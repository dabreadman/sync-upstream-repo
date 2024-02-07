#!/usr/bin/env bash

set -e

readonly GIT_REPO_REGEX="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+)(.git)*$"
UPSTREAM_REPO_URL=$1
UPSTREAM_BRANCH=$2
DOWNSTREAM_REPO_URL=$3
DOWNSTREAM_BRANCH=$4
GITHUB_TOKEN=$5
FETCH_ARGS=$6
REBASE_ARGS=$7
PUSH_ARGS=$8

if [[ -z "${UPSTREAM_REPO_URL}" ]]; then
  echo "Missing UPSTREAM_REPO"
  exit 1
fi

if [[ -z "${UPSTREAM_BRANCH}" ]]; then
  echo "Missing UPSTREAM_BRANCH"
  exit 1
fi

if [[ -z "${DOWNSTREAM_REPO_URL}" ]]; then
  echo "Missing DOWNSTREAM_REPO_URL"
  exit 1
fi

if [[ -z "${GITHUB_TOKEN}" ]]; then
  echo "Missing GITHUB_TOKEN"
  exit 1
fi

echo "Running with these values:"
echo "    UPSTREAM_REPO_URL='${UPSTREAM_REPO_URL}'"
echo "    UPSTREAM_BRANCH='${UPSTREAM_BRANCH}'"
echo "    DOWNSTREAM_REPO_URL='${DOWNSTREAM_REPO_URL}'"
echo "    DOWNSTREAM_BRANCH='${DOWNSTREAM_BRANCH}'"
echo "    GITHUB_TOKEN=*******"
echo "    FETCH_ARGS='${FETCH_ARGS}'"
echo "    REBASE_ARGS='${REBASE_ARGS}'"
echo "    PUSH_ARGS='${PUSH_ARGS}'"


if [[ -z "${DOWNSTREAM_BRANCH}" ]]; then
  echo "Missing DOWNSTREAM_BRANCH, defaulting it to ${UPSTREAM_BRANCH}"
  DOWNSTREAM_BRANCH=${UPSTREAM_BRANCH}
fi


if [[ ${DOWNSTREAM_REPO_URL} =~ ${GIT_REPO_REGEX} ]]; then    
   DOWNSTREAM_REPO="${BASH_REMATCH[4]}/${BASH_REMATCH[5]}"
else 
  echo "${DOWNSTREAM_REPO_URL} does not seem to be a valid GitHub repo url"
  exit 1
fi

mkdir -pv work
if [[ $? -gt 0 ]]; then
  echo "Failed to create work directory"
  exit 1
fi 

git clone --branch ${DOWNSTREAM_BRANCH} "https://github.com/${DOWNSTREAM_REPO}" work
cd work || { echo "Missing work dir" && exit 2 ; }

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --local user.password ${GITHUB_TOKEN}

git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${DOWNSTREAM_REPO}"
git remote add upstream "$UPSTREAM_REPO_URL"
git fetch --tags ${FETCH_ARGS} upstream
git remote -v

echo "Rebasing upstream/${UPSTREAM_BRANCH} unto ${DOWNSTREAM_BRANCH}"
git rebase ${MERGE_ARGS} upstream/${UPSTREAM_BRANCH}

echo "Pushing changes to origin ${DOWNSTREAM_BRANCH}"
git push ${PUSH_ARGS} origin ${DOWNSTREAM_BRANCH}

echo "Pushing tags to origin..."
git push -f --tags origin


cd ..
rm -rf work
