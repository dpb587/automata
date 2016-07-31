#!/bin/sh

set -eu

target_extra=""

if [ -n "$ca_cert" ] ; then
  echo "$ca_cert" > /tmp/ca.crt
  target_extra="--ca-cert /tmp/ca.crt"
fi

echo "${target} director" >> /etc/hosts

/usr/bin/bosh $target_extra env "https://director:25555"
/usr/bin/bosh $target_extra log-in --user "$username" --password "$password"
/usr/bin/bosh $target_extra -n cleanup
