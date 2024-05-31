$ cat test.sh
#!/bin/bash

# Resolve the Hostname to IP
hostname="$1"
ip_address=$(getent hosts "$hostname" | awk '{ print $1 }' | head -n1)

if [ -z "$ip_address" ]; then
    echo "Hostname '$hostname' could not be resolved to an IP address."
else
    echo "The IP address of $hostname is $ip_address"
fi