ARG VERSION
ARG SRC

FROM $SRC/openjdk-sqlcl:$VERSION as sqlcl
FROM $SRC/openjdk-tarql:$VERSION as tarql


FROM $SRC/jena-fuseki-hdt:$VERSION

COPY --from=sqlcl /usr/local/lib/sqlcl /usr/local/lib/sqlcl
COPY --from=tarql /usr/local/lib/tarql /usr/local/lib/tarql


# Put this section, where we install ontop, above all the ENV vars and the COPY statement that might change a lot
# so that we don't have to waste time on waiting for ontop installation.
#
USER root

# Set up some HDT files
RUN mkdir -p /var/lib/fuseki/hdt/
COPY vocabularies/experts.ucdavis.edu%2FFoR/FoR.hdt* /var/lib/fuseki/hdt/
COPY vocabularies/experts.ucdavis.edu%2Fucop/positions.hdt* /var/lib/fuseki/hdt/

# Setup our FUSEKI_BASE, this is actually copied for regular users
COPY fuseki ${FUSEKI_BASE}

# Setup a place to hold the Makefile data
RUN mkdir /usr/local/lib/grants
COPY grants  /usr/local/lib/grants
COPY /rp-ucd-harvest-grants-entrypoint.sh /

ENV PATH=$PATH:/usr/local/lib/sqlcl/bin:/usr/local/lib/tarql/bin

VOLUME /home/ucd.process
WORKDIR /home/ucd.process

# You can override this entrypoint if you use this image as your base image but
# if you leave it as is you can use this image just to run tarql from your
# command line.
#
ENTRYPOINT ["/rp-ucd-harvest-grants-entrypoint.sh" ]
#ENTRYPOINT ["/usr/bin/make","--file=/usr/local/lib/grants/Makefile" ]
