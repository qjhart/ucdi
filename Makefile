#! /usr/bin/make -f
SHELL:=/bin/bash

define pod

=pod

=head1 NAME

Dockerfile Tools

=head1 SYNOPSIS

This Makefile is used to manage our workflow Dockerfiles.

  make [-n] [dest=cloud] [image] [image ...]

=head2 Methods / Files

=item C<image>

Adding an image name will build the image.  The if [dest=cloud] then it will be a cloud build,
otherwise it will be a local-dev build.

=cut

endef

mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

dest:=local
org.local:=local-dev
org.cloud:=gcr.io/ucdlib-pubreg

repo:=$(shell basename -s .git $$(git config --get remote.origin.url))
branch:=$(shell git rev-parse --abbrev-ref HEAD)
tag:=$(shell git tag --points-at HEAD)
base:=$(shell git rev-parse --show-toplevel)
gcloud_user:=$(shell gcloud auth list --filter="status:ACTIVE"  --format="value(account)")
sha:=$(shell git log -1 --pretty=%h)

images:=jena-fuseki-hdt rp-ucd-harvest-grants rp-ucd-harvest-person openjdk-tarql openjdk-sqlcl

INFO::
	@pod2usage -exit 0 ${MAKEFILE_LIST}

.PHONY::${images}

local-dev: ${images}

# This is where you set any other dependancies
jena-fuseki-hdt:: openjdk-python3

define build-local
$(warning build-local $1)

.PHONY:: $1

$1::
	export DOCKER_BUILDKIT=1;\
	docker build \
	     --build-arg BUILDKIT_INLINE_CACHE=1 \
	     --build-arg SRC=${org.${dest}} --build-arg VERSION=${branch}\
	     -t ${org.${dest}}/$1:${branch} $1
endef

define build-cloud
$(warning build-remote $1)

.PHONY:: $1

$1::
	gcloud config set project digital-ucdavis-edu;\
  gcloud builds submit \
    --config ${base}/cloudbuild.yaml \
    --substitutions=_UCD_LIB_INITIATOR=${user},ORG=${org.${dest}},\
	IMAGE=${repo}-$1,REPO_NAME=${repo},TAG_NAME=${tag},\
	BRANCH_NAME=${branch},SHORT_SHA=${sha} \
  ${base}/$1
endef


$(eval $(call build-${dest},openjdk-python3))

$(foreach i,${images},$(eval $(call build-${dest},$i)))
