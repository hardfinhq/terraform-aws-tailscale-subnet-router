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

locals {
  tailscale_volume_name     = "var-lib-tailscale"
  tailscale_definition_path = abspath("${path.module}/container_definitions/tailscale.json")
  tailscale_container_json = templatefile(local.tailscale_definition_path, {
    hostname           = "${var.vpc}-tailscale"
    advertise_routes   = join(",", concat([data.aws_vpc.ecs.cidr_block], var.additional_routes))
    auth_key_secret_id = data.aws_secretsmanager_secret.tailscale_auth_key.id
    image_id           = "${data.aws_ecr_repository.tailscale.repository_url}@${data.aws_ecr_image.tailscale.id}"
    volume_name        = local.tailscale_volume_name
    logs_group         = aws_cloudwatch_log_group.tailscale.name
    logs_region        = local.aws_region_name
  })
}

resource "aws_ecs_task_definition" "tailscale" {
  family                   = "${var.vpc}-tailscale"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256" # 0.25 vCPU (256/1024)
  memory                   = "512" # 512 MiB == 0.5 GiB
  execution_role_arn       = aws_iam_role.ecs_task_execution_tailscale.arn
  task_role_arn            = aws_iam_role.ecs_task_tailscale.arn

  container_definitions = jsonencode([
    jsondecode(local.tailscale_container_json),
  ])

  volume {
    name = local.tailscale_volume_name

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.tailscale.id
      transit_encryption = "ENABLED"
    }
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }
}

data "aws_ecs_cluster" "target" {
  cluster_name = var.target_ecs_cluster
}

resource "aws_ecs_service" "tailscale" {
  name                   = "tailscale"
  cluster                = data.aws_ecs_cluster.target.id
  task_definition        = aws_ecs_task_definition.tailscale.arn
  desired_count          = 1
  wait_for_steady_state  = true
  launch_type            = "FARGATE"
  enable_execute_command = var.enable_execute_command

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    assign_public_ip = var.assign_public_ip
    security_groups  = var.security_group_ids
    subnets          = data.aws_subnets.primary.ids
  }
}
