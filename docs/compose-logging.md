# Docker Compose logging — Jenkins service

Forward Jenkins logs to your central sink using Docker’s logging drivers or host journald integration.

## Example: JSON file limits

```yaml
services:
  jenkins:
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "5"
```

Apply edits under `/opt/lucy-infra/jenkins/docker-compose.yml` on the VPS after rsync from Git; redeploy with `docker compose up -d`.

## Example: syslog forwarder

Use `syslog` driver if your VPN syslog collector accepts TCP/TLS from the VPS host.

Avoid exposing Jenkins logs containing credential IDs or SCM URLs to untrusted aggregators without scrubbing policies.
