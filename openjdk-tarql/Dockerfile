ARG VERSION
ARG SRC
FROM $SRC/ucdi-openjdk-python3:$VERSION

ENV TARQL_VERSION="1.2"

#
# Put this section, where we install ontop, above all the ENV vars and the COPY statement that might change a lot
# so that we don't have to waste time on waiting for ontop installation.
#
USER root
RUN set -x ; mkdir -p /home/ucd.process/builder && \
    cd /home/ucd.process/builder && \
    curl -L https://github.com/tarql/tarql/releases/download/v${TARQL_VERSION}/tarql-${TARQL_VERSION}.tar.gz -o ./tarql.tar.gz && \
    tar xzf ./tarql.tar.gz && \
    rm tarql.tar.gz && \
    mv tarql-${TARQL_VERSION} tarql && \
    rm tarql/bin/tarql.bat tarql/README.md && \
    find . && \
    echo JAVA_HOME=${JAVA_HOME} && \
    chmod ug+x ./tarql/bin/tarql && \
    cat ./tarql/bin/tarql && \
    ls -al ./tarql/bin && \
    mv tarql .. && cd .. && rm -rf builder && \
    chown -vR ucd.process:root .

ENV PATH=/home/ucd.process/tarql/bin:$PATH

#
USER ucd.process
WORKDIR /home/ucd.process

ENV TARQL_JAVA_ARGS="-Xmx2g"
ENV JAVA_OPTS=${TARQL_JAVA_ARGS}

#
# You can override this entrypoint if you use this image as your base image but
# if you leave it as is you can use this image just to run tarql from your
# command line.
#
ENTRYPOINT [ "/bin/bash", "/home/ucd.process/tarql/bin/tarql" ]
