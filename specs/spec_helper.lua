local util = require "specl.util"

lyaml = require "lyaml"

BOM   = string.char (254, 255) -- UTF-16 Byte Order Mark

function dump (e)
  print (util.prettytostring (e))
end

function github_issue (n)
  return "see http://github.com/gvvaughan/lyaml/issues/" .. tostring (n)
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
