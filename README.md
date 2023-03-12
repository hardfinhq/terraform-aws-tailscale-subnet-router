# Terraform module for Tailscale subnet router in ECS Fargate

This module deploys a Tailscale [subnet router][1] as an [AWS Fargate][2]
ECS task. The subnet router runs within an AWS VPC and advertises (to the
Tailnet) the entire CIDR block for that VPC.

## Docker Container

The `_docker/tailscale.Dockerfile` file extends the `tailscale/tailscale`
[image][3] with an entrypoint script that starts the Tailscale daemon and runs
`tailscale up` using an [auth key][4] and the relevant advertised CIDR block.

This Docker container must be built and [pushed][5] to an ECR repository.

```bash
docker build \
  --tag tailscale-subnet-router:v1.20230311.1 \
  --file ./_docker/tailscale.Dockerfile \
  .

# Optionally override the tag for the base `tailscale/tailscale` image
docker build \
  --build-arg TAILSCALE_TAG=v1.36.2 \
  --tag tailscale-subnet-router:v1.20230311.1 \
  --file ./_docker/tailscale.Dockerfile \
  .
```

## Operator's Notes

- The Tailscale state (`/var/lib/tailscale`) is stored in an EFS disk so that
  the subnet router only needs to be [authorized][6] once.
- When deploying a new version, ECS will do a rolling update so two ECS tasks
  will be simultaneously claiming to be the same host. This conflict will
  eventually resolve itself some time after the older task exits, but may be
  confusing during the rollout.

## Room for Improvement

### Throughput

Right now this explicitly maps exactly one subnet router per VPC. As an
organization grows, this can cause the subnet router to get saturated and cause
a bottleneck. One of the perks of a mesh VPN is that bottlenecks via a
centralized controller aren't possible, so reintroducing a bottleneck is
unfortunate.

The best way to avoid this bottleneck is to not use a subnet router at all, but
many engineering organizations can't (or don't want to) run Tailscale as a
sidecar for all workloads. Assuming a subnet router will be used, there are a
few ways bottlenecks can be mitigated:

- Use smaller VPCs and utilize VPC peering as needed.
- Use multiple subnet routers to cover one VPC. To enable this we could allow
  the CIDR range covered by the subnet router (via `--advertise-routes`) to be
  configurable.
- Use [subnet router failover][7] for business users.
- Use the subnet router **only** as a way to access jump / bastion hosts (with
  access limited via Tailscale [network ACLs][8]) and then rely on scaling
  jump hosts to increase throughput.

### State

In the current form, this module uses AWS EFS to persist the Tailscale state in
`/var/lib/tailscale` across deploys.

```bash
tailscaled --state arn:aws:ssm:zz-minotaur-7:123456789012:parameter/sandbox-tailscale
```

### VPC

This module assumes a VPC `Name` is used, equivalent to:

```hcl
data "aws_vpc" "sandbox" {
  tags = {
    Name = "sandbox"
  }
}
```

We'd be open to accepting a `vpc_id` directly.

### Subnet group

The `subnet_group` variable is of note; it is used to filter subnets tagged
with `group={subnet_group}`. This is a convention we use at Hardfin to group
together subnets that are part of the same VPC (usually one subnet per AZ).
In Terraform, this is determined via:

```hcl
data "aws_subnets" "primary" {
  filter {
    name   = "vpc-id"
    values = ["vpc-51edfd86d3223cdff"]
  }
  tags = {
    group = "sandbox-igw-zz-minotaur-7"
  }
}
```

We'd be open to accepting an `aws_subnet_ids` list directly.

[1]: https://tailscale.com/kb/1019/subnets/
[2]: https://docs.aws.amazon.com/AmazonECS/latest/userguide/what-is-fargate.html
[3]: https://hub.docker.com/r/tailscale/tailscale
[4]: https://tailscale.com/kb/1085/auth-keys/
[5]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html
[6]: https://tailscale.com/kb/1099/device-authorization/
[7]: https://tailscale.com/kb/1115/subnet-failover/
[8]: https://tailscale.com/kb/1018/acls/
