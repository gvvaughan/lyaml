# maintainer rules.
#
# Copyright (C) 2013 Gary V. Vaughan
# Written by Gary V. Vaughan, 2013
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
 
dont-forget-to-bootstrap = $(wildcard Makefile)

ifeq ($(dont-forget-to-bootstrap),)

Makefile: Makefile.in
	./configure
	$(MAKE)

Makefile.in:
	./bootstrap --force --verbose -Wall --skip-git

else

include Makefile

MKROCKSPECS = $(ROCKSPEC_ENV) $(LUA) $(srcdir)/build-aux/mkrockspecs.lua
ROCKSPEC_TEMPLATE = $(srcdir)/lyaml-rockspec.lua

luarocks-config.lua:
	$(AM_V_GEN){				\
	  echo 'rocks_trees = {';		\
	  echo '  "$(abs_srcdir)/luarocks"';	\
	  echo '}';				\
	} > '$@'

rockspecs: luarocks-config.lua
	rm -f *.rockspec
	$(MKROCKSPECS) $(PACKAGE) $(VERSION) $(ROCKSPEC_TEMPLATE)
	$(MKROCKSPECS) $(PACKAGE) git $(ROCKSPEC_TEMPLATE)

GIT ?= git

tag-release:
	$(GIT) diff --exit-code && \
	$(GIT) tag -f -a -m "Release tag" v$(VERSION)

define unpack-distcheck-release
	rm -rf $(PACKAGE)-$(VERSION)/ && \
	tar zxf $(PACKAGE)-$(VERSION).tar.gz && \
	cp -a -f $(PACKAGE)-$(VERSION)/* . && \
	rm -rf $(PACKAGE)-$(VERSION)/ && \
	echo "unpacked $(PACKAGE)-$(VERSION).tar.gz over current directory" && \
	echo './configure && make all rockspecs' && \
	./configure --version && ./configure && \
	$(MAKE) all rockspecs
endef

check-in-release: distcheck
	{ $(GIT) checkout -b release 2>/dev/null || $(GIT) checkout release; } && \
	{ $(GIT) pull origin release || true; } && \
	$(unpack-distcheck-release) && \
	$(GIT) add . && \
	$(GIT) commit -a -m "Release v$(VERSION)" && \
	$(GIT) tag -f -a -m "Full source release tag" release-v$(VERSION)


## To test the release process without publishing upstream, use:
##   make release WOGER=: GIT_PUBLISH=:
GIT_PUBLISH ?= $(GIT)
WOGER ?= woger

WOGER_ENV = LUA_INIT= LUA_PATH='$(abs_srcdir)/?-git-1.rockspec'
WOGER_OUT = $(WOGER_ENV) $(LUA) -l$(PACKAGE) -e

release:
	current_branch=`$(GIT) symbolic-ref HEAD`; \
	$(MAKE) tag-release && \
	$(MAKE) check-in-release && \
	$(GIT_PUBLISH) push && $(GIT_PUBLISH) push --tags && \
	$(WOGER) lua \
	  package=$(PACKAGE) \
	  package_name=$(PACKAGE_NAME) \
	  version=$(VERSION) \
	  notes=docs/RELEASE-NOTES-$(VERSION) \
	  home="`$(WOGER_OUT) 'print (description.homepage)'`" \
	  description="`$(WOGER_OUT) 'print (description.summary)'`"
	$(GIT) checkout `echo "$$current_branch" | sed 's,.*/,,g'`

endif
