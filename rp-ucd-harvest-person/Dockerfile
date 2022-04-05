ARG PROCESS_USER=ucd.process
ARG HOME=/home/ucd.process
ARG VERSION=latest
ARG SRC=local-dev

FROM ${SRC}/ucdi-openjdk-python3:${VERSION}

ARG JENA_VERSION=4.4.0
ARG FUSEKI_HOME=/usr/share/fuseki
ARG FUSEKI_JAR=jena-fuseki-server-${JENA_VERSION}.jar
ARG FUSEKI_HOME=/etc/fuseki

COPY --from=local-dev/jena-fuseki:4.4.0 /fuseki ${FUSEKI_HOME}
COPY --from=local-dev/jena4:latest /jena /usr/local/jena/
ENV PATH=$PATH:/usr/local/jena/bin


# Put this section, where we install ontop, above all the ENV vars and the COPY
# statement that might change a lot so that we don't have to waste time on
# waiting for ontop installation.
#

USER root

RUN set -eux && \
    apt-get update && \
    apt-get install -y \
    build-essential \
    httpie \
    jq \
    xmlstarlet \
    wait-for-it && \
    rm -rf /var/lib/apt/lists/*

# Add node
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs

# Add our elements
COPY cdl-elements /usr/local/bin
COPY ucdid /usr/local/bin

# Add our aeq tool
#COPY aeq /aeq/
#RUN make --directory=/aeq prefix=/usr/local install && rm -rf /aeq
COPY ./fuseki $FUSEKI_HOME/

# Our entrypoint calls the generic VIVO one
COPY rp-ucd-harvest-person-entrypoint.sh /

RUN chown -vR ${PROCESS_USER}:root ${HOME}

USER ucd.process

RUN cd && npm install xml2json
env PATH $PATH:${HOME}/node_modules/.bin

RUN mkdir ${HOME}/add-person
WORKDIR ${HOME}/add-person
COPY add_person.ttl .

# You can override this entrypoint if you use this image as your base image
#ENTRYPOINT ["/usr/bin/make","--directory=/home/ucd.process/grants" ]
ENTRYPOINT ["/rp-ucd-harvest-person-entrypoint.sh"]
CMD ["/bin/echo", "rp-ucd-harvest-person"]
#CMD ["/jena-fuseki/fuseki-server", "--jetty-config=/jena-fuseki/jetty-config.xml"]
