-- Transform between YAML 1.1 streams and Lua table representations.
-- Written by Gary V. Vaughan, 2013
--
-- Copyright (c) 2013-2015 Gary V. Vaughan
--
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.
--
-- Portions of this software were inspired by an earlier LibYAML binding by
-- Andrew Danforth <acd@weirdness.net>


local yaml = require "yaml"


local TAG_PREFIX = "tag:yaml.org,2002:"

local null = setmetatable ({}, { _type = "LYAML null" })

local function isnull (x)
  return (getmetatable (x) or {})._type == "LYAML null"
end


-- Metatable for Dumper objects.
local dumper_mt = {
  __index = {
    -- Emit EVENT to the LibYAML emitter.
    emit = function (self, event)
      return self.emitter.emit (event)
    end,

    -- Look up an anchor for a repeated document element.
    get_anchor = function (self, value)
      local r = self.anchors[value]
      if r then
	self.aliased[value], self.anchors[value] = self.anchors[value], nil
      end
      return r
    end,

    -- Look up an already anchored repeated document element.
    get_alias = function (self, value)
      return self.aliased[value]
    end,

    -- Dump ALIAS into the event stream.
    dump_alias = function (self, alias)
      return self:emit {
	type   = "ALIAS",
	anchor = alias,
      }
    end,

    -- Dump MAP into the event stream.
    dump_mapping = function (self, map)
      local alias = self:get_alias (map)
      if alias then
	return self:dump_alias (alias)
      end

      self:emit {
        type   = "MAPPING_START",
        anchor = self:get_anchor (map),
        style  = "BLOCK",
      }
      for k, v in pairs (map) do
        self:dump_node (k)
        self:dump_node (v)
      end
      return self:emit {type = "MAPPING_END"}
    end,

    -- Dump SEQUENCE into the event stream.
    dump_sequence = function (self, sequence)
      local alias = self:get_alias (sequence)
      if alias then
	return self:dump_alias (alias)
      end

      self:emit {
        type = "SEQUENCE_START",
        anchor = self:get_anchor (sequence),
        style = "BLOCK",
      }
      for _, v in ipairs (sequence) do
        self:dump_node (v)
      end
      return self:emit {type = "SEQUENCE_END"}
    end,

    -- Dump a null into the event stream.
    dump_null = function (self)
      return self:emit {
        type            = "SCALAR",
        value           = "~",
        plain_implicit  = true,
        quoted_implicit = true,
        style           = "PLAIN",
      }
    end,

    -- Dump VALUE into the event stream.
    dump_scalar = function (self, value)
      local alias = self:get_alias (value)
      if alias then
	return self:dump_alias (alias)
      end

      local anchor = self:get_anchor (value)
      local itsa = type (value)
      local style = "PLAIN"
      if value == "true" or value == "false" or
         value == "yes" or value == "no" or value == "~" or
         (type (value) ~= "number" and tonumber (value) ~= nil) then
        style = "SINGLE_QUOTED"
      elseif itsa == "number" or itsa == "boolean" then
        value = tostring (value)
      elseif itsa == "string" and string.find (value, "\n") then
        style = "LITERAL"
      end
      return self:emit {
        type            = "SCALAR",
	anchor          = anchor,
        value           = value,
        plain_implicit  = true,
        quoted_implicit = true,
        style           = style,
      }
    end,

    -- Decompose NODE into a stream of events.
    dump_node = function (self, node)
      local itsa = type (node)
      if isnull (node) then
        return self:dump_null ()
      elseif itsa == "string" or itsa == "boolean" or itsa == "number" then
        return self:dump_scalar (node)
      elseif itsa == "table" then
        if #node > 0 then
          return self:dump_sequence (node)
        else
          return self:dump_mapping (node)
        end
      else -- unsupported Lua type
        error ("cannot dump object of type '" .. itsa .. "'", 2)
      end
    end,

    -- Dump DOCUMENT into the event stream.
    dump_document = function (self, document)
      self:emit {type = "DOCUMENT_START"}
      self:dump_node (document)
      return self:emit {type = "DOCUMENT_END"}
    end,
  },
}


-- Emitter object constructor.
local function Dumper (anchors)
  local t = {}
  for k, v in pairs (anchors or {}) do t[v] = k end
  local object = {
    anchors = t,
    aliased = {},
    emitter = yaml.emitter (),
  }
  return setmetatable (object, dumper_mt)
end


local function dump (documents, anchors)
  local dumper = Dumper (anchors)
  dumper:emit { type = "STREAM_START", encoding = "UTF8" }
  for _, document in ipairs (documents) do
    dumper:dump_document (document)
  end
  local ok, stream = dumper:emit { type = "STREAM_END" }
  return stream
end

local istruthy = {
  y = true, Y = true, yes = true, Yes = true, YES = true,
  ["true"] = true, True = true, TRUE = true,
  on = true, On = true, ON = true,
}


local isfalsey = {
  n = true, N = true, no = true, No = true, NO = true,
  ["false"] = true, False = true, FALSE = true,
  off = true, Off = true, OFF = true,
}


-- Metatable for Parser objects.
local parser_mt = {
  __index = {
    -- Return the type of the current event.
    type = function (self)
      return tostring (self.event.type)
    end,

    -- Raise a parse error.
    error = function (self, errmsg)
      error (string.format ("%d:%d: %s", self.mark.line,
                            self.mark.column, errmsg), 0)
    end,

    -- Save node in the anchor table for reference in future ALIASes.
    add_anchor = function (self, node)
      if self.event.anchor ~= nil then
        self.anchors[self.event.anchor] = node
      end
    end,

    -- Fetch the next event.
    parse = function (self)
      local ok, event = pcall (self.next)
      if not ok then
	-- if ok is nil, then event is a parser error from libYAML
	self:error (event:gsub (" at document: .*$", ""))
      end
      self.event = event
      self.mark  = {
	line     = self.event.start_mark.line + 1,
	column   = self.event.start_mark.column + 1,
      }
      return self:type ()
    end,

    -- Construct a Lua hash table from following events.
    load_map = function (self)
      local map = {}
      self:add_anchor (map)
      while true do
        local key = self:load_node ()
        if key == nil then break end
        local value, event = self:load_node ()
        if value == nil then
          self:error ("unexpected " .. self:type () .. "event")
        end
        map[key] = value
      end
      return map
    end,

    -- Construct a Lua array table from following events.
    load_sequence = function (self)
      local sequence = {}
      self:add_anchor (sequence)
      while true do
        local node = self:load_node ()
        if node == nil then break end
        sequence[#sequence + 1] = node
      end
      return sequence
    end,

    -- Construct a primitive type from the current event.
    load_scalar = function (self)
      local value = self.event.value
      local tag   = self.event.tag
      if tag then
        tag = tag:match ("^" .. TAG_PREFIX .. "(.*)$")
        if tag == "str" then
          -- value is already a string
	elseif tag == "null" then
	  value = null
        elseif tag == "int" or tag == "float" then
          value = tonumber (value)
        elseif tag == "bool" then
          value = istruthy[value] == true
        end
      elseif self.event.style == "PLAIN" then
        if value == "~" then
          value = null
        elseif istruthy[value] then
          value = true
        elseif isfalsey[value] then
          value = false
        else
          local number = tonumber (value)
          if number then value = number end
        end
      end
      self:add_anchor (value)
      return value
    end,

    load_alias = function (self)
      local anchor = self.event.anchor
      if self.anchors[anchor] == nil then
        self:error ("invalid reference: " .. tostring (anchor))
      end
      return self.anchors[anchor]
    end,

    load_node = function (self)
      local dispatch  = {
        SCALAR         = self.load_scalar,
        ALIAS          = self.load_alias,
        MAPPING_START  = self.load_map,
        SEQUENCE_START = self.load_sequence,
        MAPPING_END    = function () end,
        SEQUENCE_END   = function () end,
        DOCUMENT_END   = function () end,
      }

      local event = self:parse ()
      if dispatch[event] == nil then
        self:error ("invalid event: " .. self:type ())
      end
     return dispatch[event] (self)
    end,
  },
}


-- Parser object constructor.
local function Parser (s)
  local object = {
    anchors = {},
    mark    = { line = 0, column = 0 },
    next    = yaml.parser (s),
  }
  return setmetatable (object, parser_mt)
end


local function load (s, all)
  local documents = {}
  local parser    = Parser (s)

  if parser:parse () ~= "STREAM_START" then
    error ("expecting STREAM_START event, but got " .. parser:type (), 2)
  end

  while parser:parse () ~= "STREAM_END" do
    local document = parser:load_node ()
    if document == nil then
      error ("unexpected " .. parser:type () .. " event")
    end

    if parser:parse () ~= "DOCUMENT_END" then
      error ("expecting DOCUMENT_END event, but got " .. parser:type (), 2)
    end

    -- save document
    documents[#documents + 1] = document

    -- reset anchor table
    parser.anchors = {}
  end

  return all and documents or documents[1]
end


--[[ ----------------- ]]--
--[[ Public Interface. ]]--
--[[ ----------------- ]]--

local M = {
  dump      = dump,
  load      = load,
  null      = null,
  _VERSION  = yaml.version,
}

return M
