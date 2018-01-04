local _MODREV, _SPECREV = 'git', '-1'

package = 'lyaml'
version = _MODREV .. _SPECREV

description = {
   summary  = 'libYAML binding for Lua',
   detailed = 'Read and write YAML format files with Lua.',
   homepage = 'http://github.com/gvvaughan/lyaml',
   license  = 'MIT/X11',
}

source = (function(gitp)
   if gitp then
      return {
         url = 'git://github.com/gvvaughan/lyaml.git',
      }
   else
      return {
         url = 'http://github.com/gvvaughan/lyaml/archive/v' .. _MODREV .. '.zip',
         dir = 'lyaml-' .. _MODREV,
      }
   end
end)(_MODREV == 'git')

dependencies = {
   'lua >= 5.1, < 5.4',
   'std.normalize > 2.0',
}

if _MODREV == 'git' then
   dependencies[#dependencies + 1] = 'ldoc'
end

external_dependencies = {
   YAML = {
     library = 'yaml',
   },
}

build = {
   type = 'command',
   build_command = '$(LUA) build-aux/luke'
      .. ' package="' .. package .. '"'
      .. ' version="' .. version .. '"'
      .. ' PREFIX="$(PREFIX)"'
      .. ' CFLAGS="$(CFLAGS)"'
      .. ' LIBFLAG="$(LIBFLAG)"'
      .. ' LIB_EXTENSION="$(LIB_EXTENSION)"'
      .. ' OBJ_EXTENSION="$(OBJ_EXTENSION)"'
      .. ' LUA="$(LUA)"'
      .. ' LUA_DIR="$(LUADIR)"'
      .. ' LUA_INCDIR="$(LUA_INCDIR)"'
      .. ' YAML_DIR="$(YAML_DIR)"'
      .. ' YAML_INCDIR="$(YAML_INCDIR)"'
      .. ' YAML_LIBDIR="$(YAML_LIBDIR)"'
      ,
   install_command = '$(LUA) build-aux/luke install --quiet'
      .. ' INST_LIBDIR="$(LIBDIR)"'
      .. ' INST_LUADIR="$(LUADIR)"'
      ,
}
