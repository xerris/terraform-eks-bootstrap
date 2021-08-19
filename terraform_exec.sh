#!/bin/bash
set -o nounset
set -o errexit


echo "###############################"
echo "## Starting Terraform script ##"
echo "###############################"

ENV="${ENV:-dev}"
AWS_REGION="${AWS_REGION:-ca-central-1}"
echo "Configuring AWS Profiles"
export AWS_PROFILE=default

#temp_role=$(aws sts assume-role --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/deployment-role" --role-session-name "RoleSession1" --profile default)
#aws configure set aws_access_key_id $(echo $temp_role | jq .Credentials.AccessKeyId | xargs) --profile deployment-profile
#aws configure set aws_secret_access_key $(echo $temp_role | jq .Credentials.SecretAccessKey | xargs) --profile deployment-profile
#aws configure set aws_session_token $(echo $temp_role | jq .Credentials.SessionToken | xargs) --profile deployment-profile

aws configure set role_arn "arn:aws:iam::${ACCOUNT_ID}:role/deployment-role" --profile deployment-profile
aws configure set source_profile default --profile deployment-profile
aws configure set role_session_name test-session --profile deployment-profile
export AWS_PROFILE=deployment-profile

APPLY=${1:-0} #If set terraform will force apply changes
commit_hash=`git rev-parse --short HEAD`
build_number="${BITBUCKET_BUILD_NUMBER:=local}"
#export TF_LOG=TRACE
export TF_VAR_commit_hash="${commit_hash}"
export TF_VAR_build_number="${build_number}"

terraform init \
-upgrade \
-backend-config="bucket=project-eks-terraform-state-${ENV}" \
-backend-config="key=${ENV}/project-eks-bootstrap.tfstate" \
-backend-config="dynamodb_table=${ENV}-project-eks-terraform-state-lock-dynamo" \
-backend-config="region=${AWS_REGION}"


terraform validate
terraform plan -var-file=envs/${ENV}.tfvars

if [ $APPLY == 2 ]; then
    echo "###############################"
    echo "## Executing terraform destroy ##"
    echo "###############################"
    terraform destroy --auto-approve -var-file=envs/${ENV}.tfvars
fi

if [ $APPLY == 1 ]; then
    echo "###############################"
    echo "## Executing terraform apply ##"
    echo "###############################"
    terraform apply --auto-approve -var-file=envs/${ENV}.tfvars
fi
