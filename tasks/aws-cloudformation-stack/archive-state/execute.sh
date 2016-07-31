#!/bin/sh

set -eu

git clone file://$PWD/repository repository-output
cd repository-output

[ ! -e "$state" ] || rm -fr "$state"
mkdir "$state"
cp ../stack/* $state/

if [ -n "${git_committer_email:-}" ] ; then
  git config --global user.email "$git_committer_email"
fi

if [ -n "${git_committer_name:-}" ] ; then
  git config --global user.name "$git_committer_name"
fi

git add "$state"

if git diff-index --quiet HEAD ; then
  exit
fi

git commit -m "aws-cloudformation-stack: $( cut -d/ -f2 < $state/arn.txt )"
