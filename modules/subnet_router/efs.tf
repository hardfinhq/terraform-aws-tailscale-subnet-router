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

resource "aws_efs_file_system" "tailscale" {
  creation_token = local.name
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = local.name
  }
}

resource "aws_efs_access_point" "tailscale" {
  file_system_id = aws_efs_file_system.tailscale.id
  root_directory {
    path = "/var/lib/tailscale"
  }

  tags = {
    Name = "var-lib-tailscale"
  }
}

resource "aws_efs_mount_target" "primary" {
  for_each = toset(data.aws_subnets.primary.ids)

  file_system_id  = aws_efs_file_system.tailscale.id
  subnet_id       = each.key
  security_groups = var.security_group_ids
}
