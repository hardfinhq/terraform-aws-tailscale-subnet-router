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

module "subnet_router" {
  source = "./modules/subnet_router"

  name                        = var.name
  vpc                         = var.vpc
  subnet_group                = var.subnet_group
  assign_public_ip            = var.assign_public_ip
  security_group_ids          = var.security_group_ids
  target_ecs_cluster          = var.target_ecs_cluster
  tailscale_auth_key_secret   = var.tailscale_auth_key_secret
  tailscale_docker_repository = var.tailscale_docker_repository
  tailscale_docker_tag        = var.tailscale_docker_tag
  enable_execute_command      = var.enable_execute_command
  additional_routes           = var.additional_routes
  cpu_architecture            = var.cpu_architecture
  additional_flags            = var.additional_flags
  cpu                         = var.cpu
  memory                      = var.memory
}
