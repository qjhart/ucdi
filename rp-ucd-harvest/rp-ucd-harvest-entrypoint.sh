#! /bin/bash

function local_user() {
  local uid=$(id -u)
  if [[ "$uid" = 0 ]]; then
    uid=${LOCAL_USER_ID:-9001}
    useradd --create-home --shell /bin/bash --uid ${uid} ucd.process
    export HOME=/home/ucd.process
    chown -R ucd.process:ucd.process /home/ucd.process
  fi
}

local_user

uid=$(id -u)
if [[ ${uid} = 0 ]]; then
  # Don't cd, because users may want to set their own workdir
  exec setpriv --reuid=ucd.process --init-groups make --file=/usr/local/lib/harvest/harvest.mk "$@"
else
  exec make --file=/usr/local/lib/harvest/harvest.mk "$@"
fi
