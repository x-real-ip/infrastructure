# OpenTofu

Declarative configuration of the infrastructure. Every directory under
`stacks/` has its own state and is planned and applied on its own, so a change
in one stack can never touch the resources of another.

| Stack | Manages |
| ----- | ------- |
| `stacks/proxmox` | Proxmox cluster: cluster options, DNS, hosts, time zone, network bridges, SDN VLANs, APT repositories, storage, HA, replication, PCI mappings, pools and node certificates |

Configuration *inside* the machines (packages, files, services) stays in
Ansible.

## Requirements

- [OpenTofu](https://opentofu.org/docs/intro/install/) 1.10 or newer.
- The secrets below, stored in Bitwarden.

## Secrets

The state is committed to git and is always encrypted. Nothing secret is
stored in `.tf` or `.tfvars` files; everything comes from environment
variables.

| Variable | Contents |
| -------- | -------- |
| `TF_VAR_state_passphrase` | Passphrase for state encryption (at least 16 characters). Losing it means losing the state. |
| `PROXMOX_VE_API_TOKEN` | `tofu@pve!provider=<secret>` |

## Bootstrap the Proxmox API token

OpenTofu cannot create the token it authenticates with. The Ansible playbook
`proxmox_bootstrap.yaml` creates the user and token and prints the token once.
By hand, on one of the Proxmox nodes:

```sh
pveum user add tofu@pve --comment "OpenTofu"
pveum aclmod / -user tofu@pve -role Administrator
pveum user token add tofu@pve provider --privsep 0
```

Store `tofu@pve!provider=<value>` in Bitwarden. The value is shown only once.

## Node certificates

The web interface and API of every node use a certificate from the stamx CA.
The stack reads them from `~/certs/proxmox` (variable `certificate_dir`):
`<node>.crt`, `<node>.key` and `ca.crt`. How to create them is described in
[Create the node certificates](https://x-real-ip.github.io/documentation/hypervisor/#5-create-the-node-certificates).
The node private keys end up in the encrypted state.

## Usage

```sh
cd stacks/proxmox
export TF_VAR_state_passphrase='...'
export PROXMOX_VE_API_TOKEN='tofu@pve!provider=...'

tofu init
tofu plan
tofu apply
```

Commit `terraform.tfstate` and `.terraform.lock.hcl` after every apply.

## Adopting existing resources

To bring something that already exists under OpenTofu, add a temporary
`imports.tf` with an `import` block for it. The `tofu plan` must report only
imports and no changes. If it shows a change, align the code with reality
before applying. Remove `imports.tf` after the apply: an import block for a
resource that does not exist, for example a bridge on a freshly installed
node, makes the plan fail.
