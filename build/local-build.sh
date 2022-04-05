#! /bin/bash

repo=$(basename -s .git $(git config --get remote.origin.url))
branch=$(git rev-parse --abbrev-ref HEAD)

src=local-dev

function build-part () {
  part=$(basename $1);
  export DOCKER_BUILDKIT=1
  docker build \
       --build-arg BUILDKIT_INLINE_CACHE=1 \
       --build-arg SRC=${src} --build-arg VERSION=${branch}\
       -t ${src}/${repo}-${part} -t ${src}/${repo}-${part}:${branch}\
       $1
}

base=openjdk-python3
build-part $base
for i in $(find $(git rev-parse --show-toplevel) -type f -name Dockerfile | grep -v $base/Dockerfile);do
  echo $i;
  build-part $(dirname $i)
done
