######
# top-level Makefile for uberSpark
# author: amit vasudevan (amitvasudevan@acm.org)
######

###### paths

export USPARK_SRCROOTDIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
export USPARK_BUILDTRUSSESDIR := $(USPARK_SRCROOTDIR)/build-trusses
export USPARK_SRCDIR = $(USPARK_SRCROOTDIR)/src-exptoolchain
export USPARK_DOCSDIR = $(USPARK_SRCROOTDIR)/docs

export USPARK_NAMESPACEROOTDIR := ~/uberspark
export USPARK_INSTALL_BINDIR := /usr/bin

export SUDO := sudo

###### targets

.PHONY: all
all: 
	docker run --rm -i \
		-e MAKE_TARGET=all \
		-v $(USPARK_BUILDTRUSSESDIR):/home/docker/uberspark \
		-v $(USPARK_DOCSDIR):/home/docker/uberspark/docs \
		-v $(USPARK_SRCDIR):/home/docker/uberspark/src  \
		-t local/ubersparkbuild
	rm -rf $(USPARK_BUILDTRUSSESDIR)/src
	rm -rf $(USPARK_BUILDTRUSSESDIR)/docs

.PHONY: docs_html
docs_html: 
	docker run --rm -i \
		-e MAKE_TARGET=docs_html \
		-v $(USPARK_BUILDTRUSSESDIR):/home/docker/uberspark \
		-v $(USPARK_DOCSDIR):/home/docker/uberspark/docs \
		-v $(USPARK_SRCDIR):/home/docker/uberspark/src  \
		-t local/ubersparkbuild
	rm -rf $(USPARK_BUILDTRUSSESDIR)/src
	rm -rf $(USPARK_BUILDTRUSSESDIR)/docs


.PHONY: docs_pdf
docs_pdf: 
	docker run --rm -i \
		-e MAKE_TARGET=docs_pdf \
		-v $(USPARK_BUILDTRUSSESDIR):/home/docker/uberspark \
		-v $(USPARK_DOCSDIR):/home/docker/uberspark/docs \
		-v $(USPARK_SRCDIR):/home/docker/uberspark/src  \
		-t local/ubersparkbuild
	rm -rf $(USPARK_BUILDTRUSSESDIR)/src
	rm -rf $(USPARK_BUILDTRUSSESDIR)/docs


.PHONY: bldcontainer-x86_64
bldcontainer-x86_64: 
	@echo building x86_64 build truss...
	docker build -f $(USPARK_BUILDTRUSSESDIR)/Makefile-truss-x86_64.Dockerfile -t local/ubersparkbuild $(USPARK_BUILDTRUSSESDIR)/.
	@echo successfully built x86_64 build truss!


###### installation targets

### installation helper target to create namespace
.PHONY: install_createnamespace
install_createnamespace: 
	@echo Creating namespace within: $(USPARK_NAMESPACEROOTDIR)...
	rm -rf $(USPARK_NAMESPACEROOTDIR)
	mkdir -p $(USPARK_NAMESPACEROOTDIR)
	mkdir -p $(USPARK_NAMESPACEROOTDIR)/bridges
	mkdir -p $(USPARK_NAMESPACEROOTDIR)/docs
	mkdir -p $(USPARK_NAMESPACEROOTDIR)/hwm
	mkdir -p $(USPARK_NAMESPACEROOTDIR)/include
	mkdir -p $(USPARK_NAMESPACEROOTDIR)/loaders
	mkdir -p $(USPARK_NAMESPACEROOTDIR)/platforms
	mkdir -p $(USPARK_NAMESPACEROOTDIR)/sentinels
	mkdir -p $(USPARK_NAMESPACEROOTDIR)/uobjcoll
	mkdir -p $(USPARK_NAMESPACEROOTDIR)/uobjrtl
	mkdir -p $(USPARK_NAMESPACEROOTDIR)/uobjs
	@echo Namespace created.

### installation helper target to populate namespace
.PHONY: install_populatenamespace
install_populateamespace: 
	@echo Populating namespace within: $(USPARK_NAMESPACEROOTDIR)...
	cp -rf $(USPARK_SRCDIR)/bridges/* $(USPARK_NAMESPACEROOTDIR)/bridges/.
	cp -rf $(USPARK_DOCSDIR)/_build/* $(USPARK_NAMESPACEROOTDIR)/docs/.
	cp -rf $(USPARK_SRCDIR)/hwm/* $(USPARK_NAMESPACEROOTDIR)/hwm/.
	cp -rf $(USPARK_SRCDIR)/include/* $(USPARK_NAMESPACEROOTDIR)/include/.
	cp -rf $(USPARK_SRCDIR)/loaders/* $(USPARK_NAMESPACEROOTDIR)/loaders/.
	cp -rf $(USPARK_SRCDIR)/platforms/* $(USPARK_NAMESPACEROOTDIR)/platforms/.
	cp -rf $(USPARK_SRCDIR)/sentinels/* $(USPARK_NAMESPACEROOTDIR)/sentinels/.
	cp -rf $(USPARK_SRCDIR)/uobjcoll/* $(USPARK_NAMESPACEROOTDIR)/uobjcoll/.
	cp -rf $(USPARK_SRCDIR)/uobjrtl/* $(USPARK_NAMESPACEROOTDIR)/uobjrtl/.
	cp -rf $(USPARK_SRCDIR)/uobjs/* $(USPARK_NAMESPACEROOTDIR)/uobjs/.
	@echo Namespace populated.


# install tool binary to /usr/bin and namespace to ~/uberspark/
.PHONY: install
install: install_createnamespace install_populateamespace
	@echo Installing binary to $(USPARK_INSTALL_BINDIR)...
	@echo Note: You may need to enter your sudo password. 
	$(SUDO) cp -f $(USPARK_SRCDIR)/tools/driver/uberspark $(USPARK_INSTALL_BINDIR)/uberspark
	@echo Installation success! Use uberspark --version to check.
