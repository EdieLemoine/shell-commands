#!/usr/bin/env bash

rmbr() {
    git fetch -p
    [[ $? -eq 0 ]] || return # return if git command failed
    branches=$(git branch -a --sort=committerdate | grep remotes | grep -v 'origin/master' | grep -v 'origin/develop' | grep "$1" | sed 's/[[:space:]]*//')
    [[ $? -eq 0 ]] || return # return if git command failed
    branch=$(echo "$branches" | fzf -m)
    [[ "$branch" ]] || return # return if user canceled command

    branchesArray=("${(@f)$(echo $branch)}")
    for branch in ${branchesArray[@]}; do
      shortBranch=$(echo ${branch} | sed 's/remotes\/origin\///')
      mergedBranches=$(git branch -r -a --sort=committerdate --merged master | grep -v master | grep -v develop | grep "$shortBranch")
      deleteBranch='n'
      if echo ${mergedBranches} | grep -q ${branch}; then
        echo -e "\e[93mDeleting $branch:\e[39m It's fully merged into master."
        deleteBranch='y'
      else
        echo "\e[41mWARNING:\e[49m Branch '$shortBranch' is not fully merged into master."
        read "deleteBranch?Delete branch '$shortBranch'? (y/n) "
      fi

      if [[ ${deleteBranch} =~ ^[Yy]$ ]]; then
         git push origin --delete ${shortBranch} || :
      fi
    done
    unset deleteTag
}
