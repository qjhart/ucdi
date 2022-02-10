#
# debian-openjdk-python3-awscli is a lightweight base image that has openjdk, bash, python3 and the AWS CLI on board (for S3 access)
#
# We switched from Alpine to Debian for this image due to these two articles:
# - https://pythonspeed.com/articles/base-image-python-docker-images/
# - https://pythonspeed.com/articles/alpine-docker-python/
#
# This image is based on Debian Buster, the official Dockerhub image that already contains OpenJDK Java.
# Then we copied all relevant parts of their python image into this to end up with a combination of Java and Python
# in one image.
#
# See https://github.com/docker-library/python/blob/master/3.8/buster/Dockerfile
#
# TODO: Make this a multi-stage dockerfile, we don't need the full C compiler and all that in the base image!
#
FROM openjdk:15-slim-buster

ENV YQ_VERSION="3.3.2"

#
#   This image runs on kubernetes in Google Cloud and on OpenShift. Ideally we have one
#   strict setup with a non-root user in its own group but since OpenShift assigns the uid
#   for you we cannot assume that our top level process runs with our assigned uid.
#   What we do know however is that the Openshift assigned user id always has group 0 (the root group)
#   so we're using the user ekggroup in group root for all non-openshift deployments.
#
#   See also https://www.openshift.com/blog/jupyter-on-openshift-part-6-running-as-an-assigned-user-id
#
ARG UID=2000
ENV HOME=/home/ucd.process
RUN useradd --system --no-user-group --home-dir /home/ucd.process --create-home --shell /bin/bash --uid ${UID} --gid 0 ucd.process && \
    chgrp -Rf root /home/ucd.process && chmod -Rf g+w /home/ucd.process


#   Ensure that the local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH
ENV LANG=C.UTF-8

#
#   This hack is widely applied to avoid python printing issues in docker containers.
#   See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
#
ENV PYTHONUNBUFFERED=1

#
#   The two lines below are there to prevent a red line error to be shown about apt-utils not being installed
#
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

#
#   Install the python and awscli dependencies in one RUN statement
#
RUN apt-get update -y -qq && \
    apt-get install -y -qq --no-install-recommends \
#       slim-buster doesn't have python 3.8+ yet
		python3.7 \
		python3-pip \
		python3-setuptools-git \
#    	uuid-dev \
#    	dirmngr \
    	gnupg \
    	less \
    	groff \
		ca-certificates \
		netbase \
		git \
    	wget \
    	curl \
		unzip \
    	jq \
    rsync \
    httpie \
# 		python3-gssapi \
# 		krb5-user \
# 		libkrb5-dev \
    	&& \
	apt-get upgrade -y && \
	apt-get dist-upgrade -y && \
#   now we install yq
#    curl -L "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" -o /usr/bin/yq && \
#    chmod +x /usr/bin/yq && \
#    yq --version && \
#   clean up before ending this RUN statement
    rm -rf /var/lib/apt/lists/* && \
	(dpkg -l | grep python) && \
	(cd /usr/bin && ln -s python3.7 python) && \
	(cd /usr/bin && ln -s pip3 pip) && \
	( \
		set -x && \
		python3 --version || true && \
		python3.7 --version || true && \
		pip --version || true \
	) && \
#   create /home/ucd.process/.cache and own it as root to avoid red warning messages during docker build
	mkdir -p /home/ucd.process/.cache && chown root /home/ucd.process/.cache && \
    python3 -m pip install --upgrade pip && \
#   install wheel just to avoid all kinds of messages during docker build
    python3 -m pip install wheel && \
    python3 -m pip install setuptools && \
    python3 -m pip install rdflib && \
#    python3 -m pip install git+https://github.com/rdflib/sparqlwrapper#egg=sparqlwrapper && \
#    python3 -m pip install git+https://github.com/ekgf/ekglib@3fe4283a27c62bb2f8478944c2c4a00fce5e5ad6#egg=ekglib && \
#   most of the packages below are already pulled in by ekglib
#   but keeping these lines here just for documentation purposes
#    python3 -m pip install boto3 && \
#    python3 -m pip install botocore && \
#    python3 -m pip install owlrl && \
#    python3 -m pip install pandas && \
    python3 -m pip install python-dateutil && \
    python3 -m pip install requests && \
#    python3 -m pip install six && \
    python3 -m pip install stringcase && \
#    python3 -m pip install humps && \
#    python3 -m pip install argparse && \
    python3 -m pip install inflection && \
#    python3 -m pip install ldap3 && \
    python3 -m pip install xlrd && \
#    python3 -m pip install pystardog && \
    python3 -m pip install unidecode && \
#   python3 -m pip install gssapi && \
#   no more pip installs after this point so we can now remove the .cache directory
    rm -rf /home/ucd.process/.cache && \
#
#   now the final clean up, making the image as small as possible
#
    apt-get --purge -y remove git && \
    apt-get --purge -y autoremove && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* && \
#
#   just to be sure, everything we added to the home directory is owned by user ucd.process
#   and group root (see openshift comments at the top of this dockerfile)
#
	cd /home/ucd.process && \
	chown -vR ucd.process:root .

#
# 	now we leave the image to run as user ucd.process from its home directory
#
USER ucd.process
WORKDIR /home/ucd.process
ENTRYPOINT [ "/bin/bash" ]
