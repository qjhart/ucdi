ARG PROCESS_USER=ucd.process
ARG HOME=/home/ucd.process
ARG VERSION=latest
ARG SRC=local-dev

FROM ${SRC}/ucdi-openjdk-python3:${VERSION}

COPY --from=local-dev/ucdi-openjdk-sqlcl ${HOME}/sqlcl ${HOME}/sqlcl
COPY --from=local-dev/ucdi-openjdk-tarql ${HOME}/tarql ${HOME}/tarql

# Put this section, where we install ontop, above all the ENV vars and the COPY statement that might change a lot
# so that we don't have to waste time on waiting for ontop installation.
#

USER root
RUN chown -vR ${PROCESS_USER}:root ${HOME}


USER ucd.process
RUN mkdir ${HOME}/grants
WORKDIR ${HOME}/grants
COPY Makefile *.sql *.rq ./

ENV PATH=$PATH:${HOME}/sqlcl/bin:${HOME}/tarql/bin

#
# You can override this entrypoint if you use this image as your base image but
# if you leave it as is you can use this image just to run tarql from your
# command line.
#
ENTRYPOINT ["/usr/bin/make","--directory=/home/ucd.process/grants" ]
