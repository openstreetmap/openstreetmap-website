#!/bin/sh

if [ -d /etc/firewall ]
then
  for ip in $(ls /etc/firewall)
  do
    echo "\$HTTP[\"remoteip\"] == \"$ip\" { url.access-deny = (\"\") }"
  done
fi
