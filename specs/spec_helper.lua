local util = require "specl.util"

lyaml = require "lyaml"

BOM   = string.char (254, 255) -- UTF-16 Byte Order Mark

-- Hide differences between 5.1 and 5.2
table.unpack = table.unpack or unpack

function dump (e)
  print (util.prettytostring (e))
end

function github_issue (n)
  return "see http://github.com/gvvaughan/lyaml/issues/" .. tostring (n)
end

-- Output a list of event tables to the given emitter.
function emitevents (emitter, list)
  for _, v in ipairs (list) do
    if type (v) == "string" then
      ok, msg = emitter.emit { type = v }
    elseif type (v) == "table" then
      ok, msg = emitter.emit (v)
    else
      error "expected table or string argument"
    end

    if not ok then
      error (msg)
    elseif ok and msg then
      return msg
    end
  end
end

-- Create a new emitter and send STREAM_START, listed events and STREAM_END.
function emit (list)
  local emitter = lyaml.emitter ()
  emitter.emit {type = "STREAM_START"}
  emitevents (emitter, list)
  local _, msg = emitter.emit {type = "STREAM_END"}
  return msg
end

-- Create a new parser for STR, and consume the first N events.
function consume (n, str)
  local e = lyaml.parser (str)
  for n = 1, n do e () end
  return e
end

-- Return a new table with only elements of T that have keys listed
-- in the following arguments.
function filter (t, ...)
  local u = {}
  for _, k in ipairs {...} do
    u[k] = t[k]
  end
  return u
end
