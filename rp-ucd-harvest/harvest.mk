#! /usr/bin/make -f
SHELL:=/bin/bash

mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: INFO check

FUSEKI_BASE:=$(shell pwd)

INFO::
	echo "harvest.mk"

.PHONY:bash server server_bg

define grant_stub
<http://experts.ucdavis.edu/fis/> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://experts.ucdavis.edu/schema#Graph>.
endef

.PHONY: grants.hdt
grants.hdt:${FUSEKI_BASE}/databases/hdt/grants.hdt

${FUSEKI_BASE}/databases/hdt/grants.hdt:
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@)
	rdf2hdt.sh -index $@ >/dev/null <<<'${grant_stub}'

define iam_stub
<http://experts.ucdavis.edu/private/iam/> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://experts.ucdavis.edu/schema#Graph>.
endef

.PHONY: iam.hdt
iam.hdt:${FUSEKI_BASE}/databases/hdt/iam.hdt

${FUSEKI_BASE}/databases/hdt/iam.hdt:
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@)
	rdf2hdt.sh -index $@ >/dev/null <<<'${iam_stub}'

bash:
	bash

server: grants.hdt iam.hdt
	export FUSEKI_BASE=${FUSEKI_BASE};\
	. /jena-fuseki-hdt-functions.sh; \
  cp -r /etc/fuseki/* ${FUSEKI_BASE}; \
	fix_startup_files /etc/fuseki ${FUSEKI_BASE};\
	${FUSEKI_HOME}/fuseki-server-hdt

server_bg: grants.hdt iam.hdt
	export FUSEKI_BASE=${FUSEKI_BASE};\
	. /jena-fuseki-hdt-functions.sh; \
  cp -r /etc/fuseki/* ${FUSEKI_BASE}; \
	fix_startup_files /etc/fuseki ${FUSEKI_BASE};\
	nohup ${FUSEKI_HOME}/fuseki-server-hdt
