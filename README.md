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
  --tag tailscale-ecs-router:2022.07.14 \
  --file ./_docker/tailscale.Dockerfile \
  .

# Optionally override the tag for the base `tailscale/tailscale` image
docker build \
  --build-arg TAILSCALE_TAG=v1.25.84 \
  --tag tailscale-ecs-router:2022.07.14 \
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

[1]: https://tailscale.com/kb/1019/subnets/
[2]: https://docs.aws.amazon.com/AmazonECS/latest/userguide/what-is-fargate.html
[3]: https://hub.docker.com/r/tailscale/tailscale
[4]: https://tailscale.com/kb/1085/auth-keys/
[5]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html
[6]: https://tailscale.com/kb/1099/device-authorization/
