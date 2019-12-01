replace-tag() {
  if git tag $2 $1; then
    echo "Tag " + $2 + " added."
    git push --delete origin $1
    git tag -d $1
  fi
}
