-- YAML 1.1 spec file loader.
--
-- Copyright (c) 2013, Gary V. Vaughan,
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
-- Portions of this software were inspired by an earlier LibYAML from
-- Andrew Danforth <acd@weirdness.net>


local lyaml = require "lyaml"


local TAG_PREFIX = "tag:yaml.org,2002:"

local null     = lyaml.null ()


-- Metatable for Parser objects.
local parser_mt = {
  __index = {
    -- Return the type of the current event.
    type = function (self)
      return tostring (self.event.type)
    end,

    -- Save node in the anchor table for reference in future ALIASes.
    add_anchor = function (self, node)
      if self.event.anchor ~= nil then
        self.anchors[self.event.anchor] = node
      end
    end,

    -- Fetch the next event.
    parse = function (self)
      self.event = self.next ()
      -- TODO: report parser problems here
      return self:type ()
    end,

    -- Construct a Lua hash table from following events.
    load_map = function (self)
      local map = {}
      self:add_anchor (map)
      while true do
        local key = self:load_node ()
        if key == nil then break end
        local value = self:load_node ()
        if key == nil then
          error ("unexpected " .. self:type () .. "event")
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
        elseif tag == "int" or tag == "float" then
          value = tonumber (value)
        elseif tag == "bool" then
          value = (value == "true" or value == "yes")
        end
      elseif self.event.style == "PLAIN" then
        if value == "~" then
          value = null
        elseif value == "true" or value == "yes" then
          value = true
        elseif value == "false" or value == "no" then
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
        error ("invalid reference: " .. tostring (anchor))
      end
      return self.anchors[anchor]
    end,

    load_node = function (self)
      local dispatch  = {
        SCALAR         = self.load_scalar,
        ALIAS          = self.load_alias,
        MAPPING_START  = self.load_map,
        SEQUENCE_START = self.load_sequence,
        MAPPING_END    = function () return nil end,
        SEQUENCE_END   = function () return nil end,
        DOCUMENT_END   = function () return nil end,
      }

      local event = self:parse ()
      if dispatch[event] == nil then
        error ("invalid event: " .. self:type ())
      end
     return dispatch[event] (self)
    end,
  },
}


-- Parser object constructor.
local function Parser (s)
  local object = {
    anchors = {},
    next    = lyaml.parser (s),
  }
  return setmetatable (object, parser_mt)
end


local function load (s)
  local documents = {}
  local parser    = Parser (s)

  if parser:parse () ~= "STREAM_START" then
    error ("expecting STREAM_START event, but got " .. parser:type ())
  end

  while parser:parse () ~= "STREAM_END" do
    local document = parser:load_node ()
    if document == nil then
      error ("unexpected " .. parser:type () .. " event")
    end

    if parser:parse () ~= "DOCUMENT_END" then
      error ("expecting DOCUMENT_END event, but got " .. parser:type ())
    end

    -- save document
    documents[#documents + 1] = document

    -- reset anchor table
    parser.anchors = {}
  end

  return documents
end


--[[ ----------------- ]]--
--[[ Public Interface. ]]--
--[[ ----------------- ]]--

local M = {
  configure = lyaml.configure,
  dump      = lyaml.dump,
  load      = load,
  null      = null,
  _VERSION  = lyaml.version,
}

return M
