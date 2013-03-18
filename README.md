lyaml
=====

LibYAML binding for [Lua](http://www.lua.org)

1. Usage
--------

    local lyaml   = require "lyaml"
    local ok      = lyaml.configure (OPTION-NAME, BOOLEAN)
    local t       = lyaml.load (FILENAME)
    local yamlstr = lyaml.dump (LUA-TABLE)
    local null    = lyaml.null ()

The configure function allows enabling and disabling of the following
options:    

 * `dump_auto_array`
 * `dump_check_metatables`
 * `dump_error_on_unsupported`
 * `load_set_metatables`
 * `load_numeric_scalars`
 * `load_nulls_as_nil`


2. Installation
---------------

    ./configure --prefix=INSTALLATION-ROOT-DIRECTORY
    make all install

or:

    make
    make rockspecs
    luarocks make lyaml-git-1.rockspec
