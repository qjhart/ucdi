#! /usr/bin/bash

function local_user() {
  local uid=$(id -u)
  if [[ "$uid" = 0 ]]; then
    uid=${LOCAL_USER_ID:-9001}
    useradd --create-home --shell /bin/bash --uid ${uid} ucd.process
    export HOME=/home/ucd.process
    chown -R ucd.process:ucd.process /home/ucd.process
  fi
}

function exec_mk() {
  local mk=$1
  local uid=$(id -u)

  # Don't cd, because users may want to set their own workdir
  if [[ ${uid} = 0 ]]; then
    exec setpriv --reuid=ucd.process --init-groups make --file=${mk} "$@"
  else
    exec make --file=${mk} "$@"
  fi
}
