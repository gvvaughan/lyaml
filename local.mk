# Non-recursive Make rules.
#
# Copyright (C) 2013-2015 Gary V. Vaughan
# Written by Gary V. Vaughan, 2013
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


## ------------ ##
## Environment. ##
## ------------ ##

lyaml_cpath	= $(abs_builddir)/ext/yaml/$(objdir)/?$(shrext)
lyaml_path	= $(abs_srcdir)/lib/?.lua;$(abs_srcdir)/lib/?/init.lua

LUA_ENV =						\
	LUA_CPATH="$(lyaml_cpath);$(LUA_CPATH)"		\
	LUA_PATH="$(lyaml_path);$(LUA_PATH)"		\
	$(NOTHING_ELSE)


## ---------- ##
## Bootstrap. ##
## ---------- ##

old_NEWS_hash   = d41d8cd98f00b204e9800998ecf8427e

update_copyright_env = \
	UPDATE_COPYRIGHT_HOLDER='(Gary V. Vaughan|Andrew Danforth)' \
	UPDATE_COPYRIGHT_USE_INTERVALS=1 \
	UPDATE_COPYRIGHT_FORCE=1


## ------------- ##
## Declarations. ##
## ------------- ##

modulesdir		= $(docdir)/modules

dist_doc_DATA		=
dist_modules_DATA	=

include specs/specs.mk


## ------ ##
## Build. ##
## ------ ##

luaexec_LTLIBRARIES += ext/yaml/yaml.la

ext_yaml_yaml_la_SOURCES =				\
	ext/yaml/yaml.c					\
	ext/yaml/emitter.c				\
	ext/yaml/parser.c				\
	ext/yaml/scanner.c				\
	$(NOTHING_ELSE)

ext_yaml_yaml_la_LDFLAGS  = -module -avoid-version
ext_yaml_yaml_la_CPPFLAGS = $(LUA_INCLUDE) $(YAML_INCLUDE)

EXTRA_DIST +=						\
	ext/yaml/lyaml.h				\
	$(NOTHING_ELSE)

dist_lua_DATA	+=					\
	lib/lyaml.lua					\
	$(NOTHING_ELSE)

lualyamldir = $(luadir)/lyaml

dist_lualyaml_DATA =					\
	lib/lyaml/explicit.lua				\
	lib/lyaml/functional.lua			\
	lib/lyaml/implicit.lua				\
	$(NOTHING_ELSE)

# Point mkrockspecs at the in-tree lyaml module.
MKROCKSPECS_ENV = $(LUA_ENV)

# Make sure yaml is built before calling mkrockspecs.
$(package_rockspec) $(scm_rockspec): $(lib_LTLIBRARIES)


## ------------- ##
## Distribution. ##
## ------------- ##

EXTRA_DIST +=				\
	build-aux/config.ld.in		\
	$(NOTHING_ELSE)


## -------------- ##
## Documentation. ##
## -------------- ##

dist_doc_DATA +=				\
	doc/index.html				\
	doc/ldoc.css				\
	$(NOTHING_ELSE)

dist_modules_DATA +=				\
	doc/modules/lyaml.html			\
	doc/modules/lyaml.explicit.html		\
	doc/modules/lyaml.functional.html	\
	doc/modules/lyaml.implicit.html		\
	$(NOTHING_ELSE)


## Parallel make gets confused when one command ($(LDOC)) produces
## multiple targets (all the html files above), so use the presence
## of the doc directory as a sentinel file.
$(dist_doc_DATA) $(dist_docmodules_DATA): $(srcdir)/doc

$(srcdir)/doc: $(dist_lua_DATA) $(dist_lualyaml_DATA)
	test -d $@ || mkdir $@
if HAVE_LDOC
	$(LDOC) -c build-aux/config.ld -d $(abs_srcdir)/doc .
else
	$(MKDIR_P) doc
	touch doc/index.html doc/ldoc.css
endif
