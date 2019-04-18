#!/usr/bin/env bash

rmbr() {
    branches=$(git branch -r -a --sort=committerdate | grep -v master | grep -v develop | grep "$1" | sed 's/[[:space:]]*//')
    [[ $? -eq 0 ]] || return # return if git command failed
    branch=$(echo "$branches" | fzf -m)
    [[ "$branch" ]] || return # return if user canceled command

    shortBranch=$(echo ${branch} | sed 's/remotes\/origin\///')
    mergedBranches=$(git branch -r -a --sort=committerdate --merged master | grep -v master | grep -v develop | grep "$shortBranch")
    deleteBranch='n'
    if echo ${mergedBranches} | grep -q ${branch}; then
      echo "Deleting $branch: It's fully merged into master."
      deleteBranch='y'
    else
      echo "WARNING: Branch '$shortBranch' is not fully merged into master."
      read "deleteBranch?Delete branch '$shortBranch'? (y) "
    fi

    if [[ -z ${deleteBranch} || ${deleteBranch} =~ ^[Yy]$ ]]; then
       git branch -d -q ${shortBranch} || : && git push origin --delete ${shortBranch} || :
    fi
    unset deleteTag
}
