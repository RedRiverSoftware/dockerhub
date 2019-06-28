#!/bin/bash

echo cloudflare-cli: k8s-tools v0.0.6

bad=0
if [ -z "$action" ]; then echo "variable 'action' is not set"; bad=1; fi
if [ -z "$subdomain" ]; then echo "variable 'subdomain' is not set"; bad=1; fi
if [ -z "$CF_API_KEY" ]; then echo "variable 'CF_API_KEY' is not set"; bad=1; fi
if [ -z "$CF_API_EMAIL" ]; then echo "variable 'CF_API_EMAIL' is not set"; bad=1; fi
if [ -z "$CF_API_DOMAIN" ]; then echo "variable 'CF_API_DOMAIN' is not set"; bad=1; fi
if [ $action = "create" ]; then
	if [ -z "$service" ]; then echo "variable 'service' is not set"; bad=1; fi
	if [ -z "$deployment" ]; then echo "variable 'deployment' is not set"; bad=1; fi
	if [ -z "$namespace" ]; then echo "variable 'namespace' is not set"; bad=1; fi
fi
if [ $bad -eq 1 ]
then
	echo "please set variables: action, subdomain, CF_API_KEY, CF_API_EMAIL, CF_API_DOMAIN"
	echo "if action is create, please specify these variables too: namespace, deployment, service"
	echo "valid actions: create, delete"
	exit 1
fi

bad=1
if [ $action = "create" ]; then
	bad=0

	echo waiting for deployment to rollout...
	kubectl --namespace=$namespace rollout status deployment/$deployment

	echo waiting for service to rollout...
	kubectl --namespace=$namespace rollout status service/$service
	
	echo getting service info...
	service=$(kubectl --namespace=$namespace get service $service --output=json)
	retVal=$?
	if [ $retVal -ne 0 ]; then
		echo failed
		exit 1
	fi
	if [ -z "$service" ]; then echo "no service data returned"; exit 1; fi
	echo got service info

	echo getting external IP...
	ip=$(echo "$service" | jq -r '.status.loadBalancer.ingress | .[] | .ip')
	retVal=$?
	if [ $retVal -ne 0 ]; then
		echo failed
		exit 1
	fi
	if [ -z "$ip" ]; then echo "ip not found"; exit 1; fi
	echo public IP: $ip

	echo deleting any existing record...
	cfcli -e $CF_API_EMAIL -k $CF_API_KEY -d $CF_API_DOMAIN -a -t A rm $subdomain

    echo adding...
    cfcli -e $CF_API_EMAIL -k $CF_API_KEY -d $CF_API_DOMAIN -a -t A add $subdomain $ip
    retVal=$?
fi
if [ $action = "delete" ]; then
	bad=0
    echo deleting...
	cfcli -e $CF_API_EMAIL -k $CF_API_KEY -d $CF_API_DOMAIN -a -t A rm $subdomain
    retVal=$?
fi
if [ $bad -eq 1 ]; then echo "unknown action - use create or delete"; exit 1; fi

if [ $retVal -ne 0 ]; then
	echo failed
	exit 1
fi
echo success!
