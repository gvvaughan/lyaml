# Non-recursive Make rules.
#
# Copyright (C) 2013 Gary V. Vaughan
# Written by Gary V. Vaughan, 2013
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


## ---------- ##
## Bootstrap. ##
## ---------- ##

ACLOCAL_AMFLAGS = -I m4


## ------------- ##
## Declarations. ##
## ------------- ##

lib_LTLIBRARIES = lyaml.la

lyaml_la_LDFLAGS  = -module -avoid-version
lyaml_la_CPPFLAGS = $(LUA_INCLUDE) $(YAML_INCLUDE)

EXTRA_DIST = lua52compat.h

## ------------- ##
## Distribution. ##
## ------------- ##

gitlog_to_changelog = $(srcdir)/build-aux/gitlog-to-changelog

dist-hook: ChangeLog
ChangeLog: FORCE
	$(AM_V_GEN)if test -d '$(srcdir)/.git'; then	\
	  $(gitlog_to_changelog) > '$@T';		\
	  rm -f '$@'; mv '$@T' '$@';			\
	fi

EXTRA_DIST +=						\
	GNUmakefile					\
	lyaml-rockspec.lua


## ------------ ##
## Maintenance. ##
## ------------ ##

FORCE:
