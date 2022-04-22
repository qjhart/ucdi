ARG VERSION
ARG SRC
FROM $SRC/openjdk-python3:$VERSION

ENV TARQL_VERSION="1.2"

#
# Put this section, where we install ontop, above all the ENV vars and the COPY statement that might change a lot
# so that we don't have to waste time on waiting for ontop installation.
#
USER root
RUN set -x ; mkdir -p /tmp/builder && \
    cd /tmp/builder && \
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
    mv tarql /usr/local/lib && cd /usr/local/lib/tarql && rm -rf builder

ENV PATH=/usr/local/lib/tarql/bin:$PATH


ENV TARQL_JAVA_ARGS="-Xmx2g"
ENV JAVA_OPTS=${TARQL_JAVA_ARGS}

#
# You can override this entrypoint if you use this image as your base image but
# if you leave it as is you can use this image just to run tarql from your
# command line.
#
ENTRYPOINT [ "/bin/bash", "/usr/local/lib/tarql/bin/tarql" ]
