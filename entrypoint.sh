#!/usr/bin/env bash

set -x

UPSTREAM_REPO=$1
UPSTREAM_BRANCH=$2
DOWNSTREAM_BRANCH=$3
GITHUB_TOKEN=$4
MERGE_ARGS=$5
PUSH_ARGS=$6

if [[ -z "$UPSTREAM_REPO" ]]; then
  echo "Missing \$UPSTREAM_REPO"
  exit 1
fi

if [[ -z "$DOWNSTREAM_BRANCH" ]]; then
  echo "Missing \$DOWNSTREAM_BRANCH"
  echo "Default to ${UPSTREAM_BRANCH}"
  DOWNSTREAM_BREANCH=UPSTREAM_BRANCH
fi

if ! echo "$UPSTREAM_REPO" | grep '\.git'; then
  UPSTREAM_REPO="https://github.com/${UPSTREAM_REPO_PATH}.git"
fi

echo "UPSTREAM_REPO=$UPSTREAM_REPO"

git clone "https://github.com/${GITHUB_REPOSITORY}.git" work
cd work || { echo "Missing work dir" && exit 2 ; }

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --local user.password ${GITHUB_TOKEN}

git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

git remote add upstream "$UPSTREAM_REPO"
git fetch upstream
git remote -v

git checkout ${DOWNSTREAM_BRANCH}

echo -n "sync-upstream-repo https://github.com/dabreadman/sync-upstream-repo keeping CI alive. UNIX Time: " >> sync-upstream-repo
date +"%s" >> sync-upstream-repo
git add sync-upstream-repo
git commit sync-upstream-repo -m "Syncing upstream"
git push origin

MERGE_RESULT=$(git merge upstream/${UPSTREAM_BRANCH} ${MERGE_ARGS})


if [[ $MERGE_RESULT == "" ]] 
then
  exit 1
elif [[ $MERGE_RESULT != *"Already up to date."* ]]
then
  git commit -m "Merged upstream"  
  git push origin ${DOWNSTREAM_BRANCH} ${PUSH_ARGS} || exit $?
fi

cd ..
rm -rf work
