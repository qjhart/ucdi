#! /usr/bin/make -f
SHELL:=/bin/bash

define pod

=pod

=head1 NAME

Grants Makefile

=head1 SYNOPSIS

This Makefile is used to create grants related TTL files.  It should be run about once per month.

  make [-n] <files>

  funding_agencies.ttl =
  grants.ttl

=head2 Methods / Files

=item C<interactive>

Starts an interactive SQL connection to FIS.

=item C<funding_agencies.ttl>

All funding agencies and pass-thru agencies referenced in these grants.

=item C<grants.ttl>

These are the files are used to fill our experts system with potential grants.  These are used when
adding new users to the system.

=item C<organizations.ttl>

Financial Organizations.

=cut

endef

mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# According to my notes, w/ the appropriate ldap configuration, this should be
# accessable via sqlplus agexpert_app/${pw}@fis_ds_prod.ucdavis.edu but the
# setup below doesn't need those other files.


FIS_LOGIN:=$(shell jq -r '[.user,"/",.password,"@",.sid] | add' <<<'${FIS_JSON}')

sqlcl:=sqlcl -S '${FIS_LOGIN}'

.PHONY: INFO check

fiscal_period:=$(shell date --date='now() +6 months' +%m)
fiscal_year:=$(shell date --date='now() +6 months' +%Y)

tables:=organizations contributors fin_coa grants funding_agencies
csv:=$(patsubst %,fis/%.csv,${tables})
grants.ttl:=$(patsubst %,fis/%.ttl,${tables})
const_ttl:=${mkfile_path}/ttl/contributor_roles.ttl

grants.tdb2:=databases/grants
grants.hdt:=databases/hdt/grants.hdt

FUSEKI_BASE:=$(shell pwd)

define tdb2hdt
.PHONY:$1.hdt
$1.hdt:${$1.hdt}

${$1.hdt}:${$1.tdb2}
	@[[ -d $(dir ${$1.hdt}) ]] || mkdir -p $(dir ${$1.hdt}); \
	rm -f ${$1.hdt}*;\
	tdb2.tdbdump --loc=${$1.tdb2} | rdf2hdt.sh -rdftype nquad -index -  ${$1.hdt}

endef


INFO::
#	@pod2usage -exit 0 ${MAKEFILE_LIST}
	echo ${FIS_JSON}
	echo ${FIS_LOGIN}



.PHONY:csv sql grants.ttl

.PHONY:FIS_LOGIN

FIS_LOGIN:key:=fis_ds_prod_oracle_connection_configuration
FIS_LOGIN:
	@if [[ "${FIS_LOGIN}" = '' ]] ; then\
		echo "No connection information.  Set your connection variable:"; \
		echo 'FIS_JSON=$$(gcloud secrets versions access latest --secret=${key})';\
		exit 1;\
	fi

check::
	@podchecker ${MAKEFILE_LIST}

interactive: FIS_LOGIN
	sqlcl '${FIS_LOGIN}'

clean::
	rm contributors.csv  fin_coa.csv  funding_agencies.csv  grants.csv  organizations.csv
	rm -rf grants.tdb2

dist-clean: clean
	rm grants.ttl funding_agencies.ttl

csv:${csv}

${csv}:fis/%.csv:${mkfile_path}/sql/%.sql
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@)
	${sqlcl} < $< > $@

grants.ttl:${grants.ttl}

${grants.ttl}:fis/%.ttl:fis/%.csv ${mkfile_path}/rq/%.rq
	tarql ${mkfile_path}/rq/$*.rq $< > $@

grants.tdb2:=databases/grants
grants.hdt:=databases/hdt/grants.hdt

${grants.tdb2}:graph:=http://experts.ucdavis.edu/fis/
${grants.tdb2}:${grants.ttl} ${const_ttl}
	mkdir -p ${grants.tdb2};
	tdb2.tdbloader --loc=${grants.tdb2} --graph=${graph} ${grants.ttl} ${const_ttl}

grants.json.gz:${grants.tdb2}
	tdb2.tdbdump --loc=${grants.tdb2} --output=jsonld | gzip > $@
#	  jq '.+{"@id":"http://experts.ucdavis.edu/fis/"}' | gzip > $@

$(eval $(call tdb2hdt,grants))

.PHONY:bash server

bash:
	bash

server:
	export FUSEKI_BASE=${FUSEKI_BASE};\
	. /jena-fuseki-hdt-functions.sh; \
  cp -r /etc/fuseki/* ${FUSEKI_BASE}; \
	fix_startup_files /etc/fuseki ${FUSEKI_BASE};\
	${FUSEKI_HOME}/fuseki-server-hdt

###########
# IAM Section
###########
iam.tdb2:=databases/iam
iam.hdt:=databases/hdt/iam.hdt

.PHONY:UCDID_AUTH

UCDID_AUTH:key:=ucdid_auth
UCDID_AUTH:
	@if [[ -z "${UCDID_AUTH}" ]] ; then\
		echo 'Set UCDID_AUTH=$$(gcloud secrets versions access latest --secret=${key})';\
		exit 1;\
	fi

iam/staff.ttl:
	@[[ -d iam ]] || mkdir iam;
	ucdid --auth=${UCDID_AUTH} fetch --format=ttl --search=isStaff=true profiles > $@

iam/faculty.ttl:
	@[[ -d iam ]] || mkdir iam;\
	ucdid --auth=${UCDID_AUTH} fetch --format=ttl --search=isFaculty=true profiles > $@

iam/faculty_title.ttl iam/staff_title.ttl:%_title.ttl:%.ttl ${mkfile_path}/rq/iam_experts_title.rq
	arq --query=${mkfile_path}/rq/iam_experts_title.rq --data=$*.ttl > $*_title.ttl

iam/faculty_roles.ttl iam/staff_roles.ttl:%_roles.ttl:%.ttl ${mkfile_path}/rq/iam_experts_roles.rq
	arq --query=${mkfile_path}/rq/iam_experts_roles.rq --data=$*.ttl > $*_roles.ttl

${iam.tdb2}:graph:=http://experts.ucdavis.edu/private/iam/
${iam.tdb2}:files:=iam/faculty_title.ttl iam/faculty_roles.ttl iam/staff_title.ttl iam/staff_roles.ttl
${iam.tdb2}:iam/faculty_title.ttl iam/faculty_roles.ttl iam/staff_title.ttl iam/staff_roles.ttl
	rm -rf ${iam.tdb2}; mkdir ${iam.tdb2}
	tdb2.tdbloader --graph="${graph}" --loc=${iam.tdb2} ${files}

iam.json.gz:${iam.tdb2}
	tdb2.tdbdump --loc=${iam.tdb2} --output=jsonld | gzip > $@

$(eval $(call tdb2hdt,iam))
