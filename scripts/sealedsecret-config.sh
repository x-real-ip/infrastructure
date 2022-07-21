#!/bin/bash
#
# Writtin by Coen Stam.
# github@theautomation.nl
#

key=""
value=""

namespace="home-automation"
secretname="zwavejs2mqtt-eu-settings"

dir="/home/coen/github/"
certname="sealed-secret-tls-2.crt"

echo -n "${value}" | kubectl create secret generic ${secretname} --dry-run=client --from-file=${key}=/dev/stdin -o json | kubeseal --cert ${dir}${certname} -o yaml -n ${namespace} --merge-into ${dir}/secret.yaml
