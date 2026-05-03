# OVH Public Cloud — Nova power lifecycle (existing instance)

This stack **does not create or destroy** servers. It runs `openstack server stop|start` via a `terraform_data` provisioner when triggers change.

## Requirements

- `openstack` CLI and valid `clouds.yaml` (use `OS_CLIENT_CONFIG_FILE` pointing at that file).
- `OS_CLOUD` is set from variable `cloud_name` (matches the cloud entry name inside `clouds.yaml`).
- **Production:** configure a **remote backend with locking** — copy `backend.tf.example` and fill in your object storage; never rely only on ephemeral Jenkins workspace state.

## Nova semantics

`stopped` maps to **Nova stop** (not shelved). For billing/suspend semantics that require **shelve**, extend the provisioner or switch to an OpenStack Terraform resource that matches your operational requirement.

## Variables

See `variables.tf`: `server_id` (UUID), `cloud_name`, `desired_power` (`running` | `stopped`).

## State import

This module owns only a `terraform_data` resource (`nova_power`). There is **no** OpenStack provider resource to import for the VM itself—lifecycle is delegated to the OpenStack CLI in the provisioner. If you later split instance metadata into managed resources, document an explicit `terraform import` procedure alongside remote state.

## Lifecycle guard

`terraform_data.nova_power` sets **`lifecycle { prevent_destroy = true }`** so `terraform destroy` does not silently drop the automation hook; remove only during intentional module retirement.

## Plan artifacts (Jenkins)

The Isaac Sim pipeline archives **`tf-plan.txt`** (human-readable) and **`tfplan`** (binary) before a gated `terraform apply`. Production must use a **remote backend with locking**; inject `-backend-config` via CI/CD secrets or mounted files—not Git.
