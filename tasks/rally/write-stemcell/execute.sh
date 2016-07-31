#!/bin/sh

set -eu

if [ -z "${config:-}" ] ; then echo 'ERROR: $config is not set' >&2 && exit 1 ; fi

stemcell_name="$( cat stemcell/name )"
stemcell_version="$( cat stemcell/version )"
stemcell_url="$( cat stemcell/url )"

if [ -e stemcell/sha1 ] ; then
  stemcell_sha1="$( cat stemcell/sha1 )"
else
  stemcell_sha1=""
fi

git clone file://$PWD/repository repository-output
cd repository-output

[ -e "$config" ] || echo '{}' > "$config"

jq -S \
  --arg name "$stemcell_name" \
  --arg version "$stemcell_version" \
  --arg url "$stemcell_url" \
  --arg sha1 "$stemcell_sha1" \
  '
    { "name": $name, "version": $version, "regular": { "url": $url, "sha1": $sha1 } }
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

commit="$stemcell_name/$stemcell_version"

if [ -n "${commit_prefix:-}" ] ; then
  commit="$commit_prefix: $commit"
fi

git commit -m "$commit"
