#!/usr/bin/env bash


function parse_cmd () {
	local existing_named
#	local -n ARGV=$1 # un-named params
#	local -n ARGN=$2 # named params
#  shift 2
#  set -- "${ARGV[@]}" "$@"
  while [[ "$1" =~ ^--ARG[NV] ]]; do
    if [[ "$1" =~ ^--ARGV=..* ]]; then
      local -n ARGV=${1/--ARGV=}
    elif  [[ "$1" =~ ^--ARGN=..* ]]; then
      local -n ARGN=${1/--ARGN=}
    fi
    shift
  done

	while [[ "$1" =~ "--" ]]; do
		# Escape asterisk to prevent bash asterisk expansion, and quotes to prevent string breakage
		_escaped=${1/\*/\'\"*\"\'}
		_escaped=${_escaped//\'/\\\'}
		_escaped=${_escaped//\"/\\\"}
		# If equals delimited named parameter
		nonspace="[^[:space:]]"
		if [[ "$1" =~ ^${nonspace}${nonspace}*=..* ]]; then
			# Add to named parameters array
			#echo "ARGN+=('$_escaped');"
			# key is part before first =
			local _key=$(echo "$1" | cut -d = -f 1)
			# Just add as non-named when key is empty or contains space
			if [[ "$_key" == "" || "$_key" =~ " " ]]; then
				#echo "ARGV+=('$_escaped');"
				shift
				continue
			fi
			# val is everything after key and = (protect from param==value error)
			local _val="${1/$_key=}"
			# remove dashes from key name
			_key=${_key//\-}
			# skip when key is empty
			# search for existing parameter name
			if (echo "$existing_named" | grep "\b$_key\b" >/dev/null); then
				# if name already exists then it's a multi-value named parameter
				# re-declare it as an array if needed
				if ! (declare -p _key 2> /dev/null | grep -q 'declare \-a'); then
					echo "$_key=(\"\$$_key\");"
				fi
				# append new value
				echo "$_key+=('$_val');"
			else
				# single-value named parameter
				ARGN[$_key]="$_val"
				existing_named=" $_key"
			fi
		# If standalone named parameter
		elif [[ "$1" =~ ^\-${nonspace}+ ]]; then
			# remove dashes
			local _key=${1//\-}
			# Just add as non-named when key is empty or contains space
			if [[ "$_key" == "" || "$_key" =~ " " ]]; then
				echo "ARGV+=('$_escaped');"
				shift
				continue
			fi
			# Add to options array
			ARGN[$_key]=1
		# non-named parameter
		else
			# Escape asterisk to prevent bash asterisk expansion
			_escaped=${1/\*/\'\"*\"\'}
			echo "ARGV+=('$_escaped');"
		fi
		shift
	done

  # Add Remaining Parms
  ARGV+=("$@")
}

declare -g -A opts=(
  [image]=local-dev/openjdk-python3:main
  );

parse_cmd --ARGV=cmd_line --ARGN=opts "$@"

local_workdir=$(pwd)

#user=
#user='--user=0`

echo docker run \
  --interactive --tty --rm ${user} \
  --mount type=bind,source=${local_workdir},target=/home/ucd.process/workdir \
  --workdir="/home/ucd.process/workdir" \
  "${opts[image]}" "${cmd_line[@]}"
exit $?
