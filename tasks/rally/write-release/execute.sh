#!/bin/sh

set -eu

if [ -z "${config:-}" ] ; then echo 'ERROR: $config is not set' >&2 && exit 1 ; fi

release_name="missing"
#release_name="$( cat release/name )"
release_repository="$( [ -e release/repository ] && cat release/repository )"
release_version="$( cat release/version )"
release_url="$( cat release/url )"
release_sha1="$( [ -e release/sha1 ] && cat release/sha1 )"

git clone file://$PWD/repository repository-output
cd repository-output

[ -e "$config" ] || echo '{}' > "$config"

jq -S \
  --arg repository "$release_repository" \
  --arg version "$release_version" \
  --arg url "$release_url" \
  --arg sha1 "$release_sha1" \
  '
    { "repository": $repository, "version": $version, "url": $url, "sha1": $sha1 }
    + ( if has("name") then { name } else {} end )
    + ( if has("params") then { params } else {} end )
  ' \
  < "$config" \
  > "$config.new"

mv "$config.new" "$config"

if [ -n "${git_committer_email:-}" ] ; then
  git config --global user.email "$git_committer_email"
fi

if [ -n "${git_committer_name:-}" ] ; then
  git config --global user.name "$git_committer_name"
fi

git add "$config"

if git diff-index --quiet HEAD ; then
  exit
fi

commit="$release_repository/$release_version"

if [ -n "${commit_prefix:-}" ] ; then
  commit="$commit_prefix: $commit"
fi

git commit -m "$commit"
