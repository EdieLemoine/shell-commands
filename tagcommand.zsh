#!/usr/bin/env bash

tag() {
  unset prevTag
  unset currentTag
  unset tag

  merges=$(git log --merges --first-parent master --oneline --decorate --stat --pretty="format:%h%<(18)%d %<(20)%cn %<(30)%s")
  [[ $? -eq 0 ]] || return # return if git command failed
  line=$(echo "$merges" | fzf)
  [[ "$line" ]] || return # return if user canceled command

  commitHash=$(echo ${line} | sed -E 's/^([a-z0-9]+).*$/\1/')

  # Get the previous line
  prevLine=$(echo ${merges} | grep -A 1 "^$commitHash" | tail -1)

  # find current tag if it exists
  if echo ${line} | grep -q "(tag:"; then
    currentTag=$(echo ${line} | sed -E 's/^.*([0-9]+\.[0-9]+\.[0-9]+).*$/\1/')
  fi

  if echo ${prevLine} | grep -q "(tag:"; then
    prevTag=$(echo ${prevLine} | sed -E 's/^.*([0-9]+\.[0-9]+\.[0-9]+).*$/\1/')
  fi

  # Find branch name regardless if commit is merge or pull request
  if echo ${line} | grep -q 'Merge branch '; then
    branch=$(echo ${line} | sed -E "s/^.* Merge branch '(.+)'$/\1/")
  elif echo ${line} | grep -q 'Automatic merge '; then
    branch=$(echo ${line} | sed -E "s/^.* Automatic merge from (.+) ->.*$/\1/")
    to=$(echo ${line} | sed -E "s/^.* Automatic merge from .+ -> (.+)$/\1/")
  else
    branch=$(echo ${line} | sed -E "s/^.* Merge pull request.+from (.+) to.*$/\1/")
    to=$(echo ${line} | sed -E "s/^.* Merge pull request.+from .+ to (.+).*$/\1/")
  fi

  suggestedVersion="?"
  bumpedPatch=$(semver -i patch ${prevTag})
  bumpedMinor=$(semver -i minor ${prevTag})

  if [[ ${branch} == hotfix/* || ${branch} == bugfix/* ]];  then
    suggestedVersion=$bumpedPatch
  elif [[ ${branch} == release || ${branch} == release/* || ${branch} == feature/* || ! -z ${prevTag} ]]; then
    suggestedVersion=$bumpedMinor
  fi

  if [[ ! -z ${prevTag} ]]; then
    echo -e "Previous tag: \e[93m$prevTag\e[39m"
  fi

  if [[ ! -z ${currentTag} ]]; then
    echo -e "Current tag: \e[93m$currentTag\e[39m"
  fi

  to=${to} || 'master'
  echo -e "Merge: \e[93m$branch\e[39m -> \e[92m$to\e[39m"

  until [[ ! -z ${tag} && ${returnVal} -eq 0 ]]; do
    if [[ ! ${returnVal} -eq 0 ]]; then
      echo "$tag is not a valid version, try again."
    fi

    read -r "tag?Enter new tag: ($suggestedVersion) / M ($bumpedMinor) / P ($bumpedPatch) "
    if [[ -z ${tag} ]]; then
      tag=$suggestedVersion
    elif [[ ${tag} =~ ^[Mm]$ ]]; then
      tag=$bumpedMinor
    elif [[ ${tag} =~ ^[Pp]$ ]]; then
      tag=$bumpedPatch
    fi

    # use semver to validate tag
    semver ${tag}
    returnVal=$?
  done

  tags=$(git show-ref --tags -d | grep ^"$commitHash" | sed -e 's,.* refs/tags/,,' -e 's/\^{}//')

  if [[ ! -z ${tags} ]]; then
    tagString=$(echo ${tags} | tr '\n' ', ' | sed 's/,$//')
    echo "\e[93mWarning:\e[39m Commit has tags: \e[93m$tagString\e[39m"

    tagArray=("${(@f)$(echo $tags)}")
    for commitTag in "${tagArray[@]}"; do
      read -r "deleteTag?Delete $commitTag? (y) "
        if [[ -z ${deleteTag} || ${deleteTag} =~ ^[Yy]$ ]]; then
           git tag -d ${commitTag} && git push origin --delete ${commitTag}
        fi
        unset deleteTag
    done
  fi

  if git tag | grep ${tag}; then
     read "deleteTag?Tag $tag already exits. Delete it first? (y) "
    if [[ -z ${deleteTag} || ${deleteTag} =~ ^[Yy]$ ]]; then
      git tag -d ${tag} && git push origin --delete ${tag}
    fi
  fi

  git tag ${tag} "${commitHash}" && git push --tags

  unset prevTag
  unset currentTag
  unset tag
}
