ARG VERSION
ARG SRC

FROM ${SRC}/rp-ucd-harvest:${VERSION}

# JENA_VERSION, FUSEKI_HOME,FUSEKI_BASE, FUSEKI_JAR  all specified in jena-fuseki-hdt

USER root

RUN set -eux && \
    apt-get update && \
    apt-get install -y \
    build-essential \
    httpie \
    jq \
    xmlstarlet && \
    rm -rf /var/lib/apt/lists/*

# Add node
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs

RUN cd /tmp && npm install -g xml2json --unsafe-perm

# Add our elements
COPY cdl-elements /usr/local/bin
COPY ucdid /usr/local/bin

# Add our aeq tool
#COPY aeq /aeq/
#RUN make --directory=/aeq prefix=/usr/local install && rm -rf /aeq

# Add our makefile
COPY harvest /usr/local/lib/harvest/

# Our entrypoint calls the generic VIVO one
COPY rp-ucd-harvest-person-entrypoint.sh /

ENV PATH=${PATH}

# You can override this entrypoint if you use this image as your base image
#ENTRYPOINT ["/usr/bin/make","--directory=/home/ucd.process/grants" ]
ENTRYPOINT ["/rp-ucd-harvest-person-entrypoint.sh"]
CMD ["/bin/echo", "rp-ucd-harvest-person"]
