#!/bin/bash

  export KUBE_LATEST_VERSION="v1.20.1"
  wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

  export HELM_VERSION="v3.5.4"
  wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
  tar -xvf helm-${HELM_VERSION}-linux-amd64.tar.gz
  mv linux-amd64/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm

  helm repo add "stable" "https://charts.helm.sh/stable" --force-update