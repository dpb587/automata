#!/bin/sh

set -eu

if [ -z "${from:-}" ] ; then echo 'ERROR: $from is not set' >&2 && exit 1 ; fi
if [ -z "${config:-}" ] ; then echo 'ERROR: $config is not set' >&2 && exit 1 ; fi
if [ ! -e "repository/$from" ] ; then echo "ERROR: $from does not exist" >&2 && exit 1 ; fi

git clone file://$PWD/repository repository-output
cd repository-output

stemcell_name="$( jq -r '.name' < "$from" )"
stemcell_version="$( jq -r '.version' < "$from" )"

jq \
  'to_entries | map(select(.key != "params")) | from_entries' \
  < "$from" \
  > "$config"

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
