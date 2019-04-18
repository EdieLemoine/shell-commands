#!/usr/bin/env bash

rmbrs() {
    git checkout master && git pull
    branches=$(git branch -r -a --sort=committerdate --merged master | grep -v master | grep -v develop | grep "$1" | sed 's/remotes\/origin\///' | sed 's/[[:space:]]*//')

    branchesArray=("${(@f)$(echo $branches)}")
    echo ${branches}
    for branch in ${branchesArray[@]}; do
      if git branch -a --list | grep -q ${branch}; then
        read "deleteBranch?Delete $branch? (y) "
        if [[ -z ${deleteBranch} || ${deleteBranch} =~ ^[Yy]$ ]]; then
           git branch -d ${branch} || : && git push origin --delete ${branch} || :
        fi
        unset deleteTag
        else
        echo "$branch not found, skipping"
      fi
    done
}
