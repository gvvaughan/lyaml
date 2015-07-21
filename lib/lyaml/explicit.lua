-- LYAML parse explicit token values.
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

local functional = require "lyaml.functional"
local implicit   = require "lyaml.implicit"

local anyof, id = functional.anyof, functional.id

local NULL       = functional.NULL


local yn = {
  y = true, Y = true, n = false, N = false,
}


local to_bool = anyof {
  implicit.bool,
  function (x) return yn[x] end,
}


local function maybefloat (fn)
  return function (...)
    local r = fn (...)
    if type (r) == "number" then
      return r + 0.0
    end
  end
end


local to_float = anyof {
  implicit.float,
  implicit.nan,
  implicit.inf,
  maybefloat (implicit.octal),
  maybefloat (implicit.decimal),
  maybefloat (implicit.hexadecimal),
  maybefloat (implicit.binary),
  implicit.sexfloat,
}


local to_int = anyof {
  implicit.octal,
  implicit.decimal,
  implicit.hexadecimal,
  implicit.binary,
  implicit.sexagesimal,
}


return {
  bool  = to_bool,
  float = to_float,
  int   = to_int,
  null  = function () return NULL end,
  str   = id,
}
