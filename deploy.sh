#!/bin/bash
#
# Author: Joe Gardiner
# This script will deploy a Load Balancer on port 80, 2 web servers and
# a cloud databse following this ASCII diagram
# BE AWARE: This will incur charges for you or the customer.

#
# Hard-coded variables
IDENTITY_ENDPOINT="https://identity.api.rackspacecloud.com/v2.0"
LB_ENDPOINT="https://lon.loadbalancers.api.rackspacecloud.com/v1.0"
DATE=$( date +"%F_%H-%M-%S" )

#
# Verify the existence of pre-req's
PREREQS="curl echo jq sed python"
PREREQFLAG=0
for PREREQ in $PREREQS; do
  which $PREREQ &>/dev/null
  if [ $? -ne 0 ]; then
    echo "Error: Gotta have '$PREREQ' binary to run."
    PREREQFLAG=1
  fi
done
if [ $PREREQFLAG -ne 0 ]; then
  exit 1
fi

#
# FUNCTIONS

#
# Authenticate function

authenticate ()
{
    TOKEN=`curl -s -XPOST $IDENTITY_ENDPOINT/tokens \
      -d'{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"'$USERNAME'","apiKey":"'$API_KEY'"}}}' \
      -H"Content-type:application/json" | \
      python -c 'import sys,json;data=json.loads(sys.stdin.read());print data["access"]["token"]["id"]'`

    ERROR_MSG='Username or api key is invalid.'
    # verify if the response does not indicate incorrect authentication details.
    ERROR_CHECK=$(echo $AUTH | grep "$ERROR_MSG")
    if [ -n "$ERROR_CHECK" ]
    then
        echo "ERROR: Incorrect authentication details, wrong username or password."
        exit 1
    fi
}

create_lb ()
{
  LB=`curl -s -X POST -H "Content-Type: application/json" -H "X-Auth-Token: $TOKEN" "https://$DC.loadbalancers.api.rackspacecloud.com/v1.0/$ACCOUNT_NUM/loadbalancers/" \
  -d '{"loadBalancer": {"name": "lb1","port": "80","protocol": "HTTP","virtualIps": [{"type": "PUBLIC"}]}}' | \
  python -c 'import sys,json;data=json.loads(sys.stdin.read());print data["loadBalancer"]["virtualIps"]["address"]'`
}

#
# END FUNCTIONS

#
# Welcome the user to the script
echo "\n\nThis script will deploy the following:
- 1 x Cloud Load Balancer (port 80)
- 2 x Cloud Servers (in LB pool)
- 1 x Cloud Database"
sleep 3
echo "\nFirst we need to capture some input"
sleep 2

#
# Capture auth info from the user
echo "\nType the account username, followed by [ENTER]:"
read USERNAME

echo "\nType the account API key, followed by [ENTER]:"
read API_KEY

echo "\nType the account number, followed by [ENTER]:"
read ACCOUNT_NUM

#
# Test connection to the auth API endpoint
authenticate

echo $TOKEN

if [ ! -z "$TOKEN" ]
  then
    echo "\nToken received, ready to proceed with deployment"
    sleep 3
else
    echo "Token not provided, please try again"
    exit 1
fi

echo "\nStarting with the Load Balancer\n"
sleep 3
echo "Which Datacenter should the Load Balancer be created in? "
read DC

#
# Create the load balancer and confirm status
create_lb
