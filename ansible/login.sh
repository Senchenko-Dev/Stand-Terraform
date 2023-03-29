#!/bin/bash

#set -e
#test

while [ $# -gt 0 ]; do
  case "$1" in
    --token|-t)
      token="${2}"
      shift
      ;;
    --username|-u)
      username="${2}"
      shift
      ;;
    --password|-p)
      password="${2}"
      shift
      ;;
    --host|-h)
      host="${2}"
      shift
      ;;
    --kubeconfig|-k)
      kubeconfig="${2}"
      shift
      ;;
    --print-pass)
      printpass=true
      shift
      ;;
    *)
      printf "ERROR: Unknown parameter $1"
      exit 1
  esac
  shift
done

export KUBECONFIG=$kubeconfig

if [ "$token" == "none" ]
then
  password=$KUBE_PASSWORD #переменная с паролем от OpenShift из Jenkins файла
  echo $password > login.txt

  oc login --username $username --password $password  $host --insecure-skip-tls-verify=true > /dev/null 2>&1
  token=$(oc whoami -t)
  echo -e "{\n  \"apiVersion\": \"client.authentication.k8s.io/v1beta1\",\n  \"kind\": \"ExecCredential\",\n  \"status\": {\n      \"token\": \"${token}\"\n  }\n}"
elif [ -z $token ]
then
  echo $TF_VAR_vault_password
else
  kubectl config set-cluster $host --server=$host --insecure-skip-tls-verify >/dev/null 2>&1
  kubectl config set-credentials deploy-user --token=$token > /dev/null 2>&1
  kubectl config set-context DEPLOY_CONTEXT --cluster=$host --user=deploy-user > /dev/null 2>&1
  kubectl config use-context DEPLOY_CONTEXT > /dev/null 2>&1
  echo -e "{\n  \"apiVersion\": \"client.authentication.k8s.io/v1beta1\",\n  \"kind\": \"ExecCredential\",\n  \"status\": {\n      \"token\": \"${token}\"\n  }\n}"
fi
