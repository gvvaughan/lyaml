local _MODREV, _SPECREV = 'dev', '-1'

rockspec_format = '3.0'
package = 'lyaml'
version = _MODREV .. _SPECREV

description = {
   summary  = 'libYAML binding for Lua',
   detailed = 'Read and write YAML format files with Lua.',
   homepage = 'https://github.com/gvvaughan/lyaml',
   license  = 'MIT/X11',
}

source = {
   url = 'https://github.com/gvvaughan/lyaml/archive/v' .. _MODREV .. '.zip',
   dir = 'lyaml-' .. _MODREV,
}

dependencies = {
   'lua >= 5.1, < 5.6',
}

build_dependencies = {
   'luarocks-build-luke >= 0.1',
}

-- LuaRocks finds libyaml, and passes YAML_DIR, YAML_INCDIR and YAML_LIBDIR.
external_dependencies = {
   YAML = {
     library = 'yaml',
   },
}

build = {
   type = 'luke',

   defines  = {
      {PACKAGE = '"$package"'},
      {VERSION = '"$version"'},
      'NDEBUG',
      '_FORTIFY_SOURCE=2',
      platforms   = {
         aix      = {'_ALL_SOURCE'},
         bsd      = {'_BSD_SOURCE'},
         freebsd  = {'__BSD_VISIBLE'},
         macosx   = {'_DARWIN_C_SOURCE'},
      },
   },

   -- What only a probe can check, of the library that LuaRocks found.
   external_dependencies = {
      {YAML = {
         library = {checksymbol = 'yaml_document_initialize'},
      }},
   },

   incdirs  = {
      'ext/include',
      '$LUA_INCDIR',
   },

   modules  = {
      {['yaml'] = {
         'ext/yaml/yaml.c',
         'ext/yaml/emitter.c',
         'ext/yaml/parser.c',
         'ext/yaml/scanner.c',
      }},

      {['lyaml']            = 'lib/lyaml/init.lua'},
      {['lyaml.explicit']   = 'lib/lyaml/explicit.lua'},
      {['lyaml.functional'] = 'lib/lyaml/functional.lua'},
      {['lyaml.implicit']   = 'lib/lyaml/implicit.lua'},
   },

   -- A release commits its LDocs, with the manual, to install.
   copy_directories = {'doc'},
}

test_dependencies = {
   'ansicolors',
   'luacov',
   'specl >= 16',
}

test = {
   type = 'command',
   command = 'specl -vfreport --coverage spec/*_spec.yaml',
}

if _MODREV == 'dev' then
   -- Only a release builds LDocs, which `luke release` commits, but
   -- `check_dependencies` finds an ldoc here.  luarocks.org's ldoc fails
   -- on Lua 5.5; gvvaughan's works.
   build_dependencies[#build_dependencies + 1] = 'gvvaughan/ldoc'

   build.copy_directories = nil

   source = {
      url = 'git+https://github.com/gvvaughan/lyaml.git',
   }
end
