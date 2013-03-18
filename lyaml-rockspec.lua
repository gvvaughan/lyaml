-- lyaml rockspec data

-- Variables to be interpolated:
--
-- package
-- version

local default = {
  package = package_name,
  version = version.."-1",
  source = {
    url = "http://github.com/gvvaughan/"..package_name.."/archive/release-v"..version..".zip",
    dir = package_name.."-release-v"..version,
  },
  description = {
    summary = "libYAML binding for Lua",
    detailed = [[
      Read and write YAML format files with Lua.
     ]],
    homepage = "http://github.com/gvvaughan/"..package_name.."/",
    license = "MIT",
  },
  dependencies = {
    "lua >= 5.1",
  },
  external_dependencies = {
    YAML = { library = "yaml" }
  },
  build = {
    type = "command",
    build_command = "LUA=$(LUA) LUA_INCLUDE=-I$(LUA_INCDIR) " ..
      "./configure CPPFLAGS=-I$(YAML_INCDIR) LDFLAGS='-L$(YAML_LIBDIR)' " ..
      "--prefix=$(PREFIX) --libdir=$(LIBDIR) --datadir=$(LUADIR) " ..
      "&& make clean && make",
    install_command = "make install",
    copy_directories = {},
  },
}

if version == "git" then
  default.build.build_command = "./bootstrap && " .. default.build.build_command
end

return {default=default, [""]={}}
