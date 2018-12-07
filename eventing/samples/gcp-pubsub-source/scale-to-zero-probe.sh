#!/bin/bash

when ()
{
    ts '[%Y-%m-%d %H:%M:%.S]'
}

while :
do
    echo "Waiting for Revision to scale to zero (6 min)" | when
    sleep 360
    kubectl get deploy | grep 'message-dumper' | when

    echo "Publishing a random message and waiting for scale from zero (30 sec)" | when
    WANT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    gcloud pubsub topics publish testing --message="$WANT"
    sleep 30
    kubectl get deploy | grep 'message-dumper' | when

    echo "Looking for the random message" | when
    GOT=$(kubectl logs -l serving.knative.dev/service=message-dumper -c user-container | grep '{' | jq1.6 -r '.Data | @base64d' | grep "$WANT")

    echo "Got $GOT. Want $WANT." | when

    if [ "$WANT" != "$GOT" ]; then
	echo "FAIL" | when
    else
	echo "PASS" | when
    fi
    echo

done

