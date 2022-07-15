# Copyright 2022 Hardfin, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

##################################################
############### ECS Task Execution ###############
##################################################

# This role will be the one used by the AWS Fargate agent(s) to make AWS
# API calls, e.g. to authenticate with ECR when pulling container images
# or to pull secrets from AWS Secrets Manager to inject into the task
# environment variables. See:
# - https://docs.aws.amazon.com/AmazonECS/latest/userguide/task_execution_IAM_role.html
resource "aws_iam_role" "ecs_task_execution_tailscale" {
  name               = "ecs-task-execution-${var.vpc}-tailscale"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_tailscale" {
  role       = aws_iam_role.ecs_task_execution_tailscale.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# See: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/specifying-sensitive-data-tutorial.html
data "aws_iam_policy_document" "ecs_task_secrets_tailscale" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      data.aws_secretsmanager_secret.tailscale_auth_key.arn,
    ]
  }
}

resource "aws_iam_policy" "ecs_task_secrets_tailscale" {
  name        = "ecs-task-secrets-${var.vpc}-tailscale"
  description = "Permissions for ECS task execution to read secrets for Tailscale in VPC ${var.vpc}"
  policy      = data.aws_iam_policy_document.ecs_task_secrets_tailscale.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_secrets_tailscale" {
  role       = aws_iam_role.ecs_task_execution_tailscale.name
  policy_arn = aws_iam_policy.ecs_task_secrets_tailscale.arn
}

##################################################
#################### ECS Task ####################
##################################################

# This role will be the one actually used by the running ECS task; i.e.
# when the task authenticates with the AWS credential endpoint, this is
# the role it will authenticate with. See:
# - https://docs.aws.amazon.com/AmazonECS/latest/userguide/task-iam-roles.html
resource "aws_iam_role" "ecs_task_tailscale" {
  name               = "ecs-task-${var.vpc}-tailscale"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

# See: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html
data "aws_iam_policy_document" "ecs_task_logs_tailscale" {
  statement {
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = [
      aws_cloudwatch_log_group.tailscale.arn,
    ]
  }
}

resource "aws_iam_policy" "ecs_task_logs_tailscale" {
  name        = "ecs-task-logs-${var.vpc}-tailscale"
  description = "Permissions for ECS task to write logs for Tailscale in VPC ${var.vpc}"
  policy      = data.aws_iam_policy_document.ecs_task_logs_tailscale.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_logs_tailscale" {
  role       = aws_iam_role.ecs_task_tailscale.name
  policy_arn = aws_iam_policy.ecs_task_logs_tailscale.arn
}
