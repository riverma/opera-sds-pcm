#!/bin/bash

#----------------------
# E2E-opera-pcm-develop
#
# This shell script is intended for use with the Build step of the
# E2E-opera-pcm-develop Jenkins job. It's contents may be copied as-is
# into the Command text field of the "Execute Shell" Build step.
# ---------------------

source /export/home/hysdsops/verdi/bin/activate

# Get the tag from the end of the GIT_BRANCH
BRANCH="${GIT_BRANCH##*/}"

# Get repo path by removing http://*/ and .git from GIT_URL
REPO="${GIT_URL#*:*/}"
REPO="${REPO%.git}"
REPO="${REPO//\//_}"
IMAGE="container-${REPO,,}"

project=opera
venue=ci
jenkins_api_user=collinss
ops_password=end2endtest
cluster_security_group_id=sg-0748562abca276298
verdi_security_group_id=sg-09a915669ed25d1ed
asg_vpc=vpc-02676637ea26098a7
keypair_name=pcmdev
hysds_release=v4.0.1-beta.8-oraclelinux
product_delivery_branch=develop
lambda_package_release=develop
cnm_r_event_trigger=sqs
pcm_commons_branch=develop

# clean buckets
for i in rs triage lts osl isl; do
  aws s3 rm --recursive s3://opera-dev-${i}-fwd-${venue}/
done

# TODO: opera-dev-osl-reproc-ci does not seem to exist yet
#for i in osl; do
#  aws s3 rm --recursive s3://opera-dev-${i}-reproc-${venue}/
#done

# build dev
cd cluster_provisioning/dev-e2e

echo "Running terraform init"
/home/hysdsops/bin/terraform init -no-color -force-copy

# provision cluster and run end-to-end
# TODO: ts command does not seem to be installed on opera-pcm-ci, need to get https://joeyh.name/code/moreutils/ installed
echo "Running terraform apply"
/home/hysdsops/bin/terraform apply --var pcm_branch=${BRANCH} \
  --var private_key_file=${PRIVATE_KEY_FILE} --var project=$project \
  --var venue=$venue --var jenkins_api_key=${JENKINS_API_KEY} \
  --var git_auth_key=${GIT_OAUTH_TOKEN} --var ops_password=$ops_password \
  --var jenkins_api_user=$jenkins_api_user --var keypair_name=$keypair_name \
  --var cluster_security_group_id=$cluster_security_group_id \
  --var verdi_security_group_id=$verdi_security_group_id \
  --var asg_vpc=$asg_vpc \
  --var hysds_release=$hysds_release \
  --var product_delivery_branch=$product_delivery_branch \
  --var pcm_commons_branch=$pcm_commons_branch \
  --var cnm_r_event_trigger=$cnm_r_event_trigger \
  --var lambda_package_release=$lambda_package_release -no-color -auto-approve || : #| ts '[%Y-%m-%d %H:%M:%.S]' || :

# untaint terraform in case it fails
echo "Running terraform untaint"
/home/hysdsops/bin/terraform untaint null_resource.mozart || :

# clean up resources
# TODO: ts command does not seem to be installed on opera-pcm-ci, need to get https://joeyh.name/code/moreutils/ installed
echo "Running terraform destroy"
/home/hysdsops/bin/terraform destroy --var pcm_branch=${BRANCH} \
  --var private_key_file=${PRIVATE_KEY_FILE} --var project=$project \
  --var venue=$venue --var jenkins_api_key=${JENKINS_API_KEY} \
  --var git_auth_key=${GIT_OAUTH_TOKEN} --var ops_password=$ops_password \
  --var jenkins_api_user=$jenkins_api_user --var keypair_name=$keypair_name \
  --var cluster_security_group_id=$cluster_security_group_id \
  --var verdi_security_group_id=$verdi_security_group_id \
  --var asg_vpc=$asg_vpc \
  --var hysds_release=$hysds_release \
  --var product_delivery_branch=$product_delivery_branch \
  --var pcm_commons_branch=$pcm_commons_branch \
  --var cnm_r_event_trigger=$cnm_r_event_trigger \
  --var lambda_package_release=$lambda_package_release -no-color -auto-approve || : #| ts '[%Y-%m-%d %H:%M:%.S]' || :

# print out the check_pcm.xml
cat check_pcm.xml
