package = "lyaml"
version = "4-1"
description = {
  homepage = "http://github.com/gvvaughan/lyaml",
  license = "MIT/X11",
  summary = "libYAML binding for Lua",
  detailed = "Read and write YAML format files with Lua.",
}
source = {
  url = "http://github.com/gvvaughan/lyaml/archive/release-v4.zip",
  dir = "lyaml-release-v4",
}
dependencies = {
  "lua >= 5.1",
}
external_dependencies = {
  YAML = {
    library = "yaml",
  },
}
build = {
  build_command = "./configure LUA='$(LUA)' LUA_INCLUDE='-I$(LUA_INCDIR)' CPPFLAGS='-I$(YAML_INCDIR)' LDFLAGS='-L$(YAML_LIBDIR)' --prefix='$(PREFIX)' --libdir='$(LIBDIR)' --datadir='$(LUADIR)' && make clean all",
  type = "command",
  copy_directories = {},
  install_command = "make install luadir='$(LUADIR)'",
}
