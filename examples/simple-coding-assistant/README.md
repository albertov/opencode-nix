# Example: Simple Coding Assistant (NixOS Module)

This example shows a minimal **headless coding assistant** using the NixOS
service module pattern: `services.opencode.instances.<name>`.

It includes:

- 1 instance (`my-project`)
- 4 subagents (`general`, `explorer`, `implementer`, `reviewer`)
- 2 skill prompt patterns (inline and file-based)

For a more complete and production-oriented setup, see
`examples/chief-coding-assistant/`.

## Prerequisites

- A NixOS host
- This flake's `overlays.default` applied so `pkgs.opencode` exists
- `nixosModules.opencode` imported in your NixOS config
- API credentials provided via a runtime secrets file
  (`environmentFile`), not inline in Nix

## Import and Use

You can import this example module directly in your NixOS configuration.

### `configuration.nix` style

```nix
{ inputs, pkgs, ... }:

{
  imports = [
    inputs.ocnix.nixosModules.opencode
    inputs.ocnix.examples.simple-coding-assistant
  ];
}
```

### Flake NixOS config style

```nix
{
  outputs = { self, nixpkgs, ocnix, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ocnix.nixosModules.opencode
        ocnix.examples.simple-coding-assistant
      ];
    };
  };
}
```

## Minimal Configuration Snippet

The core service declaration used by this example:

```nix
services.opencode.instances.my-project = {
  directory = "/srv/projects/my-project";
  listen.port = 8787;
  environment.OPENCODE_LOG_LEVEL = "info";
  environmentFile = "/run/secrets/opencode-my-project";
  path = [ pkgs.git pkgs.ripgrep ];
  opencodeCfg = [
    ./agents.nix
    ./permissions.nix
    ./skills
  ];
};
```

## Subagent Roles

- `general`: research, planning, and coordination across multi-step tasks
- `explorer`: read-only codebase reconnaissance (files, symbols, structure)
- `implementer`: code changes with TDD-first workflow
- `reviewer`: correctness/security/type-safety review without editing

## Skills: Inline vs File-Based

This example demonstrates both patterns:

- **Inline** (`commit`): good for short, self-contained prompts maintained
  near configuration.
- **File-based** (`code-review`): good for longer prompts that need dedicated
  docs and independent maintenance.

## Service Operations

Check service status:

```bash
systemctl status opencode-my-project
```

Follow logs:

```bash
journalctl -u opencode-my-project -f
```

## Reference

For a richer multi-provider, multi-agent setup with stricter production
hardening, see `examples/chief-coding-assistant/README.md`.
