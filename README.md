LYAML
=====

Copyright (C) 2013-2026 Gary V. Vaughan

[![License](https://img.shields.io/:license-mit-blue.svg)](https://mit-license.org)
[![workflow status](https://github.com/gvvaughan/lyaml/actions/workflows/spec.yml/badge.svg?branch=master)](https://github.com/gvvaughan/lyaml/actions)
[![codecov.io](https://codecov.io/github/gvvaughan/lyaml/coverage.svg?branch=master)](https://codecov.io/github/gvvaughan/lyaml?branch=master)

[LibYAML] binding for [Lua], with a fast C implementation
for converting between [%YAML 1.1][yaml11] and [Lua] tables,
and a low-level [YAML] event parser for implementing more
intricate [YAML] document loading.

Installation
------------

There's no need to download an [lyaml] release, or clone the git repo,
unless you want to modify the code.  If you use [LuaRocks], you can
use it to install the latest release from its repository:

    luarocks install lyaml

Or from the rockspec in a release tarball:

    luarocks make lyaml-?-1.rockspec

To install current git master from [GitHub][lyaml] (for testing):

    luarocks install https://raw.githubusercontent.com/gvvaughan/lyaml/master/lyaml-dev-1.rockspec

To install without [LuaRocks], clone the sources from the
[repository][lyaml], and then run the following commands:

```sh
cd lyaml
build-aux/luke YAML_DIR=LIBYAML-INSTALL-PREFIX
sudo build-aux/luke PREFIX=LYAML-INSTALL-PREFIX install
specl -v1freport spec/*_spec.yaml
```

The dependencies are listed in the dependencies entry of the file
[rockspec][L19].


Documentation
-------------

LYAML includes [comprehensive documentation][github.io], which is
written in [doc/lyaml.md][manual].


Bug reports and code contributions
----------------------------------

This library is maintained by its users.

Please make bug reports and suggestions as [GitHub Issues][issues].
Pull requests are especially appreciated.

But first, please check that your issue has not already been reported by
someone else, and that it is not already fixed by [master][lyaml] in
preparation for the next release (see  Installation section above for how
to temporarily install master with [LuaRocks][]).

There is no strict coding style, but please bear in mind the following
points when proposing changes:

0. Follow existing code. There are a lot of useful patterns and avoided
   traps there.

1. 3-character indentation using SPACES in Lua sources: It makes rogue
   TABs easier to see, and lines up nicely with 'if' and 'end' keywords.

2. Simple strings are easiest to type using single-quote delimiters,
   saving double-quotes for where a string contains apostrophes.

3. Save horizontal space by only using SPACEs where the parser requires
   them.

4. Use vertical space to separate out compound statements to help the
   coverage reports discover untested lines.

5. Prefer explicit string function calls over object methods, to mitigate
   issues with monkey-patching in caller environment.


[github.io]: https://gvvaughan.github.io/lyaml
[issues]:   https://github.com/gvvaughan/lyaml/issues
[libyaml]:  https://pyyaml.org/wiki/LibYAML
[lua]:      https://www.lua.org
[luarocks]: https://luarocks.org
[lyaml]:    https://github.com/gvvaughan/lyaml
[manual]:   doc/lyaml.md
[L19]:      https://github.com/gvvaughan/lyaml/blob/master/lyaml-dev-1.rockspec#L19
[yaml]:     https://yaml.org
[yaml11]:   https://yaml.org/spec/1.1/
