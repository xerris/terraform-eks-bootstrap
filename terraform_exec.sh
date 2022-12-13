#!/bin/bash
set -o nounset
set -o errexit


echo "###############################"
echo "## Starting Terraform script ##"
echo "###############################"

ENV="${ENV:-dev}"
AWS_REGION="${AWS_REGION:-us-east-1}"
echo "Configuring AWS Profiles"
export AWS_PROFILE=default

#aws configure set role_arn "arn:aws:iam::${ACCOUNT_ID}:role/deployment-role" --profile deployment-profile
#aws configure set source_profile default --profile deployment-profile
#aws configure set role_session_name test-session --profile deployment-profile
#export AWS_PROFILE=deployment-profile

APPLY=${1:-0} #If set terraform will force apply changes
commit_hash=`git rev-parse --short HEAD`
#build_number="${BITBUCKET_BUILD_NUMBER:=local}"
#export TF_LOG=TRACE
#export TF_VAR_commit_hash="${commit_hash}"
#export TF_VAR_build_number="${build_number}"
terraform init \
--upgrade \
-backend-config="bucket=project-terraform-state-ginu3-${ENV}" \
-backend-config="key=${ENV}/project-eks-bootstrap.tfstate" \
-backend-config="dynamodb_table=${ENV}-project-ginu5-terraform-state-lock-dynamo" \
-backend-config="region=${AWS_REGION}"
 

export DESTROY=""

terraform validate
if [ $APPLY == 2 ]; then export DESTROY="-destroy"; fi
terraform plan $DESTROY -var-file=envs/${ENV}.tfvars

if [ $APPLY == 1 ]; then
    echo "###############################"
    echo "## Executing terraform apply ##"
    echo "###############################"
    terraform apply --auto-approve -var-file=envs/${ENV}.tfvars
    #return 0
    ### CI/CD installation ####
    echo "###############################"
    echo "## installing CI/CD Tool ##"
    echo "###############################"

    rm -rf .terraform
    cd cicd
    ls -la
    pwd
    aws eks update-kubeconfig --region $AWS_REGION --name project_eks_cluster_ginu-$ENV --kubeconfig "~/.kube/config"
    kubectl get ns
    

    
    terraform init \
    -backend-config="bucket=project-terraform-state-ginu3-${ENV}" \
    -backend-config="key=${ENV}/project-eks-bootstrap-cicd.tfstate" \
    -backend-config="dynamodb_table=${ENV}-project-ginu5-terraform-state-lock-dynamo" \
    -backend-config="region=${AWS_REGION}"

    # terraform import -var-file=../envs/dev.tfvars -lock=false -var="flux_token=${2}" -var="github_user=${3}" module.flux2_crd.kubernetes_namespace.flux2 flux2-system
    # terraform import -var-file=../envs/dev.tfvars -lock=false -var="flux_token=${2}" -var="github_user=${3}" module.flux_repo_2048_stage.kubernetes_secret.main flux2-system/2048-k8-app-xdp-ginu-dev-secret
    # terraform import -var-file=../envs/dev.tfvars -lock=false -var="flux_token=${2}" -var="github_user=${3}" module.flux_repo_addons.kubernetes_secret.main flux2-system/kubernetes-addons-bootstrap-dev-secret

    #terraform state rm module.flux2_crd.kubernetes_namespace.flux2
    terraform validate

    terraform plan -var-file=../envs/${ENV}.tfvars -var="flux_token=${2}" -var="github_user=${3}"

    echo "###############################"
    echo "## Executing terraform apply for CI/CD ##"
    echo "###############################"
    #terraform destroy --auto-approve -var-file=../envs/${ENV}.tfvars -var="flux_token=${2}" -var="github_user=${3}"
    terraform apply --auto-approve -var-file=../envs/${ENV}.tfvars -var="flux_token=${2}" -var="github_user=${3}"
fi


if [ $APPLY == 2 ]; then
    echo "###############################"
    echo "## Executing terraform destroy for CI/CD ##"
    echo "###############################"
    pushd cicd
    aws eks update-kubeconfig --region $AWS_REGION --name project_eks_cluster-ginu-$ENV --kubeconfig "~/.kube/config"

    terraform init \
    -backend-config="bucket=project-terraform-state-ginu3-${ENV}" \
    -backend-config="key=${ENV}/project-eks-bootstrap.tfstate" \
    -backend-config="dynamodb_table=${ENV}-project-ginu5-terraform-state-lock-dynamo" \
    -backend-config="region=${AWS_REGION}"
    terraform destroy --auto-approve -var-file=../envs/${ENV}.tfvars -var="flux_token=${2}" -var="github_user=${3}"

    echo "###############################"
    echo "## Executing terraform destroy ##"
    echo "###############################"
    popd
    terraform init \
    -upgrade \
    -backend-config="bucket=project-terraform-state-ginu3-${ENV}" \
    -backend-config="key=${ENV}/project-eks-bootstrap.tfstate" \
    -backend-config="dynamodb_table=${ENV}-project-ginu5-terraform-state-lock-dynamo" \
    -backend-config="region=${AWS_REGION}"

    terraform destroy --auto-approve -var-file=envs/${ENV}.tfvars

fi
