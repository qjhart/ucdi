#!/bin/bash
#   Licensed to the Apache Software Foundation (ASF) under one or more
#   contributor license agreements.  See the NOTICE file distributed with
#   this work for additional information regarding copyright ownership.
#   The ASF licenses this file to You under the Apache License, Version 2.0
#   (the "License"); you may not use this file except in compliance with
#   the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

set -e

if [ ! -f "$FUSEKI_BASE/shiro.ini" ] ; then
  # First time
  echo "###################################"
  echo "Initializing Apache Jena Fuseki"
  echo ""
  cp "$FUSEKI_HOME/shiro.ini" "$FUSEKI_BASE/shiro.ini"
  if [ -z "$FUSEKI_PASSWORD" ] ; then
    FUSEKI_PASSWORD=$(pwgen -s 15)
    echo "Randomly generated admin password:"
    echo ""
    echo "admin=$FUSEKI_PASSWORD"
  fi
  echo ""
  echo "###################################"
fi

# $ADMIN_PASSWORD can always override
if [ -n "$FUSEKI_PASSWORD" ] ; then
  sed -i "s/^admin=.*/admin=$FUSEKI_PASSWORD/" "$FUSEKI_BASE/shiro.ini"
fi

if [ ! -f "$FUSEKI_BASE/config.ttl" ] ; then
	echo "#######################################"
	echo "Trying to copy over hdt config.ttl"
	echo "#######################################"
  cp "$FUSEKI_HOME/config.ttl" "$FUSEKI_BASE/config.ttl"
fi

exec "$@"
