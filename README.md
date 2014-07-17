[![Stories in Ready](https://badge.waffle.io/gvvaughan/lyaml.png?label=ready&title=Ready)](https://waffle.io/gvvaughan/lyaml)
LYAML
=====

[![travis-ci status](https://secure.travis-ci.org/gvvaughan/lyaml.png)](http://travis-ci.org/gvvaughan/lyaml/builds)

[LibYAML] binding for [Lua], with a fast C implementation
for converting between [%YAML 1.1][yaml11] and [Lua] tables,
and a low-level [YAML] event parser for implementing more
intricate [YAML] document loading.

Usage
-----

### High Level API

These functions quickly convert back and forth between Lua tables
and [%YAML 1.1][yaml11] format strings.

```lua
local lyaml   = require "lyaml"
local t       = lyaml.load (YAML-STRING)
local yamlstr = lyaml.dump (LUA-TABLE)
local null    = lyaml.null ()
```

[Lua] tables treat `nil` valued keys as if they were not there,
where [YAML] explicitly supports `null` values (and keys!).  Lyaml
will retain [YAML] `null` values as `lyaml.null ()` by default,
though it is straight forward to wrap the low level APIs to use `nil`,
subject to the usual caveats of how nil values work in [Lua] tables.


### Low Level APIs

```lua
local emitter = require ("yaml").emitter ()

emitter.emit {type = "STREAM_START"}
for _, event in ipairs (event_list) do
  emitter.emit (event)
end
str = emitter.emit {type = "STREAM_END"}
```

The `yaml.emitter` function returns an emitter object that has a
single emit function, which you call with event tables, the last
`STREAM_END` event returns a string formatted as a [YAML 1.1][yaml11]
document.

```lua
local iter = require ("yaml").scanner (YAML-STRING)

for token_table in iter () do
  -- process token table
end
```

Each time the iterator returned by `scanner` is called, it returns
a table describing the next token of YAML-STRING.  See LibYAML's
[yaml.h] for details of the contents and semantics of the various
tokens produced by `yaml_parser_scan`, the underlying call made by
the iterator.

[LibYAML] implements a fast parser in C using `yaml_parser_scan`, which
is also bound to lyaml, and easier to use than the token API above:

```lua
local iter = require ("yaml").parser (YAML-STRING)

for event_table in iter () do
  -- process event table
end
```

Each time the iterator returned by `parser` is called, it returns
a table describing the next event from the "Parse" process of the
"Parse, Compose, Construct" processing model described in the
[YAML 1.1][yaml11] specification using [LibYAML].

Implementing the remaining "Compose" and "Construct" processes in
[Lua] is left as an exercise for the reader -- though, unlike the
high-level API, `lyaml.parser` exposes all details of the input
stream events, such as line and column numbers.


Installation
------------

There's no need to download an [lyaml] release, or clone the git repo,
unless you want to modify the code.  If you use [LuaRocks], you can
use it to install the latest release from its repository:

    luarocks install lyaml

Or from the rockspec in a release tarball:

    luarocks make lyaml-?-1.rockspec

To install current git master from [GitHub][lyaml] (for testing):

    luarocks install http://raw.github.com/gvvaughan/lyaml/release/lyaml-git-1.rockspec

To install without [LuaRocks], clone the sources from the
[repository][lyaml], and then run the following commands:

```sh
cd lyaml
./bootstrap
./configure --prefix=INSTALLATION-ROOT-DIRECTORY
make all check install
```

The dependencies are listed in the dependencies entry of the file
[rockspec.conf][L10].  You will also need [Autoconf], [Automake]
and [Libtool].

See [INSTALL] for instructions for `configure`.

[autoconf]: http://gnu.org/s/autoconf
[automake]: http://gnu.org/s/automake
[install]:  http://raw.github.com/gvvaughan/lyaml/release/INSTALL
[libtool]:  http://gnu.org/s/libtool
[libyaml]:  http://pyyaml.org/wiki/LibYAML
[lua]:      http://www.lua.org
[luarocks]: http://www.luarocks.org
[lyaml]:    http://github.com/gvvaughan/lyaml
[L10]:      http://github.com/gvvaughan/lyaml/blob/master/rockspec.conf#L10
[yaml.h]:   http://pyyaml.org/browser/libyaml/branches/stable/include/yaml.h
[yaml]:     http://yaml.org
[yaml11]:   http://yaml.org/spec/1.1/
