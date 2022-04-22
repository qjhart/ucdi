#! /bin/bash

# Add in jena-fuseki entrypoint functions
#. /jena-fuseki-hdt-functions.sh

# Just always load this data.
function json_load_test() {
  local jsonld="$FUSEKI_BASE/databases/harvest.json"
  tdb2.tdbloader --syntax=jsonld --tdb=$FUSEKI_BASE/configuration/harvest.ttl < $jsonld
}

function local_user() {
  local user_id=${LOCAL_USER_ID:-9001}
#  useradd --system --create-home --shell /bin/bash --uid ${user_id} ucd.process
  useradd --create-home --shell /bin/bash --uid ${user_id} ucd.process
  export HOME=/home/ucd.process
}

json_load_test
local_user

#fix_startup_files
#start_fuseki
#wait-for-it -t 5 localhost:3030 -- echo "fuseki is up"

# Switch to CMD
cd $HOME
exec /jena-fuseki-hdt-entrypoint setpriv --reuid=ucd.process --init-groups "$@"
