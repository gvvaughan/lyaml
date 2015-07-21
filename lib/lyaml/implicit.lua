-- LYAML parse implicit type tokens.
-- Written by Gary V. Vaughan, 2015
--
-- Copyright (c) 2015 Gary V. Vaughan
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


local NULL = require "lyaml.functional".NULL


local function null (value)
  if value == "~" or value == "" then
    return NULL
  end
end


local to_bool = {
  ["true"]  = true,  True  = true,  TRUE  = true,
  ["false"] = false, False = false, FALSE = false,
  yes       = true,  Yes   = true,  YES   = true,
  no        = false, No    = false, NO    = false,
  on        = true,  On    = true,  ON    = true,
  off       = false, Off   = false, OFF   = false,
}


local function bool (value)
  return to_bool[value]
end


-- binary, e.g. 0b1010_0111_0100_1010_1110
local function binary (value)
  local r
  value:gsub ("^([+-]?)0b_*([01][01_]+)$", function (sign, rest)
    r = 0
    rest:gsub ("_*(.)", function (digit)
      r = r * 2 + tonumber (digit)
    end)
    if sign == "-" then r = r * -1 end
  end)
  return r
end


-- octal, e.g. 012345
local function octal (value)
  local r
  value:gsub ("^([+-]?)0_*([0-7][0-7_]*)$", function (sign, rest)
    r = 0
    rest:gsub ("_*(.)", function (digit)
      r = r * 8 + tonumber (digit)
    end)
    if sign == "-" then r = r * -1 end
  end)
  return r
end


-- decimal, e.g. 0, or 12345
local function decimal (value)
  local r
  value:gsub ("^([+-]?)_*([0-9][0-9_]*)$", function (sign, rest)
    rest = rest:gsub ("_", "")
    if rest == "0" or #rest > 1 or rest:sub (1, 1) ~= "0"  then
      r = tonumber (rest)
      if sign == "-" then r = r * -1 end
    end
  end)
  return r
end


-- hexadecimal, eg. 0xdeadbeef
local function hexadecimal (value)
  local r
  value:gsub ("^([+-]?)(0x_*[0-9a-fA-F][0-9a-fA-F_]*)$",
    function (sign, rest)
      rest = rest:gsub ("_", "")
      r = tonumber (rest)
      if sign == "-" then r = r * -1 end
    end
  )
  return r
end


-- sexagesimal, for times and angles, e.g. 190:20:30
local function sexagesimal (value)
  local r
  value:gsub ("^([+-]?)([0-9]+:[0-5]?[0-9][:0-9]*)$", function (sign, rest)
    r = 0
    rest:gsub ("([0-9]+):?", function (digit)
      r = r * 60 + tonumber (digit)
    end)
    if sign == "-" then r = r * -1 end
  end)
  return r
end


local isnan = {
  [".nan"] = true, [".NaN"] = true, [".NAN"] = true,
}


local function nan (value)
  if isnan[value] then return 0/0 end
end


local isinf = {
  [".inf"]  = math.huge,  [".Inf"]  = math.huge,  [".INF"]  = math.huge,
  ["+.inf"] = math.huge,  ["+.Inf"] = math.huge,  ["+.INF"] = math.huge,
  ["-.inf"] = -math.huge, ["-.Inf"] = -math.huge, ["-.INF"] = -math.huge,
}


local function inf (value)
  return isinf[value]
end


local function float (value)
  local r = tonumber ((value:gsub ("_", "")))
  if r and value:find "[%.eE]" then return r end
end


-- sexagesimal float, for times and angles, e.g. 190:20:30.15
local function sexfloat (value)
  local r
  value:gsub ("^([+-]?)([0-9]+:[0-5]?[0-9][:0-9]*)(%.[0-9]+)$",
    function (sign, rest, float)
      r = 0
      rest:gsub ("([0-9]+):?", function (digit)
        r = r * 60 + tonumber (digit)
      end)
      r = r + tonumber (float)
      if sign == "-" then r = r * -1 end
    end
  )
  return r
end


return {
  binary      = binary,
  decimal     = decimal,
  float       = float,
  hexadecimal = hexadecimal,
  inf         = inf,
  nan         = nan,
  null        = null,
  octal       = octal,
  sexagesimal = sexagesimal,
  sexfloat    = sexfloat,
  bool        = bool,
}
