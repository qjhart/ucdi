#! /bin/bash

repo=$(basename -s .git $(git config --get remote.origin.url))
branch=$(git rev-parse --abbrev-ref HEAD)
tag=$(git tag --points-at HEAD)

function build-part () {
  part=$(basename $1);
  export DOCKER_BUILDKIT=1
  echo docker build \
         --build-arg BUILDKIT_INLINE_CACHE=1 \
         -t local-dev/${repo}-${part} -t local-dev/${repo}-${part}:${branch}\
         $1
#         $(git rev-parse --show-toplevel)
}

for i in $(find $(git rev-parse --show-toplevel) -type f -name Dockerfile);do
  echo $i;
  build-part $(dirname $i)
done
