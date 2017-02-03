CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

# Lua version to build for
SET(LUA "5.1" CACHE STRING "lua version to build for")
SET(VERSION "6.1.1" CACHE STRING "version of this package")

INCLUDE(FindPkgConfig)

PKG_CHECK_MODULES(YAML REQUIRED yaml-0.1)
STRING(REPLACE "." "" LUA_VERS ${LUA})
PKG_CHECK_MODULES(LUA REQUIRED lua${LUA_VERS})

SET(SOURCES
  "ext/yaml/emitter.c"
  "ext/yaml/lyaml.h"
  "ext/yaml/parser.c"
  "ext/yaml/scanner.c"
  "ext/yaml/yaml.c"
  )

SET(LUALIB
  "lib/lyaml/explicit.lua"
  "lib/lyaml/functional.lua"
  "lib/lyaml/implicit.lua"
  "lib/lyaml/init.lua"
  )

INCLUDE_DIRECTORIES(${LUA_INCLUDE_DIRS}
  ${YAML_INCLUDE_DIRS}
  "/usr/local/include"
  )
LINK_DIRECTORIES(${LUA_LIBRARY_DIRS})

ADD_DEFINITIONS(${LUA_CFLAGS} ${YAML_CFLAGS} -DVERSION="${VERSION}")

ADD_LIBRARY(lyaml SHARED ${SOURCES})
SET_TARGET_PROPERTIES(lyaml PROPERTIES PREFIX "" OUTPUT_NAME yaml)
TARGET_LINK_LIBRARIES(lyaml ${LUA_LIBRARIES} ${YAML_LIBRARIES})

INSTALL(TARGETS lyaml DESTINATION lib/lua/${LUA})
INSTALL(FILES ${LUALIB} DESTINATION share/lua/${LUA}/lyaml)
