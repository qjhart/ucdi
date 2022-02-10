#! /bin/bash

repo=$(basename -s .git $(git config --get remote.origin.url))
branch=$(git rev-parse --abbrev-ref HEAD)
tag=$(git tag --points-at HEAD)
base=$(git rev-parse --show-toplevel)

if [[ -n $tag ]]; then
  t_tag="-t ucdlib/${repo}:$tag"
  echo "Submitting build to Google Cloud..."
gcloud builds submit \
  --config $base/cloudbuild.yaml \
  --substitutions=REPO_NAME=${repo},TAG_NAME=$tag,BRANCH_NAME=$branch,SHORT_SHA=$(git log -1 --pretty=%h) \
  $base
else
  echo "There is no tag on the current HEAD. Do you really want to cloud build?"
fi
