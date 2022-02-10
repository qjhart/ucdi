#!/usr/bin/env bash

local_workdir=$(pwd)

user=
#user='--user=0`

docker run \
  --interactive --tty --rm ${user} \
  --mount type=bind,source=${local_workdir},target=/home/ucd.process/workdir \
  --workdir="/home/ucd.process/workdir" \
  "$(< image.id)" "$@"
exit $?
