# opencode NixOS Multi-Instance Module

NixOS module for running multiple isolated opencode server instances with virtual-host-style declarations.

## Import

Add ocnix as a flake input and import the module into your NixOS configuration:

```nix
# flake.nix
{
  inputs = {
    ocnix.url = "github:your-org/ocnix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    opencode.url = "github:sst/opencode";
  };

  outputs = { self, nixpkgs, ocnix, opencode, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        { nixpkgs.overlays = [ ocnix.overlays.default ]; }
        ocnix.nixosModules.opencode   # or nixosModules.default (alias)
        ./hosts/my-host.nix
      ];
      specialArgs = { inherit opencode; };
    };
  };
}
```

In your host config:

```nix
{ pkgs, opencode, ... }:
{
  services.opencode = {
    enable = true;
    instances.my-project = {
      directory = "/srv/my-project";
      listen.port = 8787;
      package = opencode.packages.${pkgs.system}.default;
    };
  };
}
```

## Basic Usage

```nix
# my-host-config.nix
{ pkgs, ... }:
{
  services.opencode = {
    enable = true;
    instances = {
      my-project = {
        directory = "/srv/my-project";
        listen.port = 8787;
      };
    };
  };
}
```

This generates:
- `systemd.services.opencode-my-project` - main service
- `systemd.services.opencode-my-project-setup` - idempotent setup
- A dedicated user `opencode-my-project` with state in `/var/lib/opencode/instance-state/my-project`

## Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | true | Enable this instance |
| `directory` | str | required | Project working directory |
| `stateDir` | str | `/var/lib/opencode/instance-state/<name>` | Runtime state (HOME) |
| `extraGroups` | [str] | [] | Supplementary groups for instance user |
| `listen.address` | str | `127.0.0.1` | Listen address |
| `listen.port` | port | `8080` | Listen port |
| `openFirewall` | bool | false | Open firewall for listen port |
| `environment` | attrs | {} | Environment variables |
| `environmentFile` | str | null | Path to secret env file |
| `path` | packages | [] | Extra packages in PATH |
| `logLevel` | enum | null | debug/info/warn/error |
| `model` | str | null | Model identifier |
| `provider` | str | null | Provider identifier |
| `extraArgs` | [str] | [] | Extra CLI arguments |
| `sandbox.readWritePaths` | [str] | [] | Extra read-write paths |
| `sandbox.readOnlyPaths` | [str] | [] | Extra read-only paths |
| `sandbox.unixSockets.allow` | [str] | [] | Unix socket paths to allow |
| `networkIsolation.enable` | bool | false | Enable outbound CIDR policy |
| `networkIsolation.outboundAllowCidrs` | [str] | [] | Allowed CIDR ranges |
| `preInitScript` | str | null | Script before setup steps |
| `postInitScript` | str | null | Script after setup steps |
| `config` | submodule | `{}` | Typed opencode.json config options (same as `nix/config/default.nix`) |
| `configFile` | path or null | `null` | Explicit path to opencode.json; overrides `config` when set |

## Secrets

Use `environmentFile` with sops-nix or similar:

```nix
instances.my-project = {
  directory = "/srv/my-project";
  environmentFile = "/run/secrets/opencode-my-project.env";
};
```

## Unix Socket Access (e.g. PostgreSQL)

```nix
instances.db-project = {
  directory = "/srv/db-project";
  sandbox.unixSockets.allow = [ "/run/postgresql/.s.PGSQL.5432" ];
};
```

## Network Isolation

```nix
instances.restricted = {
  directory = "/srv/restricted";
  networkIsolation = {
    enable = true;
    outboundAllowCidrs = [ "10.10.0.0/16" ];
  };
};
```

Requires nftables. Blocked attempts are logged (rate-limited) with prefix `opencode-<name>-blocked:`.

## Network Policy Troubleshooting

When `networkIsolation.enable = true`, blocked outbound connection attempts are logged to the system journal with the format:

```
opencode-<instance-name>-blocked: OUT=<iface> SRC=<src-ip> DST=<dst-ip> PROTO=TCP ...
```

### Inspect blocked attempts

View recent blocked attempts for a specific instance:

```bash
# All blocked attempts (all instances)
journalctl -k | grep 'opencode-.*-blocked'

# Specific instance
journalctl -k | grep 'opencode-my-project-blocked'

# Real-time monitoring
journalctl -kf | grep 'opencode-my-project-blocked'
```

### Identify the destination to allowlist

Each log entry contains `DST=<ip>`. Extract unique blocked destinations:

```bash
journalctl -k | grep 'opencode-my-project-blocked' \
  | grep -oP 'DST=\K[\d.]+' | sort -u
```

### Add a CIDR to the allowlist

Once you've identified required destinations, update your NixOS config:

```nix
services.opencode.instances.my-project = {
  networkIsolation = {
    enable = true;
    outboundAllowCidrs = [
      "10.10.0.0/16"    # internal APIs
      "34.120.0.0/14"   # newly discovered destination range
    ];
  };
};
```

Then rebuild and switch:

```bash
nixos-rebuild switch --flake .#my-host
```

### Rate limiting

Blocked attempt logging is rate-limited to **5 log entries per minute per instance** to avoid log spam. If an instance is generating many blocked attempts, the rate limiter will suppress some entries - tune the allowlist based on the sampled entries and re-verify.

### Check nftables policy is active

If a service with `networkIsolation.enable = true` fails to start, verify the nftables table is loaded:

```bash
# List the opencode egress table
nft list table inet opencode-egress

# If missing, check nftables service
systemctl status nftables.service
journalctl -u nftables.service
```

The opencode service requires its setup unit to complete before starting. If the nftables service fails or the egress table is not loaded, the service may start without intended network constraints - verify with `nft list table inet opencode-egress` after service startup.

### Compatibility note

`networkIsolation.enable = true` requires nftables (`networking.nftables.enable = true`). The opencode egress policy table (`inet opencode-egress`) coexists safely with the NixOS firewall (`networking.firewall.enable = true`) - both use nftables internally on NixOS 24.11+. You can use `openFirewall = true` and `networkIsolation.enable = true` together on the same instance.

## NixOS Tests

VM tests are in `nix/nixos/tests/`. Build with:

```
nix build .#nixosTests.postgres-socket
```

(Requires NixOS with KVM support.)
