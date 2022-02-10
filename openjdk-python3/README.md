# Base Image - debian-openjdk-python3

This base image was inspired by:
https://github.com/EKGF/debian-openjdk-python3-awscli which I found primarily
because they have sparql style tools as well. I'm using this for the tarql,
although, we probably need node as well.

The above project references a comparison of Alpine to Debian for this image due
to these two articles:
- https://pythonspeed.com/articles/base-image-python-docker-images/
- https://pythonspeed.com/articles/alpine-docker-python/

This can also be used as a starting point for Ariflow images

Utilities in this image:

- jq (for processing JSON)
- yq (for processing YAML)
- curl & wget (for executing HTTP commands)
- git
- rsync
- uuid-dev
- dirmngr
- gnupg
- less
- groff
- ca-certificates
- netbase
- unzip

Python libraries:

- wheel
- rdflib
- sparqlwrapper
- requests
- boto3
- pystardog
- owlrt
- pandas
- stringcase
- unidecode
- humps
- xlrd
