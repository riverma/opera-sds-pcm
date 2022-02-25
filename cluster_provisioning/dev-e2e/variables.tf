# globals
#
# venue : userId
# counter : 1-n
# private_key_file : the equivalent to .ssh/id_rsa or .pem file
#
variable "artifactory_base_url" {
  default = "https://cae-artifactory.jpl.nasa.gov/artifactory"
}

variable "artifactory_repo" {
  default = "general-develop"
}

variable "artifactory_mirror_url" {
  default = "s3://opera-dev-cc-fwd-ci"
}

variable "hysds_release" {
}

variable "pcm_repo" {
  default = "github.com/nasa/opera-sds-pcm.git"
}

variable "pcm_branch" {
  default = "develop"
}

variable "pcm_commons_repo" {
  default = "github.jpl.nasa.gov/IEMS-SDS/pcm_commons.git"
}

variable "pcm_commons_branch" {
  default = "develop"
}

variable "product_delivery_repo" {
  default = "github.jpl.nasa.gov/IEMS-SDS/CNM_product_delivery.git"
}

variable "opera_bach_api_repo" {
  default = "github.jpl.nasa.gov/opera-sds/opera-bach-api.git"
}

variable "opera_bach_api_branch" {
  default = "develop"
}

variable "opera_bach_ui_repo" {
  default = "github.jpl.nasa.gov/opera-sds/opera-bach-ui.git"
}

variable "opera_bach_ui_branch" {
  default = "develop"
}

variable "product_delivery_branch" {
  default = "develop"
}

variable "venue" {
}

variable "counter" {
  default = ""
}

variable "private_key_file" {
}

variable "git_auth_key" {
}

variable "jenkins_api_user" {
  default = ""
}

variable "keypair_name" {
  default = ""
}

variable "jenkins_api_key" {
}

variable "ops_password" {
  default = "hysdsops"
}

variable "shared_credentials_file" {
  default = "~/.aws/credentials"
}

#
# "default" links to [default] profile in "shared_credentials_file" above
#
variable "profile" {
  default = "saml-pub"
}

variable "project" {
  default = "opera"
}

variable "region" {
  default = "us-west-2"
}

variable "az" {
  default = "us-west-2a"
}

variable "grq_aws_es" {
  default = false
}

variable "grq_aws_es_host" {
  default = "vpce-0d33a52fc8fed6e40-ndiwktos.vpce-svc-09fc53c04147498c5.us-west-2.vpce.amazonaws.com"
}

variable "grq_aws_es_host_private_verdi" {
  default = "vpce-07498e8171c201602-l2wfjtow.vpce-svc-09fc53c04147498c5.us-west-2.vpce.amazonaws.com"
}

variable "grq_aws_es_port" {
  default = 443
}

variable "use_grq_aws_es_private_verdi" {
  default = true
}

variable "subnet_id" {
  default = "subnet-000eb551ad06392c7"
}

variable "verdi_security_group_id" {
}

variable "cluster_security_group_id" {
}

variable "pcm_cluster_role" {
  default = {
    name = "am-pcm-dev-cluster-role"
    path = "/"
  }
}

variable "pcm_verdi_role" {
  default = {
    name = "am-pcm-dev-verdi-role"
    path = "/"
  }
}

# mozart vars
variable "mozart" {
  type = map(string)
  default = {
    name          = "mozart"
    instance_type = "r5.xlarge"
    root_dev_size = 50
    private_ip    = ""
    public_ip     = ""
  }
}

# metrics vars
variable "metrics" {
  type = map(string)
  default = {
    name          = "metrics"
    instance_type = "r5.xlarge"
    private_ip    = ""
    public_ip     = ""
  }
}

# grq vars
variable "grq" {
  type = map(string)
  default = {
    name          = "grq"
    instance_type = "r5.xlarge"
    private_ip    = ""
    public_ip     = ""
  }
}

# factotum vars
variable "factotum" {
  type = map(string)
  default = {
    name          = "factotum"
    instance_type = "c5.xlarge"
    root_dev_size = 50
    data          = "/data"
    data_dev      = "/dev/xvdb"
    data_dev_size = 300
    private_ip    = ""
    public_ip     = ""
  }
}

# ci vars
variable "ci" {
  type = map(string)
  default = {
    name          = "ci"
    instance_type = "c5.xlarge"
    data          = "/data"
    data_dev      = "/dev/xvdb"
    data_dev_size = 100
    private_ip    = ""
    public_ip     = ""
  }
}

variable "common_ci" {
  type = map(string)
  default = {
    name       = "ci"
    private_ip = "100.104.40.248"
    public_ip  = "100.104.40.248"
  }
}

# autoscale vars
variable "autoscale" {
  type = map(string)
  default = {
    name          = "autoscale"
    instance_type = "t2.micro"
    data          = "/data"
    data_dev      = "/dev/xvdb"
    data_dev_size = 300
    private_ip    = ""
    public_ip     = ""
  }
}

# staging area vars

variable "lambda_vpc" {
  default = "vpc-b5a983cd"
}

variable "lambda_role_arn" {
  default = "arn:aws:iam::681612454726:role/am-pcm-dev-lambda-role"
}

variable "lambda_job_type" {
  default = "INGEST_STAGED"
}

variable "lambda_job_queue" {
  default = "opera-job_worker-small"
}

# CNM Response job vars

variable "cnm_r_handler_job_type" {
  default = "process_cnm_response"
}

variable "cnm_r_job_queue" {
  default = "opera-job_worker-rcv_cnm_notify"
}

variable "cnm_r_event_trigger" {
  default = "sqs"
}

variable "cnm_r_allowed_account" {
  default = "*"
}

#The value of daac_delivery_proxy can be
#  arn:aws:sqs:us-west-2:782376038308:daac-proxy-for-opera
#  arn:aws:sqs:us-west-2:871271927522:asf-w2-cumulus-dev-opera-workflow-queue
variable "daac_delivery_proxy" {
  default = "arn:aws:sqs:us-west-2:782376038308:daac-proxy-for-opera"
}

variable "use_daac_cnm" {
  default = false
}

variable "daac_endpoint_url" {
  default = ""
}

# asg vars
variable "asg_use_role" {
  default = "true"
}

variable "asg_role" {
  default = "am-pcm-dev-verdi-role"
}

variable "asg_vpc" {
  default = "vpc-b5a983cd"
}

variable "aws_account_id" {
  default = "681612454726"
}

variable "lambda_package_release" {
  default = "develop"
}

variable "cop_catalog_url" {
  default = ""
}

variable "delete_old_cop_catalog" {
  default = false
}

variable "tiurdrop_catalog_url" {
  default = ""
}

variable "delete_old_tiurdrop_catalog" {
  default = false
}

variable "rost_catalog_url" {
  default = ""
}

variable "delete_old_rost_catalog" {
  default = false
}

variable "pass_catalog_url" {
  default = ""
}

variable "delete_old_pass_catalog" {
  default = false
}

variable "delete_old_observation_catalog" {
  default = false
}

variable "delete_old_track_frame_catalog" {
  default = false
}

variable "delete_old_radar_mode_catalog" {
  default = false
}

variable "environment" {
  default = "dev"
}

variable "use_artifactory" {
  default = false
}

variable "event_misfire_trigger_frequency" {
  default = "rate(5 minutes)"
}

variable "event_misfire_delay_threshold_seconds" {
  type    = number
  default = 60
}

variable "lambda_log_retention_in_days" {
  type    = number
  default = 30
}

variable "pge_snapshots_date" {
  default = "20210805-R2.0.0"
}

variable "pge_release" {
  default = "R2.0.0"
}

variable "crid" {
  default = "D00200"
}

variable "cluster_type" {
  default = "reprocessing"
}

variable "l0a_timer_trigger_frequency" {
  default = "rate(15 minutes)"
}

variable "data_subscriber_timer_trigger_frequency" {
  default = "rate(60 minutes)"
}

variable "obs_acct_report_timer_trigger_frequency" {
  default = "cron(0 0 * * ? *)"
}

variable "rs_fwd_bucket_ingested_expiration" {
  default = 14
}

variable "dataset_bucket" {
  default = ""
}

variable "code_bucket" {
  default = ""
}

variable "lts_bucket" {
  default = ""
}

variable "triage_bucket" {
  default = ""
}

variable "isl_bucket" {
  default = ""
}

variable "osl_bucket" {
  default = ""
}

variable "use_s3_uri_structure" {
  default = true
}

variable "inactivity_threshold" {
  type    = number
  default = 1800
}

variable "queues" {
  default = ""
}

variable "docker_registry_bucket" {
  default = "opera-pcm-registry-bucket"
}

variable "purge_es_snapshot" {
  default = true
}

variable "es_snapshot_bucket" {
  default = "opera-dev-es-bucket"
}

variable "es_bucket_role_arn" {
  default = "arn:aws:iam::271039147104:role/am-es-role"
}

variable "artifactory_fn_user" {
  default = ""
}

variable "artifactory_fn_api_key" {
  default = ""
}

# ami vars
variable "amis" {
  type = map(string)
  default = {
    mozart    = "ami-02fcd254c71ff0fa0"  # opera dev mozart - ol8
    metrics   = "ami-0a54a14946e0bb52f"  # opera dev metrics - ol8
    grq       = "ami-0a11c7d42e24fe7d5"  # opera dev grq - ol8
    factotum  = "ami-0ce5e6a66b7732993"  # opera dev factotum - ol8
    ci        = "ami-0cf8b9a10b8778646"  # opera-pcm-ci-temp
    autoscale = "ami-0cf8b9a10b8778646"  # opera-pcm-ci-temp
  }
}
