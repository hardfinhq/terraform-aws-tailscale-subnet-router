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

variable "vpc" {
  type        = string
  description = "The name of the VPC where the subnet router ECS service will be launched"
}

variable "subnet_group" {
  type        = string
  description = "The group (tag) of the VPC subnets where the subnet router ECS service will be launched"
}

variable "assign_public_ip" {
  type        = bool
  description = "The 'assign_public_ip' flag for the ECS task network configuration"
}

variable "security_group_ids" {
  type        = list(string)
  description = "The security group IDs to associate with the subnet router ECS service and EFS mount targets"
}

variable "target_ecs_cluster" {
  type        = string
  description = "The name of the target ECS cluster"
}

variable "tailscale_auth_key_secret" {
  type        = string
  description = "The name of secret where the Tailscale auth key is stored"
}

variable "tailscale_docker_repository" {
  type        = string
  description = "The name of ECR repository where the Docker image stored"
}

variable "tailscale_docker_tag" {
  type        = string
  description = "The name of tag for the Docker image stored in ECR"
}

variable "enable_execute_command" {
  type        = bool
  description = "Allows AWS ECS exec into the task containers"
}

variable "additional_routes" {
  type        = list(string)
  default     = []
  description = "A list of additional CIDR blocks to pass to Tailscale as routes to advertise"
}

variable "cpu_architecture" {
  type        = string
  default     = "X86_64"
  description = "The CPU architecture to use for the container. Either X86_64 or ARM64."
}

variable "additional_flags" {
  type        = string
  default     = ""
  description = "Additional flags to pass to the tailscale up command"
}
variable "cpu" {
  type        = string
  default     = "256"
  description = "The CPU value to assign to the container (vCPU)"
}
variable "memory" {
  type        = string
  default     = "512"
  description = "The memory value to assign to the container (MiB)"
}