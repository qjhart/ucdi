#! /usr/bin/make -f
SHELL:=/bin/bash

define pod

=pod

=head1 NAME

Dockerfile Tools

=head1 SYNOPSIS

This Makefile is used to manage our workflow Dockerfiles.

  make [-n] [fiscal_y

=head2 Methods / Files

=item C<interactive>

Starts an interactive SQL connection to FIS.

=item C<funding_agencies.ttl>

All funding agencies and pass-thru agencies referenced in these grants.

=item C<grants.ttl>

These are the files are used to fill our experts system with potential grants.  These are used when
adding new users to the system.

=cut

endef

mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

src:=local-dev
repo:=$(shell basename -s .git $$(git config --get remote.origin.url))
branch:=$(shell git rev-parse --abbrev-ref HEAD)


images:=jena-fuseki-hdt rp-ucd-harvest-grants rp-ucd-harvest-person openjdk-tarql

INFO::
	@pod2usage -exit 0 ${MAKEFILE_LIST}

.PHONY::${images}

local-dev: ${images}

define build-local
$(warning build-local $1)

.PHONY:: $1

$1::
	export DOCKER_BUILDKIT=1;\
	docker build \
	     --build-arg BUILDKIT_INLINE_CACHE=1 \
	     --build-arg SRC=${src} --build-arg VERSION=${branch}\
	     -t ${src}/${repo}-$1:${branch} $1
endef

$(eval $(call build-local, openjdk-python3))

$(foreach i,${images},$(eval $(call build-local,$i)))
