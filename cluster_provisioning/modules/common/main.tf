locals {
  counter                        = var.counter != "" ? var.counter : random_id.counter.hex
  default_dataset_bucket         = "${var.project}-${var.environment}-rs-fwd-${var.venue}"
  dataset_bucket                 = var.dataset_bucket != "" ? var.dataset_bucket : local.default_dataset_bucket
  default_code_bucket            = "${var.project}-${var.environment}-cc-fwd-${var.venue}"
  code_bucket                    = var.code_bucket != "" ? var.code_bucket : local.default_code_bucket
  default_isl_bucket             = "${var.project}-${var.environment}-isl-fwd-${var.venue}"
  isl_bucket                     = var.isl_bucket != "" ? var.isl_bucket : local.default_isl_bucket
  default_osl_bucket             = "${var.project}-${var.environment}-osl-fwd-${var.venue}"
  osl_bucket                     = var.osl_bucket != "" ? var.osl_bucket : local.default_osl_bucket
  default_triage_bucket          = "${var.project}-${var.environment}-triage-fwd-${var.venue}"
  triage_bucket                  = var.triage_bucket != "" ? var.triage_bucket : local.default_triage_bucket
  default_lts_bucket             = "${var.project}-${var.environment}-lts-fwd-${var.venue}"
  lts_bucket                     = var.lts_bucket != "" ? var.lts_bucket : local.default_lts_bucket
  key_name                       = var.keypair_name != "" ? var.keypair_name : split(".", basename(var.private_key_file))[0]
  sns_count                      = var.cnm_r_event_trigger == "sns" ? 1 : 0
  kinesis_count                  = var.cnm_r_event_trigger == "kinesis" ? 1 : 0
  sqs_count                      = var.cnm_r_event_trigger == "sqs" ? 1 : 0
  lambda_repo                    = "${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pcm/lambda"
  daac_delivery_event_type       = split(":", var.daac_delivery_proxy)[2]
  daac_delivery_region           = split(":", var.daac_delivery_proxy)[3]
  daac_delivery_account          = split(":", var.daac_delivery_proxy)[4]
  daac_delivery_resource_name    = split(":", var.daac_delivery_proxy)[5]
  pge_artifactory_dev_url        = "${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pcm/pge_snapshots/${var.pge_snapshots_date}"
  pge_artifactory_release_url    = "${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pge/"
  daac_proxy_cnm_r_sns_count     = var.environment == "dev" && var.venue != "int" && local.sqs_count == 1 ? 1 : 0
  maturity                       = split("-", var.daac_delivery_proxy)[5]
  timer_handler_job_type         = "timer_handler"
  accountability_report_job_type = "accountability_report"
  data_subscriber_job_type       = "data_subscriber"
  use_s3_uri_structure           = var.use_s3_uri_structure
  grq_es_url                     = "${var.grq_aws_es ? "https" : "http"}://${var.grq_aws_es ? var.grq_aws_es_host : aws_instance.grq.private_ip}:${var.grq_aws_es ? var.grq_aws_es_port : 9200}"


  cnm_response_queue_name = {
    "dev"  = "opera-dev-daac-cnm-response"
    "int"  = "opera-int-daac-cnm-response"
    "test" = "opera-test-daac-cnm-response"
  }
  cnm_response_dl_queue_name = {
    "dev"  = "opera-dev-daac-cnm-response-dead-letter-queue"
    "int"  = "opera-int-daac-cnm-response-dead-letter-queue"
    "test" = "opera-test-daac-cnm-response-dead-letter-queue"
  }

  e_misfire_metric_alarm_name = "${var.project}-${var.venue}-${local.counter}-event-misfire"
  enable_timer = var.cluster_type == "reprocessing" ? false : true
}
resource "null_resource" "download_lambdas" {
  provisioner "local-exec" {
    command = "curl ${local.lambda_repo}/${var.lambda_package_release}/${var.lambda_cnm_r_handler_package_name}-${var.lambda_package_release}.zip -o ${var.lambda_cnm_r_handler_package_name}-${var.lambda_package_release}.zip"
  }
  provisioner "local-exec" {
    command = "curl ${local.lambda_repo}/${var.lambda_package_release}/${var.lambda_harikiri_handler_package_name}-${var.lambda_package_release}.zip -o ${var.lambda_harikiri_handler_package_name}-${var.lambda_package_release}.zip"
  }
  provisioner "local-exec" {
    command = "curl ${local.lambda_repo}/${var.lambda_package_release}/${var.lambda_isl_handler_package_name}-${var.lambda_package_release}.zip -o ${var.lambda_isl_handler_package_name}-${var.lambda_package_release}.zip"
  }
  provisioner "local-exec" {
    command = "curl ${local.lambda_repo}/${var.lambda_package_release}/${var.lambda_e-misfire_handler_package_name}-${var.lambda_package_release}.zip -o ${var.lambda_e-misfire_handler_package_name}-${var.lambda_package_release}.zip"
  }
  provisioner "local-exec" {
    command = "curl ${local.lambda_repo}/${var.lambda_package_release}/${var.lambda_timer_handler_package_name}-${var.lambda_package_release}.zip -o ${var.lambda_timer_handler_package_name}-${var.lambda_package_release}.zip"
  }
  provisioner "local-exec" {
    command = "curl ${local.lambda_repo}/${var.lambda_package_release}/${var.lambda_report_handler_package_name}-${var.lambda_package_release}.zip -o ${var.lambda_report_handler_package_name}-${var.lambda_package_release}.zip"
  }
  provisioner "local-exec" {
    command = "curl ${local.lambda_repo}/${var.lambda_package_release}/${var.lambda_data_subscriber_handler_package_name}-${var.lambda_package_release}.zip -o ${var.lambda_data_subscriber_handler_package_name}-${var.lambda_package_release}.zip"
  }
}

resource "null_resource" "is_cnm_r_event_trigger_value_valid" {
  count = contains(var.cnm_r_event_trigger_values_list, var.cnm_r_event_trigger) ? 0 : "ERROR: The cnm_r_event_trigger value can only be: sns or kinesis"
}

resource "null_resource" "is_cluster_type_valid" {
  count = contains(var.valid_cluster_type_values, var.cluster_type) ? 0 : "ERROR: cluster_type must be one of the following: ${var.valid_cluster_type_values}"
}

resource "random_id" "counter" {
  byte_length = 2
}

##############################
## CloudWatch Dashboard
##############################

resource "aws_cloudwatch_dashboard" "terraform-dashboard" {
  dashboard_name = "${var.project}-${var.venue}-${local.counter}-dashboard"

  dashboard_body = <<EOF
 {
   "widgets": [
       {
          "type":"metric",
          "x":0,
          "y":0,
          "width":12,
          "height":6,
          "properties":{
             "metrics":[
                [
                   "AWS/EC2",
                   "CPUUtilization",
                   "InstanceId",
                   "${aws_instance.mozart.id}"
                ]
             ],
             "period":60,
             "stat":"Average",
             "region":"${var.region}",
             "title":"${var.project}-${var.venue}-${local.counter}-mozart CPU"
          }
       },
       {
          "type":"metric",
          "x":20,
          "y":0,
          "width":12,
          "height":6,
          "properties":{
             "metrics":[
                [
                   "AWS/EC2",
                   "CPUUtilization",
                   "InstanceId",
                   "${aws_instance.metrics.id}"
                ]
             ],
             "period":60,
             "stat":"Average",
             "region":"${var.region}",
             "title":"${var.project}-${var.venue}-${local.counter}-metrics CPU"
          }
          },
          {
          "type":"metric",
          "x":0,
          "y":20,
          "width":12,
          "height":6,
          "properties":{
             "metrics":[
                [
                   "AWS/EC2",
                   "CPUUtilization",
                   "InstanceId",
                   "${aws_instance.grq.id}"
                ]
             ],
             "period":60,
             "stat":"Average",
             "region":"${var.region}",
             "title":"${var.project}-${var.venue}-${local.counter}-grq CPU"
          }
       },
       {
          "type":"metric",
          "x":20,
          "y":20,
          "width":12,
          "height":6,
          "properties":{
             "metrics":[
                [
                   "AWS/EC2",
                   "CPUUtilization",
                   "InstanceId",
                   "${aws_instance.factotum.id}"
                ]
             ],
             "period":60,
             "stat":"Average",
             "region":"${var.region}",
             "title":"${var.project}-${var.venue}-${local.counter}-factotum CPU"
          }
       },
       {
          "type":"metric",
          "x":0,
          "y":40,
          "width":12,
          "height":6,
          "properties":{
             "metrics":[
                [
                   "CWAgent",
                   "mem_used_percent",
                   "InstanceId",
                   "${aws_instance.mozart.id}",
                   "ImageId",
                   "${var.amis["mozart"]}",
                   "InstanceType",
                   "${var.mozart["instance_type"]}"
                ]
             ],
             "period":300,
             "stat":"Average",
             "region":"${var.region}",
             "title":"CWAgent mozart mem_used_percent"
          }
       },
       {
          "type":"metric",
          "x":20,
          "y":40,
          "width":12,
          "height":6,
          "properties":{
             "metrics":[
                [
                   "CWAgent",
                   "disk_used_percent",
                   "InstanceId",
                   "${aws_instance.mozart.id}",
                   "ImageId",
                   "${var.amis["mozart"]}",
                   "InstanceType",
                   "${var.mozart["instance_type"]}",
                   "fstype",
                   "xfs",
                   "device",
                   "nvme0n1p1",
                   "path",
                   "/"
                ]
             ],
             "period":300,
             "stat":"Average",
             "region":"${var.region}",
             "title":"CWAgent mozart disk usage"
          }
       },
       {
          "type":"metric",
          "x":0,
          "y":80,
          "width":12,
          "height":6,
          "properties":{
             "metrics":[
                [
                   "CWAgent",
                   "cpu_usage_iowait",
                   "InstanceId",
                   "${aws_instance.mozart.id}",
                   "ImageId",
                   "${var.amis["mozart"]}",
                   "InstanceType",
                   "${var.mozart["instance_type"]}",
                   "cpu",
                   "cpu1"
                ],
                [
                   "CWAgent",
                   "cpu_usage_iowait",
                   "InstanceId",
                   "${aws_instance.mozart.id}",
                   "ImageId",
                   "${var.amis["mozart"]}",
                   "InstanceType",
                   "${var.mozart["instance_type"]}",
                   "cpu",
                   "cpu2"
                ],
                                [
                   "CWAgent",
                   "cpu_usage_iowait",
                   "InstanceId",
                   "${aws_instance.mozart.id}",
                   "ImageId",
                   "${var.amis["mozart"]}",
                   "InstanceType",
                   "${var.mozart["instance_type"]}",
                   "cpu",
                   "cpu3"
                ],
                                [
                   "CWAgent",
                   "cpu_usage_iowait",
                   "InstanceId",
                   "${aws_instance.mozart.id}",
                   "ImageId",
                   "${var.amis["mozart"]}",
                   "InstanceType",
                   "${var.mozart["instance_type"]}",
                   "cpu",
                   "cpu4"
                ]
             ],
             "period":300,
             "stat":"Average",
             "region":"${var.region}",
             "title":"CWAgent cpu_usage_iowait"
          }
       }
   ]
 }
 EOF
}


##############################
## Alarms
##############################

resource "aws_cloudwatch_metric_alarm" "mozart_cpualarm" {
  alarm_name                = "${var.project}-${var.venue}-${local.counter}-mozart CPU"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "90"
  alarm_description         = "This metric monitors mozart cpu utilization"
  insufficient_data_actions = []
  dimensions = {
    InstanceId = aws_instance.mozart.id
  }
}

resource "aws_cloudwatch_metric_alarm" "metrics_cpualarm" {
  alarm_name                = "${var.project}-${var.venue}-${local.counter}-metrics CPU"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "90"
  alarm_description         = "This metric monitors metrics cpu utilization"
  insufficient_data_actions = []
  dimensions = {
    InstanceId = aws_instance.metrics.id
  }
}

resource "aws_cloudwatch_metric_alarm" "grq_cpualarm" {
  alarm_name                = "${var.project}-${var.venue}-${local.counter}-grq CPU"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "90"
  alarm_description         = "This metric monitors grq cpu utilization"
  insufficient_data_actions = []
  dimensions = {
    InstanceId = aws_instance.grq.id
  }
}

resource "aws_cloudwatch_metric_alarm" "factotum_cpualarm" {
  alarm_name                = "${var.project}-${var.venue}-${local.counter}-factotum CPU"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "90"
  alarm_description         = "This metric monitors factotum cpu utilization"
  insufficient_data_actions = []
  dimensions = {
    InstanceId = aws_instance.factotum.id
  }
}

resource "aws_cloudwatch_metric_alarm" "mozart_memoryalarm" {
  alarm_name                = "CWAgent Memory"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "mem_used_percent"
  namespace                 = "CWAgent"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "90"
  alarm_description         = "This metric monitors mozart memory utilization"
  insufficient_data_actions = []
  dimensions = {
    InstanceId   = aws_instance.mozart.id
    ImageId      = var.amis["mozart"]
    InstanceType = var.mozart["instance_type"]
  }
}

resource "aws_cloudwatch_metric_alarm" "mozart_diskalarm" {
  alarm_name                = "${var.project}-${var.venue}-${local.counter}-mozart disk usage"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "75"
  alarm_description         = "This metric monitors mozart disk utilization"
  insufficient_data_actions = []
  dimensions = {
    InstanceId   = aws_instance.mozart.id
    ImageId      = var.amis["mozart"]
    InstanceType = var.mozart["instance_type"]
    device       = "nvme0n1p1"
    fstype       = "xfs"
    path         = "/"
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_cnm_r_dead_letter_alarm" {
  count                     = local.sqs_count
  alarm_name                = "${var.project}-${var.venue}-${local.counter}-mozart CNM-R dead letter queue"
  depends_on                = [aws_sqs_queue.cnm_response_dead_letter_queue]
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "ApproximateNumberOfMessagesVisible"
  namespace                 = "AWS/SQS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "5"
  alarm_description         = "This metric monitors size of CNM-R dead letter queue"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.operator_notify.arn]
  dimensions = {
    QueueName = aws_sqs_queue.cnm_response_dead_letter_queue[count.index].name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_dead_letter_alarm" {
  alarm_name                = "${var.project}-${var.venue}-${local.counter}-mozart ISL dead letter queue"
  depends_on                = [aws_sqs_queue.isl_dead_letter_queue]
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "ApproximateNumberOfMessagesVisible"
  namespace                 = "AWS/SQS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "5"
  alarm_description         = "This metric monitors size of isl dead letter queue"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.operator_notify.arn]
  dimensions = {
    QueueName = aws_sqs_queue.isl_dead_letter_queue.name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_event_misfire_alarm" {
  alarm_name                = "${var.project}-${var.venue}-${local.counter}-event-misfire"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "NumberOfMissedFiles"
  namespace                 = "AWS/Lambda"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_description         = "This metric monitors size of input files in ${local.isl_bucket} missed for firing events"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.operator_notify.arn]
  dimensions = {
    LAMBDA_NAME                 = "event-misfire_lambda"
    E_MISFIRE_METRIC_ALARM_NAME = "${var.project}-${var.venue}-${local.counter}-event-misfire"
  }
}


######################
# sns
######################

# SNS Topic that the operator will subscribe to. All failed event messages
# should be sent here
resource "aws_sns_topic" "operator_notify" {
  name = "${var.project}-${var.venue}-${local.counter}-operator-notify"
}

resource "aws_sns_topic_policy" "operator_notify" {
  depends_on = [aws_sns_topic.operator_notify, data.aws_iam_policy_document.operator_notify]
  arn        = aws_sns_topic.operator_notify.arn
  policy     = data.aws_iam_policy_document.operator_notify.json
}

data "aws_iam_policy_document" "operator_notify" {
  depends_on = [aws_sns_topic.operator_notify]
  policy_id  = "__default_policy_ID"
  statement {
    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:Receive",
      "SNS:AddPermission",
      "SNS:Subscribe"
    ]

    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_sns_topic.operator_notify.arn
    ]
    sid = "__default_statement_ID"
  }
}

######################
# sqs
######################
resource "aws_sqs_queue" "harikiri_queue" {
  name                      = "${var.project}-${var.venue}-${local.counter}-queue"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 0
  visibility_timeout_seconds = 600
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.harikiri_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "harikirisqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": {
          "AWS": "arn:aws:iam::${var.aws_account_id}:role/${var.asg_role}"
      },
      "Action": [
          "SQS:SendMessage",
          "SQS:GetQueueUrl"
      ],
      "Resource": "${aws_sqs_queue.harikiri_queue.arn}"
    }
  ]
}
POLICY
}

resource "aws_sqs_queue" "cnm_response_dead_letter_queue" {
  count                     = local.sqs_count
  name                      = "${var.project}-${var.venue}-${local.counter}-daac-cnm-response-dead-letter-queue"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "cnm_response" {
  count                      = local.sqs_count
  name                       = "${var.project}-${var.venue}-${local.counter}-daac-cnm-response"
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.cnm_response_dead_letter_queue[count.index].arn}\", \"maxReceiveCount\": 2}"
  visibility_timeout_seconds = 300
  receive_wait_time_seconds  = 10
}

data "aws_sqs_queue" "cnm_response" {
  count      = local.sqs_count
  depends_on = [aws_sqs_queue.cnm_response]
  name       = aws_sqs_queue.cnm_response[count.index].name
}

resource "aws_lambda_event_source_mapping" "cnm_response" {
  depends_on       = [aws_sqs_queue.cnm_response, aws_lambda_function.cnm_response_handler]
  count            = local.sqs_count
  event_source_arn = var.use_daac_cnm == true ? var.daac_cnm_sqs_arn[local.maturity] : aws_sqs_queue.cnm_response[count.index].arn
  function_name    = aws_lambda_function.cnm_response_handler.arn
}

data "aws_iam_policy_document" "cnm_response" {
  count     = local.daac_proxy_cnm_r_sns_count
  policy_id = "SQSDefaultPolicy"
  statement {
    actions = [
      "SQS:SendMessage"
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      data.aws_sqs_queue.cnm_response[count.index].arn
    ]
    sid = "Sid1571258347580"
  }
}

resource "aws_sqs_queue_policy" "cnm_response" {
  count     = local.daac_proxy_cnm_r_sns_count
  queue_url = data.aws_sqs_queue.cnm_response[count.index].url
  policy    = data.aws_iam_policy_document.cnm_response[count.index].json
}

resource "aws_sqs_queue" "isl_queue" {
  name                       = "${var.project}-${var.venue}-${local.counter}-isl-queue"
  delay_seconds              = 0
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 60
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.isl_dead_letter_queue.arn
    maxReceiveCount     = 2
  })
}
resource "aws_sqs_queue_policy" "isl_queue_policy" {
  queue_url = aws_sqs_queue.isl_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "islsqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "SQS:SendMessage",
      "Resource": "${aws_sqs_queue.isl_queue.arn}",
      "Condition": {
        "ArnLike": { "aws:SourceArn": "arn:aws:s3:*:*:${local.isl_bucket}" }
      }
    }
  ]
}
POLICY
}
resource "aws_s3_bucket_object" "folder" {
  bucket = local.isl_bucket
  acl    = "private"
  key    = "met_required/"
  source = "/dev/null"
}

resource "aws_s3_bucket_notification" "sqs_isl_notification" {
  bucket = local.isl_bucket

  queue {
    id        = "sqs_event"
    queue_arn = aws_sqs_queue.isl_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }

}

resource "aws_sqs_queue" "isl_dead_letter_queue" {
  name                       = "${var.project}-${var.venue}-${local.counter}-isl-dead-letter-queue"
  delay_seconds              = 0
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 500
}

######################
# lambda
######################
resource "aws_lambda_function" "harikiri_lambda" {
  depends_on    = [null_resource.download_lambdas]
  filename      = "${var.lambda_harikiri_handler_package_name}-${var.lambda_package_release}.zip"
  description   = "Lambda function to terminate & decrement instances from their ASG"
  function_name = "${var.project}-${var.venue}-${local.counter}-harikiri-autoscaling"
  role          = var.lambda_role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"
  timeout       = 600
}

resource "aws_cloudwatch_log_group" "harikiri_lambda" {
  name              = "/aws/lambda/${var.project}-${var.venue}-${local.counter}-harikiri-autoscaling"
  retention_in_days = var.lambda_log_retention_in_days
}


resource "aws_lambda_event_source_mapping" "harikiri_queue_event_source_mapping" {
  batch_size       = 1
  enabled          = true
  event_source_arn = aws_sqs_queue.harikiri_queue.arn
  function_name    = aws_lambda_function.harikiri_lambda.arn
}

data "aws_subnet_ids" "lambda_vpc" {
  vpc_id = var.lambda_vpc
}

resource "aws_lambda_function" "isl_lambda" {
  depends_on    = [null_resource.download_lambdas, aws_sns_topic.operator_notify]
  filename      = "${var.lambda_isl_handler_package_name}-${var.lambda_package_release}.zip"
  description   = "Lambda function to process data from ISL bucket"
  function_name = "${var.project}-${var.venue}-${local.counter}-isl-lambda"
  handler       = "lambda_function.lambda_handler"
  role          = var.lambda_role_arn
  runtime       = "python3.7"
  timeout       = 60
  vpc_config {
    security_group_ids = [var.cluster_security_group_id]
    subnet_ids         = data.aws_subnet_ids.lambda_vpc.ids
  }
  environment {
    variables = {
      "JOB_TYPE"            = var.lambda_job_type
      "JOB_RELEASE"         = var.pcm_branch
      "JOB_QUEUE"           = var.lambda_job_queue
      "MOZART_URL"          = "https://${aws_instance.mozart.private_ip}/mozart"
      "DATASET_S3_ENDPOINT" = "s3-us-west-2.amazonaws.com"
      "SIGNAL_FILE_SUFFIX"  = "{\"met_required\":{\"ext\":\".signal\"}}"
      "ISL_SNS_TOPIC"       = aws_sns_topic.operator_notify.arn
      "MET_REQUIRED"        = "met_required"
    }
  }
}

resource "aws_cloudwatch_log_group" "isl_lambda" {
  name              = "/aws/lambda/${var.project}-${var.venue}-${local.counter}-isl-lambda"
  retention_in_days = var.lambda_log_retention_in_days
}

resource "aws_lambda_event_source_mapping" "isl_queue_event_source_mapping" {
  batch_size       = 10
  enabled          = true
  event_source_arn = aws_sqs_queue.isl_queue.arn
  function_name    = aws_lambda_function.isl_lambda.arn
}

#####################################
# sds config  QUEUE block generation
#####################################
data "template_file" "config" {
  template = file("${path.module}/config.tmpl")
  count    = length(var.queues)
  #the spacing in inst is determined by trial and error, so the resulting terraform generated YAML is valid
  vars = {
    queue = element(keys(var.queues), count.index)
    inst  = join("\n      - ", lookup(lookup(var.queues, element(keys(var.queues), count.index)), "instance_type"))
  }
}

data "template_file" "q_config" {
  template = file("${path.module}/config2.tmpl")
  #the spacing in queue is determined by trial and error, so the resulting terraform generated YAML is valid
  vars = {
    queue = join("\n", data.template_file.config.*.rendered)
  }
}

######################
# mozart
######################
resource "aws_instance" "mozart" {
  depends_on           = [aws_instance.metrics, aws_autoscaling_group.autoscaling_group]
  ami                  = var.amis["mozart"]
  instance_type        = var.mozart["instance_type"]
  key_name             = local.key_name
  availability_zone    = var.az
  iam_instance_profile = var.pcm_cluster_role["name"]
  private_ip           = var.mozart["private_ip"] != "" ? var.mozart["private_ip"] : null
  user_data            = <<-EOF
              GRQIP=${aws_instance.grq.private_ip}
              METRICSIP=${aws_instance.metrics.private_ip}
              EOF

  tags = {
    Name  = "${var.project}-${var.venue}-${local.counter}-pcm-${var.mozart["name"]}",
    Bravo = "pcm"
  }
  volume_tags = {
    Bravo = "pcm"
  }
  #This is very important, as it tells terraform to not mess with tags
  lifecycle {
    ignore_changes = [tags]
  }
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.cluster_security_group_id]

  root_block_device {
    volume_size           = var.mozart["root_dev_size"]
    volume_type           = "gp2"
    delete_on_termination = true
  }

  connection {
    type        = "ssh"
    host        = aws_instance.mozart.private_ip
    user        = "hysdsops"
    private_key = file(var.private_key_file)
  }

  provisioner "local-exec" {
    command = "echo export MOZART_IP=${aws_instance.mozart.private_ip} > mozart_ip.sh"
  }

  provisioner "file" {
    source      = var.private_key_file
    destination = ".ssh/${basename(var.private_key_file)}"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/bash_profile.mozart.tmpl", {})
    destination = ".bash_profile"
  }

  provisioner "file" {
    content     = data.template_file.q_config.rendered
    destination = "~/q_config"
  }

  provisioner "file" {
    source      = "${path.module}/../../../tools/download_artifact.sh"
    destination = "~/download_artifact.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "chmod 755 ~/download_artifact.sh",
      "chmod 400 ~/.ssh/${basename(var.private_key_file)}",
      "mkdir ~/.sds",

      "for i in {1..18}; do",
        "if [[ `grep \"redis single-password\" ~/.creds` != \"\" ]]; then",
          "echo \"redis password found in ~/.creds\"",
          "break",
        "else",
          "echo \"redis password NOT found in ~/.creds, sleeping 10 sec.\"",
          "sleep 10",
        "fi",
      "done",

      "scp -o StrictHostKeyChecking=no -q -i ~/.ssh/${basename(var.private_key_file)} hysdsops@${aws_instance.metrics.private_ip}:~/.creds ~/.creds_metrics",
      "echo TYPE: hysds > ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo MOZART_PVT_IP: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo MOZART_PUB_IP: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo MOZART_FQDN: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo MOZART_RABBIT_PVT_IP: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo MOZART_RABBIT_PUB_IP: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo MOZART_RABBIT_FQDN: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo MOZART_RABBIT_USER: $(awk 'NR==1{print $2; exit}' .creds) >> ~/.sds/config",
      "echo MOZART_RABBIT_PASSWORD: $(awk 'NR==1{print $3; exit}' .creds)>> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo MOZART_REDIS_PVT_IP: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo MOZART_REDIS_PUB_IP: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo MOZART_REDIS_FQDN: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo MOZART_REDIS_PASSWORD: $(awk 'NR==2{print $3; exit}' .creds) >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo MOZART_ES_PVT_IP: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo MOZART_ES_PUB_IP: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo MOZART_ES_FQDN: ${aws_instance.mozart.private_ip} >> ~/.sds/config",
      "echo OPS_USER: hysdsops >> ~/.sds/config",
      "echo OPS_HOME: $${HOME} >> ~/.sds/config",
      "echo OPS_PASSWORD_HASH: $(echo -n ${var.ops_password} | sha224sum |awk '{ print $1}') >> ~/.sds/config",
      "echo LDAP_GROUPS: opera-pcm-dev >> ~/.sds/config",
      "echo KEY_FILENAME: $${HOME}/.ssh/${basename(var.private_key_file)} >> ~/.sds/config",
      "echo JENKINS_USER: jenkins >> ~/.sds/config",
      "echo JENKINS_DIR: /var/lib/jenkins >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo METRICS_PVT_IP: ${aws_instance.metrics.private_ip} >> ~/.sds/config",
      "echo METRICS_PUB_IP: ${aws_instance.metrics.private_ip} >> ~/.sds/config",
      "echo METRICS_FQDN: ${aws_instance.metrics.private_ip} >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo METRICS_REDIS_PVT_IP: ${aws_instance.metrics.private_ip} >> ~/.sds/config",
      "echo METRICS_REDIS_PUB_IP: ${aws_instance.metrics.private_ip} >> ~/.sds/config",
      "echo METRICS_REDIS_FQDN: ${aws_instance.metrics.private_ip} >> ~/.sds/config",
      "echo METRICS_REDIS_PASSWORD: $(awk 'NR==1{print $3; exit}' .creds_metrics) >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo METRICS_ES_PVT_IP: ${aws_instance.metrics.private_ip} >> ~/.sds/config",
      "echo METRICS_ES_PUB_IP: ${aws_instance.metrics.private_ip} >> ~/.sds/config",
      "echo METRICS_ES_FQDN: ${aws_instance.metrics.private_ip} >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo GRQ_PVT_IP: ${aws_instance.grq.private_ip} >> ~/.sds/config",
      "echo GRQ_PUB_IP: ${aws_instance.grq.private_ip} >> ~/.sds/config",
      "echo GRQ_FQDN: ${aws_instance.grq.private_ip} >> ~/.sds/config",
      "echo GRQ_PORT: 8878 >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo GRQ_AWS_ES: ${var.grq_aws_es ? var.grq_aws_es : false} >> ~/.sds/config",
      "echo GRQ_ES_PROTOCOL: ${var.grq_aws_es ? "https" : "http"} >> ~/.sds/config",
      "echo GRQ_ES_PVT_IP: ${var.grq_aws_es ? var.grq_aws_es_host : aws_instance.grq.private_ip} >> ~/.sds/config",
      "echo GRQ_ES_PUB_IP: ${var.grq_aws_es ? var.grq_aws_es_host : aws_instance.grq.private_ip} >> ~/.sds/config",
      "echo GRQ_ES_FQDN: ${var.grq_aws_es ? var.grq_aws_es_host : aws_instance.grq.private_ip} >> ~/.sds/config",
      "echo GRQ_ES_PORT: ${var.grq_aws_es ? var.grq_aws_es_port : 9200} >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "if [ \"${var.grq_aws_es}\" = true ] && [ \"${var.use_grq_aws_es_private_verdi}\" = true ]; then",
      "  echo GRQ_AWS_ES_PRIVATE_VERDI: ${var.grq_aws_es_host_private_verdi} >> ~/.sds/config",
      "  echo GRQ_ES_PVT_IP_VERDI: ${var.grq_aws_es_host_private_verdi} >> ~/.sds/config",
      "  echo GRQ_ES_PUB_IP_VERDI: ${var.grq_aws_es_host_private_verdi} >> ~/.sds/config",
      "  echo GRQ_ES_FQDN_PVT_IP_VERDI: ${var.grq_aws_es_host_private_verdi} >> ~/.sds/config",
      "  echo ARTIFACTORY_REPO: ${var.artifactory_repo} >> ~/.sds/config",
      "  echo >> ~/.sds/config",
      "fi",

      "echo FACTOTUM_PVT_IP: ${aws_instance.factotum.private_ip} >> ~/.sds/config",
      "echo FACTOTUM_PUB_IP: ${aws_instance.factotum.private_ip} >> ~/.sds/config",
      "echo FACTOTUM_FQDN: ${aws_instance.factotum.private_ip} >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo CI_PVT_IP: ${var.common_ci["private_ip"]} >> ~/.sds/config",
      "echo CI_PUB_IP: ${var.common_ci["private_ip"]} >> ~/.sds/config",
      "echo CI_FQDN: ${var.common_ci["private_ip"]} >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo JENKINS_HOST: ${var.jenkins_host} >> ~/.sds/config",
      "echo JENKINS_ENABLED: ${var.jenkins_enabled} >> ~/.sds/config",
      "echo JENKINS_API_USER: ${var.jenkins_api_user != "" ? var.jenkins_api_user : var.venue} >> ~/.sds/config",
      "echo JENKINS_API_KEY: ${var.jenkins_api_key} >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo VERDI_PVT_IP: ${var.common_ci["private_ip"]} >> ~/.sds/config",
      "echo VERDI_PUB_IP: ${var.common_ci["private_ip"]} >> ~/.sds/config",
      "echo VERDI_FQDN: ${var.common_ci["private_ip"]} >> ~/.sds/config",
      "echo OTHER_VERDI_HOSTS: >> ~/.sds/config",
      "echo '  - VERDI_PVT_IP:' >> ~/.sds/config",
      "echo '    VERDI_PUB_IP:' >> ~/.sds/config",
      "echo '    VERDI_FQDN:' >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo DAV_SERVER: None >> ~/.sds/config",
      "echo DAV_USER: None >> ~/.sds/config",
      "echo DAV_PASSWORD: None >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo DATASET_AWS_REGION: us-west-2 >> ~/.sds/config",
      "echo DATASET_AWS_ACCESS_KEY: >> ~/.sds/config",
      "echo DATASET_AWS_SECRET_KEY: >> ~/.sds/config",
      "echo DATASET_S3_ENDPOINT: s3-us-west-2.amazonaws.com >> ~/.sds/config",
      "echo DATASET_S3_WEBSITE_ENDPOINT: s3-website-us-west-2.amazonaws.com >> ~/.sds/config",
      "echo DATASET_BUCKET: ${local.dataset_bucket} >> ~/.sds/config",
      "echo OSL_BUCKET: ${local.osl_bucket} >> ~/.sds/config",
      "echo TRIAGE_BUCKET: ${local.triage_bucket} >> ~/.sds/config",
      "echo LTS_BUCKET: ${local.lts_bucket} >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo AWS_REGION: us-west-2 >> ~/.sds/config",
      "echo AWS_ACCESS_KEY: >> ~/.sds/config",
      "echo AWS_SECRET_KEY: >> ~/.sds/config",
      "echo S3_ENDPOINT: s3-us-west-2.amazonaws.com >> ~/.sds/config",
      "echo CODE_BUCKET: ${local.code_bucket} >> ~/.sds/config",
      "echo VERDI_PRIMER_IMAGE: s3://${local.code_bucket}/hysds-verdi-${var.hysds_release}.tar.gz >> ~/.sds/config",
      "echo VERDI_TAG: ${var.hysds_release} >> ~/.sds/config",
      "echo VERDI_UID: 1002 >> ~/.sds/config",
      "echo VERDI_GID: 1002 >> ~/.sds/config",
      "echo VENUE: ${var.project}-${var.venue}-${local.counter} >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo ASG: >> ~/.sds/config",
      "echo '  AMI: ${var.amis["autoscale"]}' >> ~/.sds/config",
      "echo '  KEYPAIR: ${local.key_name}' >> ~/.sds/config",
      "echo '  USE_ROLE: ${var.asg_use_role}' >> ~/.sds/config",
      "echo '  ROLE: ${var.asg_role}' >> ~/.sds/config",
      "echo '  SECURITY_GROUPS:' >> ~/.sds/config",
      "echo '    - ${var.verdi_security_group_id}' >> ~/.sds/config",
      "echo '    - ${var.verdi_security_group_id}' >> ~/.sds/config",
      "echo '  VPC: ${var.asg_vpc}' >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo STAGING_AREA: >> ~/.sds/config",
      "echo '  LAMBDA_SECURITY_GROUPS:' >> ~/.sds/config",
      "echo '    - ${var.cluster_security_group_id}' >> ~/.sds/config",
      "echo '  LAMBDA_VPC: ${var.lambda_vpc}' >> ~/.sds/config",
      "echo '  LAMBDA_ROLE: \"${var.lambda_role_arn}\"' >> ~/.sds/config",
      "echo '  JOB_TYPE: ${var.lambda_job_type}' >> ~/.sds/config",
      "echo '  JOB_RELEASE: ${var.pcm_branch}' >> ~/.sds/config",
      "echo '  JOB_QUEUE: ${var.lambda_job_queue}' >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo CNM_RESPONSE_HANDLER: >> ~/.sds/config",
      "echo '  LAMBDA_SECURITY_GROUPS:' >> ~/.sds/config",
      "echo '    - ${var.cluster_security_group_id}' >> ~/.sds/config",
      "echo '  LAMBDA_VPC: ${var.lambda_vpc}' >> ~/.sds/config",
      "echo '  LAMBDA_ROLE: \"${var.lambda_role_arn}\"' >> ~/.sds/config",
      "echo '  JOB_TYPE: \"${var.cnm_r_handler_job_type}\"' >> ~/.sds/config",
      "echo '  JOB_RELEASE: ${var.product_delivery_branch}' >> ~/.sds/config",
      "echo '  JOB_QUEUE: ${var.cnm_r_job_queue}' >> ~/.sds/config",
      "echo '  EVENT_TRIGGER: ${var.cnm_r_event_trigger}' >> ~/.sds/config",
      "echo '  PRODUCT_TAG: true' >> ~/.sds/config",
      "echo '  ALLOWED_ACCOUNT: \"${var.cnm_r_allowed_account}\"' >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo GIT_OAUTH_TOKEN: ${var.git_auth_key} >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo PROVES_URL: https://prov-es.jpl.nasa.gov/beta >> ~/.sds/config",
      "echo PROVES_IMPORT_URL: https://prov-es.jpl.nasa.gov/beta/api/v0.1/prov_es/import/json >> ~/.sds/config",
      "echo DATASETS_CFG: $${HOME}/verdi/etc/datasets.json >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo SYSTEM_JOBS_QUEUE: system-jobs-queue >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo MOZART_ES_CLUSTER: resource_cluster >> ~/.sds/config",
      "echo METRICS_ES_CLUSTER: metrics_cluster >> ~/.sds/config",
      "echo DATASET_QUERY_INDEX: grq >> ~/.sds/config",
      "echo USER_RULES_DATASET_INDEX: user_rules >> ~/.sds/config",
      "echo EXTRACTOR_HOME: /home/ops/verdi/ops/opera-pcm/extractor >> ~/.sds/config",
      "echo CONTAINER_REGISTRY: localhost:5050 >> ~/.sds/config",
      "echo CONTAINER_REGISTRY_BUCKET: ${var.docker_registry_bucket} >> ~/.sds/config",
      "echo DAAC_PROXY: \"${var.daac_delivery_proxy}\" >> ~/.sds/config",
      "echo USE_S3_URI: \"${var.use_s3_uri_structure}\" >> ~/.sds/config",
      "if [ \"${local.daac_delivery_event_type}\" = \"sqs\" ]; then",
      "  echo DAAC_SQS_URL: \"https://sqs.${local.daac_delivery_region}.amazonaws.com/${local.daac_delivery_account}/${local.daac_delivery_resource_name}\" >> ~/.sds/config",
      "  echo DAAC_ENDPOINT_URL: \"${var.daac_endpoint_url}\" >> ~/.sds/config",
      "else",
      "  echo DAAC_SQS_URL: \"\" >> ~/.sds/config",
      "fi",
      "echo PCM_COMMONS_REPO: \"${var.pcm_commons_repo}\" >> ~/.sds/config",
      "echo PCM_COMMONS_BRANCH: \"${var.pcm_commons_branch}\" >> ~/.sds/config",
      "echo CRID: \"${var.crid}\" >> ~/.sds/config",
      "cat ~/q_config >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo INACTIVITY_THRESHOLD: ${var.inactivity_threshold} >> ~/.sds/config",
      "echo >> ~/.sds/config",

      "echo EARTHDATA_USER: ${var.earthdata_user} >> ~/.sds/config",
      "echo EARTHDATA_PASS: ${var.earthdata_pass} >> ~/.sds/config",
      "echo >> ~/.sds/config"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "mv ~/.sds ~/.sds.bak",
      "rm -rf ~/mozart",
      "if [ \"${var.hysds_release}\" = \"develop\" ]; then",
      "  git clone --single-branch -b ${var.hysds_release} https://${var.git_auth_key}@github.jpl.nasa.gov/IEMS-SDS/pcm-releaser.git",
      "  cd pcm-releaser",
      "  export release=${var.hysds_release}",
      "  export conda_dir=$HOME/conda",
      "  ./build_conda.sh $conda_dir $release",
      "  cd ..",
      "  rm -rf pcm-releaser",
      "  scp -o StrictHostKeyChecking=no -q -i ~/.ssh/${basename(var.private_key_file)} hysds-conda_env-${var.hysds_release}.tar.gz hysdsops@${aws_instance.metrics.private_ip}:hysds-conda_env-${var.hysds_release}.tar.gz",
      "  ssh -o StrictHostKeyChecking=no -q -i ~/.ssh/${basename(var.private_key_file)} hysdsops@${aws_instance.metrics.private_ip} 'mkdir -p ~/conda; tar xfz hysds-conda_env-${var.hysds_release}.tar.gz -C conda; export PATH=$HOME/conda/bin:$PATH; conda-unpack; rm -rf hysds-conda_env-${var.hysds_release}.tar.gz'",
      "  scp -o StrictHostKeyChecking=no -q -i ~/.ssh/${basename(var.private_key_file)} hysds-conda_env-${var.hysds_release}.tar.gz hysdsops@${aws_instance.grq.private_ip}:hysds-conda_env-${var.hysds_release}.tar.gz",
      "  ssh -o StrictHostKeyChecking=no -q -i ~/.ssh/${basename(var.private_key_file)} hysdsops@${aws_instance.grq.private_ip} 'mkdir -p ~/conda; tar xfz hysds-conda_env-${var.hysds_release}.tar.gz -C conda; export PATH=$HOME/conda/bin:$PATH; conda-unpack; rm -rf hysds-conda_env-${var.hysds_release}.tar.gz'",
      "  scp -o StrictHostKeyChecking=no -q -i ~/.ssh/${basename(var.private_key_file)} hysds-conda_env-${var.hysds_release}.tar.gz hysdsops@${aws_instance.factotum.private_ip}:hysds-conda_env-${var.hysds_release}.tar.gz",
      "  ssh -o StrictHostKeyChecking=no -q -i ~/.ssh/${basename(var.private_key_file)} hysdsops@${aws_instance.factotum.private_ip} 'mkdir -p ~/conda; tar xfz hysds-conda_env-${var.hysds_release}.tar.gz -C conda; export PATH=$HOME/conda/bin:$PATH; conda-unpack; rm -rf hysds-conda_env-${var.hysds_release}.tar.gz'",
      "  git clone https://github.com/hysds/hysds-framework",
      "  cd hysds-framework",
      "  git fetch",
      "  git fetch --tags",
      "  git checkout ${var.hysds_release}",
      "  ./install.sh mozart -d",
      "  rm -rf ~/mozart/pkgs/hysds-verdi-latest.tar.gz",
      "else",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/iems/sds/pcm/${var.hysds_release}/hysds-conda_env-${var.hysds_release}.tar.gz\"",
      "  mkdir -p ~/conda",
      "  tar xfz hysds-conda_env-${var.hysds_release}.tar.gz -C conda",
      "  export PATH=$HOME/conda/bin:$PATH",
      "  conda-unpack",
      "  rm -rf hysds-conda_env-${var.hysds_release}.tar.gz",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/iems/sds/pcm/${var.hysds_release}/hysds-mozart_venv-${var.hysds_release}.tar.gz\"",
      "  tar xfz hysds-mozart_venv-${var.hysds_release}.tar.gz",
      "  rm -rf hysds-mozart_venv-${var.hysds_release}.tar.gz",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/iems/sds/pcm/${var.hysds_release}/hysds-verdi_venv-${var.hysds_release}.tar.gz\"",
      "  tar xfz hysds-verdi_venv-${var.hysds_release}.tar.gz",
      "  rm -rf hysds-verdi_venv-${var.hysds_release}.tar.gz",
      "fi",
      "cd ~/mozart/ops",
      "if [ \"${var.use_artifactory}\" = true ]; then",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pcm/nisar-pcm-${var.pcm_branch}.tar.gz\"",
      "  tar xfz opera-pcm-${var.pcm_branch}.tar.gz",
      "  ln -s /export/home/hysdsops/mozart/ops/opera-pcm-${var.pcm_branch} /export/home/hysdsops/mozart/ops/opera-pcm",
      "  rm -rf opera-pcm-${var.pcm_branch}.tar.gz ",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pcm/CNM_product_delivery-${var.product_delivery_branch}.tar.gz\"",
      "  tar xfz CNM_product_delivery-${var.product_delivery_branch}.tar.gz",
      "  ln -s /export/home/hysdsops/mozart/ops/CNM_product_delivery-${var.product_delivery_branch} /export/home/hysdsops/mozart/ops/CNM_product_delivery",
      "  rm -rf CNM_product_delivery-${var.product_delivery_branch}.tar.gz",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pcm/pcm_commons-${var.pcm_commons_branch}.tar.gz\"",
      "  tar xfz pcm_commons-${var.pcm_commons_branch}.tar.gz",
      "  ln -s /export/home/hysdsops/mozart/ops/pcm_commons-${var.pcm_commons_branch} /export/home/hysdsops/mozart/ops/pcm_commons",
      "  rm -rf pcm_commons-${var.pcm_commons_branch}.tar.gz",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pcm/nisar-bach-api-${var.opera_bach_api_branch}.tar.gz\"",
      "  tar xfz nisar-bach-api-${var.opera_bach_api_branch}.tar.gz",
      "  ln -s /export/home/hysdsops/mozart/ops/nisar-bach-api-${var.opera_bach_api_branch} /export/home/hysdsops/mozart/ops/opera-bach-api",
      "  rm -rf nisar-bach-api-${var.opera_bach_api_branch}.tar.gz ",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pcm/nisar-bach-ui-${var.opera_bach_ui_branch}.tar.gz\"",
      "  tar xfz nisar-bach-ui-${var.opera_bach_ui_branch}.tar.gz",
      "  ln -s /export/home/hysdsops/mozart/ops/nisar-bach-ui-${var.opera_bach_ui_branch} /export/home/hysdsops/mozart/ops/opera-bach-ui",
      "  rm -rf nisar-bach-ui-${var.opera_bach_ui_branch}.tar.gz ",
      "else",
      "  git clone --single-branch -b ${var.pcm_branch} https://${var.git_auth_key}@${var.pcm_repo} opera-pcm",
      "  git clone --single-branch -b ${var.product_delivery_branch} https://${var.git_auth_key}@${var.product_delivery_repo}",
      "  git clone --single-branch -b ${var.pcm_commons_branch} https://${var.git_auth_key}@${var.pcm_commons_repo}",
      "  git clone --single-branch -b ${var.opera_bach_api_branch} https://${var.git_auth_key}@${var.opera_bach_api_repo}",
      "  git clone --single-branch -b ${var.opera_bach_ui_branch} https://${var.git_auth_key}@${var.opera_bach_ui_repo}",
      "fi",
      "export PATH=~/conda/bin:$PATH",
      "cp -rp opera-pcm/conf/sds ~/.sds",
      "cp ~/.sds.bak/config ~/.sds",
      "cd opera-bach-ui",
      "~/conda/bin/npm install --silent --no-progress",
      "sh create_config_simlink.sh ~/.sds/config ~/mozart/ops/opera-bach-ui",
      "~/conda/bin/npm run build --silent",
      "cd ../",
      "if [ \"${var.grq_aws_es}\" = true ]; then",
      "  cp -f ~/.sds/files/supervisord.conf.grq.aws_es ~/.sds/files/supervisord.conf.grq",
      "fi",
      "if [ \"${var.factotum["instance_type"]}\" = \"c5.xlarge\" ]; then",
      "  cp -f ~/.sds/files/supervisord.conf.factotum.small_instance ~/.sds/files/supervisord.conf.factotum",
      "elif [ \"${var.factotum["instance_type"]}\" = \"r5.8xlarge\" ]; then",
      "  cp -f ~/.sds/files/supervisord.conf.factotum.large_instance ~/.sds/files/supervisord.conf.factotum",
      "fi"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "source ~/.bash_profile",
      "if [ \"${var.hysds_release}\" = \"develop\" ]; then",
      "  sds -d update mozart -f",
      "  sds -d update grq -f",
      "  sds -d update metrics -f",
      "  sds -d update factotum -f",
      "else",
      "  sds -d update mozart -f -c",
      "  sds -d update grq -f -c",
      "  sds -d update metrics -f -c",
      "  sds -d update factotum -f -c",
      "fi",
      "echo buckets are ---- ${local.code_bucket} ${local.dataset_bucket} ${local.isl_bucket}",
      "if [ \"${var.use_artifactory}\" = true ]; then",
      "  fab -f ~/.sds/cluster.py -R mozart,grq,metrics,factotum update_opera_packages",
      "else",
      "  fab -f ~/.sds/cluster.py -R mozart,grq,metrics,factotum,verdi update_opera_packages",
      "fi",
      "if [ \"${var.grq_aws_es}\" = true ] && [ \"${var.use_grq_aws_es_private_verdi}\" = true ]; then",
      "  fab -f ~/.sds/cluster.py -R mozart update_celery_config",
      "fi",
      "fab -f ~/.sds/cluster.py -R grq update_es_template",
      "sds -d ship",
      "cd ~/mozart/pkgs",
      "sds -d pkg import container-hysds_lightweight-jobs-*.sdspkg.tar",
      "aws s3 cp hysds-verdi-${var.hysds_release}.tar.gz s3://${local.code_bucket}/ --no-progress",
      "aws s3 cp docker-registry-2.tar.gz s3://${local.code_bucket}/ --no-progress",
      "aws s3 cp logstash-7.9.3.tar.gz s3://${local.code_bucket}/ --no-progress",
      "sds -d reset all -f",
      "cd ~/mozart/ops/pcm_commons",
      "pip install --progress-bar off -e .",
      "cd ~/mozart/ops/opera-pcm",
      "pip install --progress-bar off -e .",
      "if [[ \"${var.pge_release}\" == \"develop\"* ]]; then",
      "    python ~/mozart/ops/opera-pcm/tools/deploy_pges.py --pge_release \"${var.pge_release}\" --image_names ${var.pge_names} --sds_config ~/.sds/config --processes 4 --force --artifactory_url ${local.pge_artifactory_dev_url}",
      "else",
      # TODO chrisjrd: remove
#      "    python ~/mozart/ops/opera-pcm/tools/deploy_pges.py --pge_release \"${var.pge_release}\" --image_names ${var.pge_names} --sds_config ~/.sds/config --processes 4 --force --artifactory_url ${local.pge_artifactory_release_url}",
      # TODO chrisjrd: extract vars as needed
      "    python ~/mozart/ops/opera-pcm/tools/deploy_pges.py \\",
      "    --image_names opera_pge-dswx_hls \\",
      "    --pge_release \"1.0.0-er.2.0\" \\",
      "    --sds_config ~/.sds/config \\",
      "    --processes 4 \\",
      "    --force \\",
      "    --artifactory_url https://artifactory-fn.jpl.nasa.gov/artifactory/general/gov/nasa/jpl/opera/sds/pge \\",
      "    --username ${var.artifactory_fn_user} \\",
      "    --api_key ${var.artifactory_fn_api_key}",
      "fi",
      "sds -d kibana import -f",
      "sds -d cloud storage ship_style --bucket ${local.dataset_bucket}",
      "sds -d cloud storage ship_style --bucket ${local.osl_bucket}",
      "sds -d cloud storage ship_style --bucket ${local.triage_bucket}",
      "sds -d cloud storage ship_style --bucket ${local.lts_bucket}",
      #"sds -d cloud asg create"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "source ~/.bash_profile",
      "wget ${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pge/testdata_R1.0.0/l0b_small_001.tgz!/input/id_06-00-0101_chirp-parameter_v44.12.xml -O /export/home/hysdsops/mozart/ops/opera-pcm/tests/pge/l0b/id_06-00-0101_chirp-parameter_v44.12.xml",
      "wget ${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pge/testdata_R1.0.0/l0b_small_001.tgz!/input/id_01-00-0101_radar-configuration_v44.12.xml -O /export/home/hysdsops/mozart/ops/opera-pcm/tests/pge/l0b/id_01-00-0101_radar-configuration_v44.12.xml",
      "wget ${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pge/testdata_R1.0.0/l0b_small_001.tgz!/input/id_ff-00-ff01_waveform.xml -O /export/home/hysdsops/mozart/ops/opera-pcm/tests/pge/l0b/id_ff-00-ff01_waveform.xml",
    ]
  }

  // creating the snapshot repositories and lifecycles for GRQ mozart and metrics ES
  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "source ~/.bash_profile",
      // grq
      "~/mozart/bin/snapshot_es_data.py --es-url ${local.grq_es_url} create-repository --repository snapshot-repository --bucket ${var.es_snapshot_bucket} --bucket-path ${var.project}-${var.venue}-${var.counter}/grq --role-arn ${var.es_bucket_role_arn}",
      "~/mozart/bin/snapshot_es_data.py --es-url ${local.grq_es_url} create-lifecycle --repository snapshot-repository --policy-id hourly-snapshot --snapshot grq-backup --index-pattern grq_*,*_catalog",

      // mozart
      "~/mozart/bin/snapshot_es_data.py --es-url http://${aws_instance.mozart.private_ip}:9200 create-repository --repository snapshot-repository --bucket ${var.es_snapshot_bucket} --bucket-path ${var.project}-${var.venue}-${var.counter}/mozart --role-arn ${var.es_bucket_role_arn}",
      "~/mozart/bin/snapshot_es_data.py --es-url http://${aws_instance.mozart.private_ip}:9200 create-lifecycle --repository snapshot-repository --policy-id hourly-snapshot --snapshot mozart-backup --index-pattern *_status-*,user_rules-*,job_specs,hysds_ios-*,containers",

      // metrics
      "~/mozart/bin/snapshot_es_data.py --es-url http://${aws_instance.metrics.private_ip}:9200 create-repository --repository snapshot-repository --bucket ${var.es_snapshot_bucket} --bucket-path ${var.project}-${var.venue}-${var.counter}/metrics --role-arn ${var.es_bucket_role_arn}",
      "~/mozart/bin/snapshot_es_data.py --es-url http://${aws_instance.metrics.private_ip}:9200 create-lifecycle --repository snapshot-repository --policy-id hourly-snapshot --snapshot metrics-backup --index-pattern logstash-*,sdswatch-*",
    ]
  }
}

resource "null_resource" "destroy_es_snapshots" {
  triggers = {
    private_key_file   = var.private_key_file
    mozart_pvt_ip      = aws_instance.mozart.private_ip
    grq_aws_es         = var.grq_aws_es
    purge_es_snapshot  = var.purge_es_snapshot
    project            = var.project
    venue              = var.venue
    counter            = var.counter
    es_snapshot_bucket = var.es_snapshot_bucket
    grq_es_url         = "${var.grq_aws_es ? "https" : "http"}://${var.grq_aws_es ? var.grq_aws_es_host : aws_instance.grq.private_ip}:${var.grq_aws_es ? var.grq_aws_es_port : 9200}"
  }

  connection {
    type        = "ssh"
    host        = self.triggers.mozart_pvt_ip
    user        = "hysdsops"
    private_key = file(self.triggers.private_key_file)
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "set -ex",
      "source ~/.bash_profile",
      "if [ \"${self.triggers.purge_es_snapshot}\" = true ]; then",
      "  aws s3 rm --recursive s3://${self.triggers.es_snapshot_bucket}/${self.triggers.project}-${self.triggers.venue}-${self.triggers.counter}",
      "  if [ \"${self.triggers.grq_aws_es}\" = true ]; then",
      "    ~/mozart/bin/snapshot_es_data.py --es-url ${self.triggers.grq_es_url} delete-lifecycle --policy-id hourly-snapshot",
      "    ~/mozart/bin/snapshot_es_data.py --es-url ${self.triggers.grq_es_url} delete-all-snapshots --repository snapshot-repository",
      "    ~/mozart/bin/snapshot_es_data.py --es-url ${self.triggers.grq_es_url} delete-repository --repository snapshot-repository",
      "  fi",
      "fi"
    ]
  }
}

locals {
  rs_fwd_lifecycle_configuration_json = jsonencode(
    {
      "Rules": [
        {
          "Expiration": {
            "Days": var.rs_fwd_bucket_ingested_expiration
          },
          "ID" : "RS Bucket Deletion",
          "Prefix": "products/",
          "Status" : "Enabled"
        }
      ]
    }
  )
}

resource "null_resource" "rs_fwd_add_lifecycle_rule" {
  depends_on = [local.rs_fwd_lifecycle_configuration_json, aws_instance.mozart]

  connection {
    type     = "ssh"
    host     = aws_instance.mozart.private_ip
    user     = "hysdsops"
    private_key = file(var.private_key_file)
  }

  # this makes it re-run every time
  triggers = {
    always_run = timestamp()
  }

  provisioner "remote-exec" {
    inline = ["aws s3api put-bucket-lifecycle-configuration --bucket ${local.dataset_bucket} --lifecycle-configuration '${local.rs_fwd_lifecycle_configuration_json}'"]
  }

}

############################
# Autoscaling Group related
############################

data "aws_subnet_ids" "asg_vpc" {
  vpc_id = var.asg_vpc
}

resource "aws_launch_template" "launch_template" {
  for_each               = var.queues
  name                   = "${var.project}-${var.venue}-${local.counter}-${each.key}-launch-template"
  image_id               = var.amis["autoscale"]
  key_name               = local.key_name
  user_data              = base64encode("BUNDLE_URL=s3://${local.code_bucket}/${each.key}-${var.project}-${var.venue}-${local.counter}.tbz2")
  vpc_security_group_ids = [var.verdi_security_group_id]

  tags = { Bravo = "pcm" }
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = lookup(each.value, "root_dev_size")
      delete_on_termination = true
    }
  }

  block_device_mappings {
    device_name = "/dev/sdf"
    ebs {
      volume_size = lookup(each.value, "data_dev_size")
      snapshot_id = data.aws_ebs_snapshot.docker_verdi_registry.id
    }
  }

  iam_instance_profile {
    name = var.asg_use_role ? var.asg_role : ""
  }
  tag_specifications {
    resource_type = "volume"

    tags = {
      Bravo = "pcm"
    }
  }
  #This is very important, as it tells terraform to not mess with tags
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  for_each                  = var.queues
  name                      = "${var.project}-${var.venue}-${local.counter}-${each.key}"
  depends_on                = [aws_launch_template.launch_template]
  max_size                  = lookup(each.value, "max_size")
  min_size                  = 0
  default_cooldown          = 60
  desired_capacity          = 0
  health_check_grace_period = 300
  health_check_type         = "EC2"
  protect_from_scale_in     = false
  vpc_zone_identifier       = data.aws_subnet_ids.asg_vpc.ids
  tags = [
    {
      key                 = "Name"
      value               = "${var.project}-${var.venue}-${local.counter}-${each.key}"
      propagate_at_launch = true
    },
    {
      key                 = "Venue"
      value               = "${var.project}-${var.venue}-${local.counter}"
      propagate_at_launch = true
    },
    {
      key                 = "Queue"
      value               = each.key
      propagate_at_launch = true
    },
    {
      key                 = "Bravo"
      value               = "pcm"
      propagate_at_launch = true
    },
  ]
  mixed_instances_policy {
    instances_distribution {
      spot_allocation_strategy                 = "lowest-price"
      spot_instance_pools                      = 3
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
    }

    launch_template {
      launch_template_specification {
        launch_template_name = "${var.project}-${var.venue}-${local.counter}-${each.key}-launch-template"
        version              = "$Latest"
      }

      dynamic "override" {
        for_each = toset(lookup(each.value, "instance_type"))
        content {
          instance_type = override.value
        }
      }
    }
  }
  #This is very important, as it tells terraform to not mess with tags
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_autoscaling_policy" "autoscaling_policy" {
  for_each               = var.queues
  name                   = "${var.project}-${var.venue}-${local.counter}-${each.key}-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = "${var.project}-${var.venue}-${local.counter}-${each.key}"
  depends_on             = [aws_autoscaling_group.autoscaling_group]
  target_tracking_configuration {
    customized_metric_specification {

      metric_dimension {
        name  = "AutoScalingGroupName"
        value = "${var.project}-${var.venue}-${local.counter}-${each.key}"
      }

      metric_dimension {
        name  = "Queue"
        value = each.key
      }
      metric_name = "JobsWaitingPerInstance-${var.project}-${var.venue}-${local.counter}-${each.key}"
      unit        = "None"
      namespace   = "HySDS"
      statistic   = "Maximum"
    }
    target_value     = 1.0
    disable_scale_in = true
  }

}


######################
# metrics
######################

resource "aws_instance" "metrics" {
  ami                  = var.amis["metrics"]
  instance_type        = var.metrics["instance_type"]
  key_name             = local.key_name
  availability_zone    = var.az
  iam_instance_profile = var.pcm_cluster_role["name"]
  private_ip           = var.metrics["private_ip"] != "" ? var.metrics["private_ip"] : null
  tags = {
    Name  = "${var.project}-${var.venue}-${local.counter}-pcm-${var.metrics["name"]}",
    Bravo = "pcm"
  }
  volume_tags = {
    Bravo = "pcm"
  }
  #This is very important, as it tells terraform to not mess with tags
  lifecycle {
    ignore_changes = [tags]
  }
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.cluster_security_group_id]

  connection {
    type        = "ssh"
    host        = aws_instance.metrics.private_ip
    user        = "hysdsops"
    private_key = file(var.private_key_file)
  }

  provisioner "local-exec" {
    command = "echo export METRICS_IP=${aws_instance.metrics.private_ip} > metrics_ip.sh"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/bash_profile.metrics.tmpl", {})
    destination = ".bash_profile"
  }

  provisioner "file" {
    source      = "${path.module}/../../../tools/download_artifact.sh"
    destination = "~/download_artifact.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 755 ~/download_artifact.sh",
      "if [ \"${var.hysds_release}\" != \"develop\" ]; then",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/iems/sds/pcm/${var.hysds_release}/hysds-conda_env-${var.hysds_release}.tar.gz\"",
      "  mkdir -p ~/conda",
      "  tar xfz hysds-conda_env-${var.hysds_release}.tar.gz -C conda",
      "  export PATH=$HOME/conda/bin:$PATH",
      "  conda-unpack",
      "  rm -rf hysds-conda_env-${var.hysds_release}.tar.gz",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/iems/sds/pcm/${var.hysds_release}/hysds-metrics_venv-${var.hysds_release}.tar.gz\"",
      "  tar xfz hysds-metrics_venv-${var.hysds_release}.tar.gz",
      "  rm -rf hysds-metrics_venv-${var.hysds_release}.tar.gz",
      "fi"
    ]
  }
}


######################
# grq
######################

resource "aws_instance" "grq" {
  ami                  = var.amis["grq"]
  instance_type        = var.grq["instance_type"]
  key_name             = local.key_name
  availability_zone    = var.az
  iam_instance_profile = var.pcm_cluster_role["name"]
  private_ip           = var.grq["private_ip"] != "" ? var.grq["private_ip"] : null
  tags = {
    Name  = "${var.project}-${var.venue}-${local.counter}-pcm-${var.grq["name"]}",
    Bravo = "pcm"
  }
  volume_tags = {
    Bravo = "pcm"
  }
  #This is very important, as it tells terraform to not mess with tags
  lifecycle {
    ignore_changes = [tags]
  }
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.cluster_security_group_id]

  connection {
    type        = "ssh"
    host        = aws_instance.grq.private_ip
    user        = "hysdsops"
    private_key = file(var.private_key_file)
  }


  provisioner "local-exec" {
    command = "echo export GRQ_IP=${aws_instance.grq.private_ip} > grq_ip.sh"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/bash_profile.grq.tmpl", {})
    destination = ".bash_profile"
  }

  provisioner "file" {
    source      = "${path.module}/../../../tools/download_artifact.sh"
    destination = "~/download_artifact.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 755 ~/download_artifact.sh",
      "if [ \"${var.hysds_release}\" != \"develop\" ]; then",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/iems/sds/pcm/${var.hysds_release}/hysds-conda_env-${var.hysds_release}.tar.gz\"",
      "  mkdir -p ~/conda",
      "  tar xfz hysds-conda_env-${var.hysds_release}.tar.gz -C conda",
      "  export PATH=$HOME/conda/bin:$PATH",
      "  conda-unpack",
      "  rm -rf hysds-conda_env-${var.hysds_release}.tar.gz",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/iems/sds/pcm/${var.hysds_release}/hysds-grq_venv-${var.hysds_release}.tar.gz\"",
      "  tar xfz hysds-grq_venv-${var.hysds_release}.tar.gz",
      "  rm -rf hysds-grq_venv-${var.hysds_release}.tar.gz",
      "fi",
      "if [ \"${var.use_artifactory}\" = true ]; then",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/nisar/sds/pcm/nisar-bach-api-${var.opera_bach_api_branch}.tar.gz\"",
      "  tar xfz nisar-bach-api-${var.opera_bach_api_branch}.tar.gz",
      "  ln -s /export/home/hysdsops/mozart/ops/nisar-bach-api-${var.opera_bach_api_branch} /export/home/hysdsops/mozart/ops/nisar-bach-api",
      "  rm -rf nisar-bach-api-${var.opera_bach_api_branch}.tar.gz ",
      "else",
      "  git clone --single-branch -b ${var.opera_bach_api_branch} https://${var.git_auth_key}@${var.opera_bach_api_repo}",
      "fi"
    ]
  }

}


######################
# factotum
######################

resource "aws_instance" "factotum" {
  ami                  = var.amis["factotum"]
  instance_type        = var.factotum["instance_type"]
  key_name             = local.key_name
  availability_zone    = var.az
  iam_instance_profile = var.pcm_cluster_role["name"]
  private_ip           = var.factotum["private_ip"] != "" ? var.factotum["private_ip"] : null
  tags = {
    Name  = "${var.project}-${var.venue}-${local.counter}-pcm-${var.factotum["name"]}",
    Bravo = "pcm"
  }
  volume_tags = {
    Bravo = "pcm"
  }
  #This is very important, as it tells terraform to not mess with tags
  lifecycle {
    ignore_changes = [tags]
  }
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.cluster_security_group_id]

  root_block_device {
    volume_size           = var.factotum["root_dev_size"]
    volume_type           = "gp2"
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = var.factotum["data_dev"]
    volume_size           = var.factotum["data_dev_size"]
    volume_type           = "gp2"
    delete_on_termination = true
  }

  connection {
    type        = "ssh"
    host        = aws_instance.factotum.private_ip
    user        = "hysdsops"
    private_key = file(var.private_key_file)
  }

  provisioner "local-exec" {
    command = "echo export FACTOTUM_IP=${aws_instance.factotum.private_ip} > factotum_ip.sh"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/bash_profile.verdi.tmpl", {})
    destination = ".bash_profile"
  }

  provisioner "file" {
    source      = "${path.module}/../../../tools/download_artifact.sh"
    destination = "~/download_artifact.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 755 ~/download_artifact.sh",
      "if [ \"${var.hysds_release}\" != \"develop\" ]; then",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/iems/sds/pcm/${var.hysds_release}/hysds-conda_env-${var.hysds_release}.tar.gz\"",
      "  mkdir -p ~/conda",
      "  tar xfz hysds-conda_env-${var.hysds_release}.tar.gz -C conda",
      "  export PATH=$HOME/conda/bin:$PATH",
      "  conda-unpack",
      "  rm -rf hysds-conda_env-${var.hysds_release}.tar.gz",
      "  ~/download_artifact.sh -m \"${var.artifactory_mirror_url}\" -b \"${var.artifactory_base_url}\" \"${var.artifactory_base_url}/${var.artifactory_repo}/gov/nasa/jpl/iems/sds/pcm/${var.hysds_release}/hysds-verdi_venv-${var.hysds_release}.tar.gz\"",
      "  tar xfz hysds-verdi_venv-${var.hysds_release}.tar.gz",
      "  rm -rf hysds-verdi_venv-${var.hysds_release}.tar.gz",
      "fi",
    ]
  }
}

resource "aws_lambda_function" "cnm_response_handler" {
  depends_on    = [null_resource.download_lambdas]
  filename      = "${var.lambda_cnm_r_handler_package_name}-${var.lambda_package_release}.zip"
  description   = "Lambda function to process CNM Response messages"
  function_name = "${var.project}-${var.venue}-${local.counter}-daac-cnm_response-handler"
  handler       = "lambda_function.lambda_handler"
  timeout       = 300
  role          = var.lambda_role_arn
  runtime       = "python3.7"
  vpc_config {
    security_group_ids = [var.cluster_security_group_id]
    subnet_ids         = data.aws_subnet_ids.lambda_vpc.ids
  }
  environment {
    variables = {
      "EVENT_TRIGGER" = var.cnm_r_event_trigger
      "JOB_TYPE"      = var.cnm_r_handler_job_type
      "JOB_RELEASE"   = var.product_delivery_branch
      "JOB_QUEUE"     = var.cnm_r_job_queue
      "MOZART_URL"    = "https://${aws_instance.mozart.private_ip}/mozart"
      "PRODUCT_TAG"   = "true"
    }
  }
}

resource "aws_cloudwatch_log_group" "cnm_response_handler" {
  name              = "/aws/lambda/${var.project}-${var.venue}-${local.counter}-daac-cnm_response-handler"
  retention_in_days = var.lambda_log_retention_in_days
}

resource "aws_sns_topic" "cnm_response" {
  count = local.sns_count
  name  = "${var.project}-${var.venue}-${local.counter}-daac-cnm-response"
}

resource "aws_sns_topic_policy" "cnm_response" {
  depends_on = [aws_sns_topic.cnm_response, data.aws_iam_policy_document.sns_topic_policy]
  count      = local.sns_count
  arn        = aws_sns_topic.cnm_response[count.index].arn
  policy     = data.aws_iam_policy_document.sns_topic_policy[count.index].json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  depends_on = [aws_sns_topic.cnm_response]
  count      = local.sns_count
  policy_id  = "__default_policy_ID"
  statement {
    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:Receive",
      "SNS:AddPermission",
      "SNS:Subscribe"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        var.aws_account_id
      ]
    }
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_sns_topic.cnm_response[count.index].arn
    ]
    sid = "__default_statement_ID"
  }
}

resource "aws_sns_topic_subscription" "lambda_cnm_r_handler_subscription" {
  depends_on = [aws_sns_topic.cnm_response, aws_lambda_function.cnm_response_handler]
  count      = local.sns_count
  topic_arn  = aws_sns_topic.cnm_response[count.index].arn
  protocol   = "lambda"
  endpoint   = aws_lambda_function.cnm_response_handler.arn
}

resource "aws_lambda_permission" "allow_sns_cnm_r" {
  count         = local.sns_count
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cnm_response_handler.function_name
  principal     = "sns.amazonaws.com"
  statement_id  = "ID-1"
  source_arn    = aws_sns_topic.cnm_response[count.index].arn
}

resource "aws_kinesis_stream" "cnm_response" {
  count       = local.kinesis_count
  name        = "${var.project}-${var.venue}-${local.counter}-daac-cnm-response"
  shard_count = 1
}

resource "aws_lambda_event_source_mapping" "kinesis_event_source_mapping" {
  depends_on        = [aws_kinesis_stream.cnm_response, aws_lambda_function.cnm_response_handler]
  count             = local.kinesis_count
  event_source_arn  = aws_kinesis_stream.cnm_response[count.index].arn
  function_name     = aws_lambda_function.cnm_response_handler.arn
  starting_position = "TRIM_HORIZON"
}

data "aws_ebs_snapshot" "docker_verdi_registry" {
  most_recent = true

  filter {
    name   = "tag:Verdi"
    values = [var.hysds_release]
  }
  filter {
    name   = "tag:Registry"
    values = ["2"]
  }
  filter {
    name   = "tag:Logstash"
    values = ["7.9.3"]
  }
}

resource "aws_lambda_function" "event-misfire_lambda" {
  depends_on    = [null_resource.download_lambdas]
  filename      = "${var.lambda_e-misfire_handler_package_name}-${var.lambda_package_release}.zip"
  description   = "Lambda function to process data from EVENT-MISFIRE bucket"
  function_name = "${var.project}-${var.venue}-${local.counter}-event-misfire-lambda"
  handler       = "lambda_function.lambda_handler"
  role          = var.lambda_role_arn
  runtime       = "python3.7"
  timeout       = 500
  vpc_config {
    security_group_ids = [var.cluster_security_group_id]
    subnet_ids         = data.aws_subnet_ids.lambda_vpc.ids
  }
  environment {
    variables = {
      "JOB_TYPE"                    = var.lambda_job_type
      "JOB_RELEASE"                 = var.pcm_branch
      "JOB_QUEUE"                   = var.lambda_job_queue
      "MOZART_ES_URL"               = "http://${aws_instance.mozart.private_ip}:9200"
      "DATASET_S3_ENDPOINT"         = "s3-us-west-2.amazonaws.com"
      "SIGNAL_FILE_BUCKET"          = local.isl_bucket
      "DELAY_THRESHOLD"             = var.event_misfire_delay_threshold_seconds
      "E_MISFIRE_METRIC_ALARM_NAME" = local.e_misfire_metric_alarm_name
    }
  }
}

resource "aws_cloudwatch_log_group" "event-misfire_lambda" {
  name              = "/aws/lambda/${var.project}-${var.venue}-${local.counter}-event-misfire-lambda"
  retention_in_days = var.lambda_log_retention_in_days
}

resource "aws_cloudwatch_event_rule" "event-misfire_lambda" {
  name                = "${aws_lambda_function.event-misfire_lambda.function_name}-Trigger"
  description         = "Cloudwatch event to trigger event misfire monitoring lambda"
  schedule_expression = var.event_misfire_trigger_frequency
}

resource "aws_cloudwatch_event_target" "event-misfire_lambda" {
  rule      = aws_cloudwatch_event_rule.event-misfire_lambda.name
  target_id = "Lambda"
  arn       = aws_lambda_function.event-misfire_lambda.arn
}

resource "aws_lambda_permission" "event-misfire_lambda" {
  statement_id  = aws_cloudwatch_event_rule.event-misfire_lambda.name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event-misfire_lambda.arn
  function_name = aws_lambda_function.event-misfire_lambda.function_name
}

# Resources to provision the L0A timer
# Lambda function to submit a job to check for expired LDF State Configs
resource "aws_lambda_function" "l0a_timer" {
  depends_on = [null_resource.download_lambdas]
  filename = "${var.lambda_timer_handler_package_name}-${var.lambda_package_release}.zip"
  description = "Lambda function to submit a job that checks for expired LDF State Configs"
  function_name = "${var.project}-${var.venue}-${local.counter}-l0a-timer"
  handler = "lambda_function.lambda_handler"
  role = var.lambda_role_arn
  runtime = "python3.7"
  vpc_config {
    security_group_ids = [var.cluster_security_group_id]
    subnet_ids = data.aws_subnet_ids.lambda_vpc.ids
  }
  timeout = 30
  environment {
    variables = {
      "MOZART_URL": "https://${aws_instance.mozart.private_ip}/mozart",
      #"JOB_QUEUE": "${var.project}-job_worker-timer",
      "JOB_QUEUE": "opera-job_worker-timer",
      "JOB_TYPE": local.timer_handler_job_type,
      "JOB_RELEASE": var.pcm_branch,
      "DATASET_TYPE": "ldf-state-config",
      "NOTIFY_ARN": aws_sns_topic.operator_notify.arn
    }
  }
}

resource "aws_cloudwatch_log_group" "l0a_timer" {
  depends_on = [aws_lambda_function.l0a_timer]
  name = "/aws/lambda/${aws_lambda_function.l0a_timer.function_name}"
  retention_in_days = var.lambda_log_retention_in_days
}

# Cloudwatch event that will trigger a Lambda that submits the LDF timer job
resource "aws_cloudwatch_event_rule" "l0a_timer" {
  name = "${aws_lambda_function.l0a_timer.function_name}-Trigger"
  description = "Cloudwatch event to trigger the L0A timer Lambda"
  schedule_expression = var.l0a_timer_trigger_frequency
  is_enabled = local.enable_timer
}

resource "aws_cloudwatch_event_target" "l0a_timer" {
  rule = aws_cloudwatch_event_rule.l0a_timer.name
  target_id = "Lambda"
  arn = aws_lambda_function.l0a_timer.arn
}

resource "aws_lambda_permission" "l0a_timer" {
  statement_id = aws_cloudwatch_event_rule.l0a_timer.name
  action = "lambda:InvokeFunction"
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.l0a_timer.arn
  function_name = aws_lambda_function.l0a_timer.function_name
}

# Resources to provision the Observation Accountability Report timer
# Lambda function to submit a job to create the Observation Accountability Report
resource "aws_lambda_function" "observation_accountability_report_timer" {
  depends_on = [null_resource.download_lambdas]
  filename = "${var.lambda_report_handler_package_name}-${var.lambda_package_release}.zip"
  description = "Lambda function to submit a job that will create an Accountability Report"
  function_name = "${var.project}-${var.venue}-${local.counter}-obs-acct-report-timer"
  handler = "lambda_function.lambda_handler"
  role = var.lambda_role_arn
  runtime = "python3.7"
  vpc_config {
    security_group_ids = [var.cluster_security_group_id]
    subnet_ids = data.aws_subnet_ids.lambda_vpc.ids
  }
  timeout = 30
  environment {
    variables = {
      "MOZART_URL": "https://${aws_instance.mozart.private_ip}/mozart",
      #"JOB_QUEUE": "${var.project}-job_worker-small",
      "JOB_QUEUE": "opera-job_worker-small",
      "JOB_TYPE": local.accountability_report_job_type,
      "JOB_RELEASE": var.pcm_branch,
      "REPORT_NAME": "ObservationAccountabilityReport",
      "REPORT_FORMAT": "xml",
      "OSL_BUCKET_NAME": local.osl_bucket,
      "OSL_STAGING_AREA": var.osl_report_staging_area,
      "USER_START_TIME": "",
      "USER_END_TIME": ""
    }
  }
}

resource "aws_cloudwatch_log_group" "observation_accountability_report_timer" {
  depends_on = [aws_lambda_function.observation_accountability_report_timer]
  name = "/aws/lambda/${aws_lambda_function.observation_accountability_report_timer.function_name}"
  retention_in_days = var.lambda_log_retention_in_days
}

# Cloudwatch event that will trigger a Lambda that submits the LDF timer job
resource "aws_cloudwatch_event_rule" "observation_accountability_report_timer" {
  name = "${aws_lambda_function.observation_accountability_report_timer.function_name}-Trigger"
  description = "Cloudwatch event to trigger the Observation Accountability Report Timer Lambda"
  schedule_expression = var.obs_acct_report_timer_trigger_frequency
  is_enabled = local.enable_timer
}

resource "aws_cloudwatch_event_target" "observation_accountability_report_timer" {
  rule = aws_cloudwatch_event_rule.observation_accountability_report_timer.name
  target_id = "Lambda"
  arn = aws_lambda_function.observation_accountability_report_timer.arn
}

resource "aws_lambda_permission" "observation_accountability_report_timer" {
  statement_id = aws_cloudwatch_event_rule.observation_accountability_report_timer.name
  action = "lambda:InvokeFunction"
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.observation_accountability_report_timer.arn
  function_name = aws_lambda_function.observation_accountability_report_timer.function_name
}

# Resources to provision the Data Subscriber timer
# Lambda function to submit a job to create the Data Subscriber
resource "aws_lambda_function" "data_subscriber_timer" {
  depends_on = [null_resource.download_lambdas]
  filename = "${var.lambda_report_handler_package_name}-${var.lambda_package_release}.zip"
  description = "Lambda function to submit a job that will create a Data Subscriber"
  function_name = "${var.project}-${var.venue}-${local.counter}-data-subscriber-timer"
  handler = "lambda_function.lambda_handler"
  role = var.lambda_role_arn
  runtime = "python3.7"
  vpc_config {
    security_group_ids = [var.cluster_security_group_id]
    subnet_ids = data.aws_subnet_ids.lambda_vpc.ids
  }
  timeout = 30
  environment {
    variables = {
      "MOZART_URL": "https://${aws_instance.mozart.private_ip}/mozart",
      "JOB_QUEUE": "factotum-job_worker-small",
      "JOB_TYPE": local.data_subscriber_job_type,
      "JOB_RELEASE": var.pcm_branch,
      "ISL_BUCKET_NAME": local.isl_bucket,
      "ISL_STAGING_AREA": var.isl_staging_area,
      "USER_START_TIME": "",
      "USER_END_TIME": ""
    }
  }
}

resource "aws_cloudwatch_log_group" "data_subscriber_timer" {
  depends_on = [aws_lambda_function.data_subscriber_timer]
  name = "/aws/lambda/${aws_lambda_function.data_subscriber_timer.function_name}"
  retention_in_days = var.lambda_log_retention_in_days
}

# Cloudwatch event that will trigger a Lambda that submits the Data Subscriber timer job
resource "aws_cloudwatch_event_rule" "data_subscriber_timer" {
  name = "${aws_lambda_function.data_subscriber_timer.function_name}-Trigger"
  description = "Cloudwatch event to trigger the Data Subscriber Timer Lambda"
  schedule_expression = var.data_subscriber_timer_trigger_frequency
  is_enabled = local.enable_timer
}

resource "aws_cloudwatch_event_target" "data_subscriber_timer" {
  rule = aws_cloudwatch_event_rule.data_subscriber_timer.name
  target_id = "Lambda"
  arn = aws_lambda_function.data_subscriber_timer.arn
}

resource "aws_lambda_permission" "data_subscriber_timer" {
  statement_id = aws_cloudwatch_event_rule.data_subscriber_timer.name
  action = "lambda:InvokeFunction"
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.data_subscriber_timer.arn
  function_name = aws_lambda_function.data_subscriber_timer.function_name
}
