#!/bin/bash

#https://stackoverflow.com/questions/415677/how-to-replace-placeholders-in-a-text-file
function expandVarsStrict(){
  local line lineEscaped
  while IFS= read -r line || [[ -n $line ]]; do  # the `||` clause ensures that the last line is read even if it doesn't end with \n
    # Escape ALL chars. that could trigger an expansion..
    IFS= read -r -d '' lineEscaped < <(printf %s "$line" | tr '`([$' '\1\2\3\4')
    # ... then selectively reenable ${ references
    lineEscaped=${lineEscaped//$'\4'\{/\$\{}
    # Finally, escape embedded double quotes to preserve them.
    lineEscaped=${lineEscaped//\"/\\\"}
    eval "printf '%s\n' \"$lineEscaped\"" | tr '\1\2\3\4' '`([$'
  done
}

function fix_startup_files() {
  local src=${1:-${FUSEKI_HOME}}
  local dest=${2:-${FUSEKI_BASE}}
  # Since these are affected by configuration parameters, redo on every startup
  for f in $(cd $src; find . -name \*.tmpl); do
    n=$(dirname $f)/$(basename $f .tmpl)
    mkdir -p $(dirname ${dest}/$n)
    expandVarsStrict < ${src}/$f > ${dest}/$n
  done
}

function start_fuseki() {
  $FUSEKI_HOME/fuseki-server-hdt &
}
