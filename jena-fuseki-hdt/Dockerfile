ARG SRC=local-dev
ARG VERSION=main

ARG HDT_VERSION=3.0.1
ARG JENA_VERSION=4.4.0

from maven:3-openjdk-15-slim as hdt-java
ARG HDT_VERSION

USER root
WORKDIR /tmp

RUN apt-get update -y -qq &&\
    apt-get install -y -qq --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch=v$HDT_VERSION https://github.com/rdfhdt/hdt-java.git

WORKDIR /tmp/hdt-java
RUN mvn install \
  && cd hdt-java-package \
  && mvn assembly:single \
    && mv target/hdt-java-*/hdt-java-* /opt/hdt-java \
  && rm -rf /tmp/hdt-java && rm -f /opt/hdt-java/bin/*.bat

# If we were creating a standalone setup we'd add
#ENV PATH="/opt/hdt-java/bin:${PATH}"
#CMD ["/bin/echo", "Available commands: hdt2rdf.sh hdtInfo.sh hdtSearch.sh hdtsparql.sh rdf2hdt.sh"]


FROM $SRC/openjdk-python3:$VERSION
# These need to be reinitialized
ARG SRC

# Config and data
ARG HDT_VERSION
ARG JENA_VERSION

ARG FUSEKI_HOME=/usr/share/fuseki
ARG FUSEKI_JAR=jena-fuseki-server-${JENA_VERSION}.jar
ARG FUSEKI_BASE=/etc/fuseki


USER root
ENV LANG C.UTF-8
RUN set -eux && \
    apt-get update; \
    apt-get install -y --no-install-recommends \
       bash curl ca-certificates findutils coreutils pwgen procps wait-for-it && \
    rm -rf /var/lib/apt/lists/*

# Update below according to https://jena.apache.org/download/
ENV FUSEKI_SHA512 62ac07f70c65a77fb90127635fa82f719fd5f4f10339c32702ebd664227d78f7414233d69d5b73f25b033f2fdea37b8221ea498755697eea3c1344819e4a527e


LABEL org.opencontainers.image.documentation https://jena.apache.org/documentation/fuseki2/
LABEL org.opencontainers.image.title "Apache Jena Fuseki"
LABEL org.opencontainers.image.version ${JENA_VERSION}
LABEL org.opencontainers.image.licenses "(Apache-2.0 AND (GPL-2.0 WITH Classpath-exception-2.0) AND GPL-3.0)"
#LABEL org.opencontainers.image.authors "Apache Jena Fuseki by https://jena.apache.org/; this image by https://orcid.org/0000-0001-9842-9718"

# Add in Jena files
WORKDIR /tmp
ARG JENA_REPO=https://repo1.maven.org/maven2/org/apache/jena

ARG JENA_TAR_MD5=ef43daa78939d961b16b9cddc4844dd5
RUN echo "$JENA_TAR_MD5 jena.tar.gz" > jena.tar.gz.md5
# Download/check/unpack/move in one go (to reduce image size)
RUN     curl --location --silent --show-error --fail --retry-connrefused --retry 3 --output jena.tar.gz ${JENA_REPO}/apache-jena/${JENA_VERSION}/apache-jena-$JENA_VERSION.tar.gz && \
    md5sum -c jena.tar.gz.md5

RUN tar zxf jena.tar.gz && \
	mv apache-jena* /usr/local/apache-jena && \
	rm jena.tar.gz* && \
	cd /usr/local/apache-jena && rm -rf *javadoc* *src* bat

# Add to PATH
ENV PATH $PATH:/usr/local/apache-jena/bin
# Check it works
RUN riot  --version

# Install Fuseki Server (Repeat some ARGS)
WORKDIR /tmp
ARG JENA_REPO=https://repo1.maven.org/maven2/org/apache/jena

# published sha512 checksum
ARG FUSEKI_TAR_MD5=d9820b51c4037bc2e1ab9c4c751a7608
RUN echo "$FUSEKI_TAR_MD5 fuseki.tar.gz" > fuseki.tar.gz.md5
# Download/check/unpack/move in one go (to reduce image size)

RUN     curl --location --silent --show-error --fail --retry-connrefused --retry 3 --output fuseki.tar.gz ${JENA_REPO}/apache-jena-fuseki/${JENA_VERSION}/apache-jena-fuseki-$JENA_VERSION.tar.gz && \
    md5sum -c fuseki.tar.gz.md5


RUN        tar zxf fuseki.tar.gz && \
        mv apache-jena-fuseki* $FUSEKI_HOME && \
        rm fuseki.tar.gz* && \
    cd $FUSEKI_HOME && rm -rf fuseki.war && chmod 755 fuseki-server

COPY --from=hdt-java /opt/hdt-java/lib/* $FUSEKI_HOME/extra/

# Copy some working binaries as well
COPY --from=hdt-java /opt/hdt-java /opt/hdt-java/
ENV PATH="${PATH}:/opt/hdt-java/bin"

COPY fuseki $FUSEKI_HOME

# We need a config file for our sleep test
COPY config.ttl $FUSEKI_BASE/

# Test the install by testing it's ping resource
RUN  $FUSEKI_HOME/fuseki-server-hdt & \
     sleep 2 && \
     curl -sS --fail 'http://localhost:3030/$/ping'

# No need to kill Fuseki as our shell will exit after curl

# As "localhost" is often inaccessible within Docker container,
# we'll enable basic-auth with a random admin password
# (which we'll generate on start-up)
COPY jena-fuseki-hdt-functions.sh /
COPY jena-fuseki-hdt-entrypoint.sh /
RUN chmod 755 /jena-fuseki-hdt-entrypoint.sh

ENV FUSEKI_HOME=${FUSEKI_HOME}
ENV FUSEKI_BASE=${FUSEKI_BASE}
ENV FUSEKI_JAR=${FUSEKI_JAR}

# Where we start our server from
WORKDIR $FUSEKI_HOME
EXPOSE 3030
ENTRYPOINT ["/jena-fuseki-hdt-entrypoint.sh"]
CMD "${FUSEKI_HOME}/fuseki-server-hdt"
#CMD "/usr/bin/curl" "-sS" "--fail" "http://localhost:3030/$/ping"
