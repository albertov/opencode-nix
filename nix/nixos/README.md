# opencode NixOS Multi-Instance Module

NixOS module for running multiple isolated opencode server instances with virtual-host-style declarations.

## Import

```nix
# flake.nix
{
  inputs.ocnix.url = "github:your-org/ocnix";
  outputs = { self, ocnix, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      modules = [
        ocnix.nixosModules.opencode
        ./my-host-config.nix
      ];
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
| `opencodeCfg` | [modules] | [] | opencode.json config modules |

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

## NixOS Tests

VM tests are in `nix/nixos/tests/`. Build with:

```
nix build .#nixosTests.postgres-socket
```

(Requires NixOS with KVM support.)
