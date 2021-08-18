#!/bin/bash

sudo apt-get update && \
sudo apt-get install -y unzip wget python3 python3-pip && \
pip3 install --user boto3 awscli && \
echo "export PATH=~/.local/bin:$PATH" >> .profile

  sudo curl -o terraform_0.15.1_linux_amd64.zip https://releases.hashicorp.com/terraform/0.15.1/terraform_0.15.1_linux_amd64.zip
  sudo unzip -o terraform_0.15.1_linux_amd64.zip -d /bin
  export PATH=$PATH:./bin/

  export KUBE_LATEST_VERSION="v1.20.1"
  sudo wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && sudo chmod +x /usr/local/bin/kubectl

  export HELM_VERSION="v3.5.4"
  sudo wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && sudo chmod +x /usr/local/bin/helm

  helm repo add "stable" "https://charts.helm.sh/stable" --force-update