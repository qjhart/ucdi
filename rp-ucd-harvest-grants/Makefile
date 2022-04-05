#! /usr/bin/make -f
SHELL:=/bin/bash

define pod

=pod

=head1 NAME

Grants Makefile

=head1 SYNOPSIS

This Makefile is used to create grants related TTL files.  It should be run about once per month.

  make [-n] [fiscal_year=YYYY] [fiscal_period=PP] pw=I<fis_passwd> <files>

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

secret.key:=fis_connection.json

logon:=$(shell [[ -f ${secret.key} ]] && jq -r '[.user,"/",.password,"@",.sid] | add' ${secret.key})

sqlcl:=sqlcl -S '${logon}'

.PHONY: INFO check

fiscal_period:=$(shell date --date='now() +6 months' +%m)
fiscal_year:=$(shell date --date='now() +6 months' +%Y)

tables:=organizations contributors fin_coa grants funding_agencies
csv:=$(patsubst %,%.csv,${tables})
ttl:=$(patsubst %,%.ttl,${tables})
const_ttl:=contributor_roles.ttl

INFO::
	@pod2usage -exit 0 ${MAKEFILE_LIST}

.PHONY:csv sql ttl

${secret.key}:key:=fis_ds_prod_oracle_connection_configuration
${secret.key}:
	@echo "Cannot find connection information at $@";\
	echo "You may need to run:"; \
	echo "gcloud secrets versions access latest --secret=${key} > ${secret.key}";\
	exit 1

check::
	@podchecker ${MAKEFILE_LIST}

interactive: ${secret.key}
	sqlcl '${logon}'

clean::
	rm contributors.csv  fin_coa.csv  funding_agencies.csv  grants.csv  organizations.csv
	rm -rf tdb2

dist-clean: clean
	rm grants.ttl funding_agencies.ttl

csv:${csv} ${secret.key}

${csv}:%.csv:${mkfile_path}/%.sql ${secret.key}
	${sqlcl} < $< > $@

ttl:${ttl}

${ttl}:%.ttl:%.csv %.rq
	tarql $*.rq $< > $@

tdb2:${ttl} ${const_ttl}
	mkdir tdb2;
	tdb2.tdbloader --loc=tdb2 --graph='http://experts.ucdavis.edu/fis/' ${ttl} ${const_ttl}

grants.json.gz:tdb2
	tdb2.tdbdump --loc=tdb2 --output=jsonld | gzip > $@
#	  jq '.+{"@id":"http://experts.ucdavis.edu/fis/"}' | gzip > $@
