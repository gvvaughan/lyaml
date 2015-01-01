# Lyaml Specl make rules.
#
# Copyright (c) 2013-2015 Gary V. Vaughan
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


## ------ ##
## Specs. ##
## ------ ##

specl_SPECS =						\
	$(srcdir)/specs/ext_yaml_emitter_spec.yaml	\
	$(srcdir)/specs/ext_yaml_parser_spec.yaml	\
	$(srcdir)/specs/ext_yaml_scanner_spec.yaml	\
	$(srcdir)/specs/lib_lyaml_spec.yaml		\
	$(NOTHING_ELSE)

EXTRA_DIST +=						\
	$(srcdir)/specs/spec_helper.lua			\
	$(NOTHING_ELSE)

include build-aux/specl.mk
