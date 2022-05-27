#! /bin/bash

. /rp-ucd-harvest-functions.sh

function exec_mk2() {
  local opts=`getopt -o m: --long mk: -n 'exec mk' -- "$@"`
  if [ $? != 0 ] ; then echo "Bad Command Options." >&2 ; exit 1 ; fi

  eval set -- "$opts"

  local mk;
  while true; do
	  case $1 in
      -m | --mk ) mk=$2; shift 2 ;;
	    -- ) shift; break;;
	    *) shift; break;
    esac
  done

  local uid=$(id -u)

  # Don't cd, because users may want to set their own workdir
  if [[ ${uid} = 0 ]]; then
    exec setpriv --reuid=ucd.process --init-groups make --file=${mk} "$@"
  else
    exec make -i --file=${mk} "$@"
  fi
}

local_user
exec_mk2 --mk=/usr/local/lib/harvest/work.mk -- "$@"
