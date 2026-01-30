SYSTEM ?= blq
BRANCH ?= samis
VERSION ?= `cut -f1 -d- VERSION`
KERNEL ?= `cut -f2 -d- VERSION`
NCPUS ?= 

usage:
	@echo "*** Usage: make [SYSTEM=...] [BRANCH=...] [VERSION=...] [KERNEL=...] [NCPUS=...] build"
	@echo "*** The defaults: SYSTEM=$(SYSTEM) BRANCH=$(BRANCH) VERSION=$(VERSION) KERNEL=$(KERNEL) NCPUS=$(NCPUS)"

build:
	@build/build.$(SYSTEM).job $(BRANCH) $(VERSION) $(KERNEL) $(NCPUS)

prot:
	@find . -type d | fgrep -v .git | xargs -r chmod -v a+rx
	@find . -type f | fgrep -v .git | xargs -r chmod -v a+r
	@chmod -v a+rx bin/* build/*

.PHONY: build prot
