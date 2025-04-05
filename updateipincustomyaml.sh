#!/bin/bash
set -x

# Get current date and time
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Update Public IP in custom.yaml
cp custom.yaml verycustom.yaml
public_ip=$(curl -s whoami.domain.tld | jq -r '.ip') # Use a good public IP whois that returns JSON
sed -i '.bak1' "s#EXTERNAL_IP: \"[0-9.].*\"#EXTERNAL_IP: \"${public_ip}\"#" custom.yaml

# Update IPv6 Subnets in custom.yaml
# Download the IPv6 subnets from the URL and save them to a file
# Check the http response code, and if it is 200 then proceed
# This does require that you have another automation that will keep track of your IPv6 subnets
http_code=$(curl -s -o /dev/null -w "%{http_code}" http://sub.innerdomain.home/listRouterIPv6Subnets.txt)
if [ $http_code -ne 200 ]; then
    echo "$TIMESTAMP: File mod - Failed to download IPv6 subnets from the URL. Exiting."
else
    echo "$TIMESTAMP: File mod - Successfully downloaded IPv6 subnets from the URL."
    curl -s http://sub.innerdomain.home/listRouterIPv6Subnets.txt | tee listRouterIPv6Subnets.txt
fi

# Get the number of lines in the subnets.txt file (i.e., the number of IPv6 subnets)
num_subnets=$(wc -l < listRouterIPv6Subnets.txt)

# If there are one or more IPv6 subnets, create a string with them separated by commas
if [ $num_subnets -gt 0 ]; then
    ipv6_subnet_str=$(cat listRouterIPv6Subnets.txt | tr '\n' ',')
    # Remove the trailing comma and add it to the IPv4 subnet string
    ipv6_subnet_str=${ipv6_subnet_str%,}
    sed -i '.bak2' "s#HOME_NET:.*#HOME_NET: \"192.168.0.0\/16,10.0.0.0\/8,172.16.0.0\/12,${ipv6_subnet_str}\"#" custom.yaml
else
    sed -i '.bak2' "s#HOME_NET:.*#HOME_NET: \"192.168.0.0\/16,10.0.0.0\/8,172.16.0.0\/12\"#" custom.yaml
fi