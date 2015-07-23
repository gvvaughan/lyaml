dnl configure.ac
dnl Written by Gary V. Vaughan, 2013
dnl
dnl Copyright (C) 2013-2015 Gary V. Vaughan
dnl
dnl Permission is hereby granted, free of charge, to any person obtaining
dnl a copy of this software and associated documentation files (the
dnl "Software"), to deal
dnl in the Software without restriction, including without limitation the
dnl rights to use, copy, modify, merge, publish, distribute, sublicense,
dnl and/or sell copies of the Software, and to permit persons to whom the
dnl Software is furnished to do so, subject to the following conditions:
dnl
dnl The above copyright notice and this permission notice shall be
dnl included in all copies or substantial portions of the Software.
dnl
dnl THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
dnl EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
dnl MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
dnl NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
dnl BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
dnl ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
dnl CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
dnl SOFTWARE.

AC_PREREQ([2.68])

dnl Initialise autoconf and automake
AC_INIT([lyaml], [5.1.4], [http://github.com/gvvaughan/lyaml/issues])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AS_BOX([Configuring AC_PACKAGE_TARNAME AC_PACKAGE_VERSION])
echo

AM_INIT_AUTOMAKE([-Wall subdir-objects])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

dnl required by automake 1.12.x, not available in 1.10.x
m4_ifdef([AM_PROG_AR], [AM_PROG_AR])

LT_PREREQ([2.4.2])
LT_INIT([disable-static])

module=yes eval shrext=$shrext_cmds

AC_SUBST([objdir])
AC_SUBST([shrext])
AC_SUBST(LIBTOOL_DEPS)

dnl Check for programs
AC_PROG_CC
AC_PATH_PROG([LDOC], [ldoc], [:])
AC_PATH_PROG([SPECL], [specl], [:])
AX_PROG_LUA(5.1, 5.4)
AX_LUA_HEADERS

dnl Check for header files
AC_HEADER_STDC
AC_CHECK_HEADERS([yaml.h])

dnl Search libs
AC_SEARCH_LIBS([yaml_document_initialize], [yaml], [], [
    AC_MSG_ERROR([Required library 'yaml' could not be found])])

dnl Generate output files
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile build-aux/config.ld])
AC_OUTPUT
