#!/bin/sh

set -eu

mkdir /tmp/create-env
jq '. * { "cloud_provider": { "ssh_tunnel": { "private_key": "/tmp/create-env/id_rsa" } } }' < "$manifest" > /tmp/create-env/manifest.yml

if [ -e "repository/$state" ] ; then
	cp "repository/$state" /tmp/create-env/manifest-state.json
fi

echo "$ssh_key" > /tmp/create-env/id_rsa
chmod 0600 /tmp/create-env/id_rsa

git clone file://$PWD/repository repository-output
cd repository-output

set +e
/usr/bin/bosh create-env /tmp/create-env/manifest.yml
exit=$?
set -e

cp /tmp/create-env/manifest-state.json "$state"

if [ -n "${git_committer_email:-}" ] ; then
  git config --global user.email "$git_committer_email"
fi

if [ -n "${git_committer_name:-}" ] ; then
  git config --global user.name "$git_committer_name"
fi

git add "$state"

if git diff-index --quiet HEAD ; then
  exit $exit
fi

git commit -m "create-env: $state"

exit $exit
