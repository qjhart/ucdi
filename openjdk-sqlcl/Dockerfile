ARG VERSION
ARG SRC
FROM $SRC/ucdi-openjdk-python3:$VERSION

ENV SQLCL_VERSION=21.4.1.17.1458

#
# Put this section, where we install ontop, above all the ENV vars and the COPY statement that might change a lot
# so that we don't have to waste time on waiting for ontop installation.
#
USER root
RUN set -x ; mkdir -p /home/ucd.process/builder && \
    cd /home/ucd.process/builder && \
    curl -L https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-${SQLCL_VERSION}.zip -o sqlcl.zip && \
    unzip ./sqlcl.zip && \
    mkdir ../sqlcl && mv sqlcl/lib ../sqlcl && \
    mkdir ../sqlcl/bin && mv sqlcl/bin/sql ../sqlcl/bin/sqlcl && \
    chmod ug+x ../sqlcl/bin/sqlcl && \
    ls -al ../sqlcl/bin/sqlcl && \
    cd .. && rm -rf builder && \
    chown -vR ucd.process:root .

ENV PATH=/home/ucd.process/sqlcl/bin:$PATH

USER ucd.process
WORKDIR /home/ucd.process

ENV SQLCL_JAVA_ARGS="-Xmx2g"
ENV JAVA_OPTS=${SQLCL_JAVA_ARGS}

#
# You can override this entrypoint if you use this image as your base image but
# if you leave it as is you can use this image just to run tarql from your
# command line.
#
ENTRYPOINT [ "/bin/bash" ]
