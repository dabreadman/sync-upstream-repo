# Sync Upstream Repo Fork

This is a Github Action used to merge changes from remote.  

This is forked from [dabreadman/sync-upstream-repo](https://github.com/dabreadman/sync-upstream-repo) which in turn was forked from [mheene](https://github.com/mheene/sync-upstream-repo). 

The changes in this fork are:

1. Use of `rebase` to merge upstream changes into the target fork repo and branch.
2. Use of the RHEL Ubi images instead of alpine
3. Removal of the spawn logs argument as it did not fit in with the rebase option.
4. Added explicit logging messages
5. Pushing and pulling of tags from upstream repo to downstream repo

## Use case

- Preserve a repo while keeping up-to-date (rather than to clone it).
- Have a branch in sync with upstream, and pull changes into dev branch.

## Usage

```YAML
name: Sync Upstream

env:
  # Required, URL to upstream repository (fork base)
  UPSTREAM_REPO_URL:  https://github.com/openvinotoolkit/model_server.git
  # Required, the name of the upstream branch to pull changes from
  UPSTREAM_BRANCH: main
  # Required, URL to the fork where to upstream changes are to be synched
  DOWNSTREAM_REPO_URL: https://github.com/z103cb/openvino_model_server.git
  # Optional, downstream repository branch name. If not provided it will default to
  # the value of UPSTREAM_BRANCH
  DOWNSTREAM_BRANCH: main
  # GITHUB TOKEN allowing for operations on the DOWNSTREAM repo. The value should be a
  # secret
  TOKEN: "xxxx"
  # Optional, fetch arguments
  FETCH_ARGS: ""
  # Optional, rebase arguments
  REBASE_ARGS: ""
  # Optional, push arguments
  PUSH_ARGS: ""
 
# This runs every day on 1801 UTC
on:
  schedule:
    - cron: '1 18 * * *'
  # Allows manual workflow run (must in default branch to work)
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: GitHub Sync to Upstream Repository
        uses: z103db/sync-upstream-repo@v2.0.0
        with: 
          upstream_repo_url: ${{ env.UPSTREAM_REPO_URL }}
          upstream_branch: ${{ env.UPSTREAM_BRANCH }}
          downstream_repo_url: ${{ env.DOwNSTREAM_REPO_URL }}
          downstream_branch: ${{ env.DOWNSTREAM_BRANCH }}
          token: ${{ secret.GHA_TOKEN }}
          fetch_args: ${{ env.FETCH_ARGS }}
          push_args: ${{ env.PUSH_ARGS }}
          rebase_args: ${{ env.REBASE_ARGS }}
```

This action syncs the downstream repo with the upstream repo every day at the time specified in the schedule. The synch process rebases the content of the specified branch in the downstream repo with the content of the upstream repo and branch. You can pass additional arguments to the rebase commands using the REBASE_ARGS  
Do note GitHub Action scheduled workflow usually face delay as it is pushed onto a queue, the delay is usually within 1 hour long.

## Development

In [`action.yml`](action.yml), we define `inputs`.  
We then pass these arguments into [`Dockerfile`](Dockerfile), which then passed onto [`entrypoint.sh`](entrypoint.sh).

`entrypoint.sh` does the heavy-lifting,

- Set up variables.
- Set up git config.
- Clone downstream repository.
- Fetch upstream repository.
- Attempt rebase if behind, and push to downstream.
