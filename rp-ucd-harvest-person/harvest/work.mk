#! /usr/bin/make

SHELL:=/bin/bash

define pod

=pod

=head1 NAME

work.mk

=head1 SYNOPSIS

This Makefile is used to create vivo grants

  make [-n] <files>

  funding_agencies.ttl =
  grants.ttl

=head2 Methods / Files

=item C<info> C[default]

Shows process info

=item C<work>

Create vivo work(s)

=cut

endef

mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: INFO check

# Include harvest.mk file,reequired for running server
include ${mkfile_path}/harvest.mk

work.ru:=/usr/local/lib/harvest/ru/work_from_cdl.ru
md5sum.rq:=/usr/local/lib/harvest/rq/md5sum.rq

# Intermediate files
cdl.json:=$(patsubst %,cdl/%.000.json,${WORKS})
tmp.in:=$(patsubst %,tmp/%.in,${WORKS})
tmp.md5:=$(patsubst %,tmp/%.md5,${WORKS})
old.work.json:=$(patsubst %,old/work/%.json,${WORKS})
old.work.in:=$(patsubst %,tmp/old/work/%.in,${WORKS})
old.work.md5:=$(patsubst %,tmp/old/work/%.md5,${WORKS})
work.json:=$(patsubst %,new/work/%.json,${WORKS})
work.ins:=$(patsubst %,new/work/%.ins.n3,${WORKS})
work.del:=$(patsubst %,new/work/%.del.n3,${WORKS})

INFO::
	@echo 'WORKS: ${WORKS}';\
	echo 'cdl.json: ${cdl.json}';\
	echo 'in: ${in}';

.PHONY:fuseki cdl.json import convert checksum diff export

fuseki:fuseki.log

fuseki.log: grants.hdt iam.hdt
	export FUSEKI_BASE=${FUSEKI_BASE};\
	. /jena-fuseki-hdt-functions.sh; \
  cp -r /etc/fuseki/* ${FUSEKI_BASE}; \
	fix_startup_files /etc/fuseki ${FUSEKI_BASE};\
	${FUSEKI_HOME}/fuseki-server-hdt | tee $@ &
	wait-for-it -t 5 localhost:3030 -- echo "fuseki is up"

#fuseki:fuseki.log
#	wait-for-it -t 5 localhost:3030 -- echo "fuseki is up"

#	while : ; do echo "Press CTRL+C to exit"; sleep 10;done
stay-up:
	read -p "Any key to delete " yn


cdl.json: ${cdl.json}
${cdl.json}:cdl/%.000.json:
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@);\
	echo cdl-elements --auth=ucd:4eKuwAhZLG publications --prefix=cdl/$* $*

tmp.in: ${tmp.in}
${tmp.in}:tmp/%.in:cdl/%.000.json fuseki
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@);\
	curl -X POST --data-binary @$< -H 'Content-Type:application/ld+json' http://localhost:3030/experts/data > $@

auth:=admin:testing123

tmp.md5:md5.rq:=/usr/local/lib/harvest/rq/md5.rq
tmp.md5:${tmp.md5}
${tmp.md5}:tmp/%.md5:tmp/%.in fuseki
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@);\
	echo "prefix this_pub: <http://oapolicy.universityofcalifornia.edu/$*> prefix this_graph: <http://experts.ucdavis.edu/work/$*#>" | cat - ${work.ru} | curl -s --location --request POST --user "${auth}" -H Content-Type:application/sparql-update --data-binary "@-" http://localhost:3030/experts/update;\
	echo "prefix this_graph: <http://experts.ucdavis.edu/work/$*#>" | cat - ${md5.rq} | curl -s --location --request POST --user "${auth}" -H Content-Type:application/sparql-query -H Accept:text/csv --data-binary "@-" http://localhost:3030/experts/query > $@

#	curl -H Accept:application/ld+json http://localhost:3030/experts/get?graph=http://experts.ucdavis.edu/work/$*#new
work.json:rq:=/usr/local/lib/harvest/rq/work.rq
work.json:${work.json}
${work.json}:new/work/%.json:tmp/%.md5
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@);\
	echo "prefix this_graph: <http://experts.ucdavis.edu/work/$*#>" | cat - ${rq} | curl -s --location --request POST --user "${auth}" -H Content-Type:application/sparql-query -H Accept:application/ld+json --data-binary "@-" http://localhost:3030/experts/query > $@

work.ins:rq:=/usr/local/lib/harvest/rq/minus.rq
work.ins:${work.ins}
${work.ins}:new/work/%.ins.n3:tmp/%.md5 tmp/old/work/%.in
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@);\
	echo "prefix graph: <http://experts.ucdavis.edu/work/$*#new> prefix minus: <http://experts.ucdavis.edu/work/$*/old/>" | cat - ${rq} | curl -s --location --request POST --user "${auth}" -H Content-Type:application/sparql-query -H Accept:text/n3 --data-binary "@-" http://localhost:3030/experts/query > $@

work.del:rq:=/usr/local/lib/harvest/rq/minus.rq
work.del:${work.del}
${work.del}:new/work/%.del.n3:tmp/%.md5 tmp/old/work/%.in
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@);\
	echo "prefix minus: <http://experts.ucdavis.edu/work/$*#new> prefix graph: <http://experts.ucdavis.edu/work/$*/old/>" | cat - ${rq} | curl -s --location --request POST --user "${auth}" -H Content-Type:application/sparql-query -H Accept:text/n3 --data-binary "@-" http://localhost:3030/experts/query > $@

old.work.in: ${old.work.in}
${old.work.in}:tmp/old/work/%.in:old/work/%.json
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@);\
	curl -X POST --data-binary @$< -H 'Content-Type:application/ld+json' 'http://localhost:3030/experts/data?graph=http://experts.ucdavis.edu/work/$*/old/' > $@
