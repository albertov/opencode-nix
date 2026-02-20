# opencode-nix

Nix module system for generating [opencode](https://github.com/sst/opencode) config files (`opencode.json`).

## Quick Start

```nix
# flake.nix
{
  inputs = {
    opencode-nix.url = "github:your-org/opencode-nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, opencode-nix }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      myConfig = opencode-nix.lib.mkOpenCodeConfig [
        { theme = "catppuccin"; logLevel = "info"; }
        { agent.plan.steps = 50; }
      ];
    in {
      # Build your config
      packages.default = myConfig;
    };
}
```

## Functions

### `lib.mkOpenCodeConfig modules`

Takes a list of Nix modules and produces a derivation containing `opencode.json`.

### `lib.wrapOpenCode { name, modules, opencode }`

Produces a wrapped opencode binary with the config pre-baked via `OPENCODE_CONFIG`.

## Options

All `opencode.json` fields are available as typed Nix options. See `nix/config/options/` for full documentation.

## CI

[![Check](https://github.com/your-org/opencode-nix/actions/workflows/check.yml/badge.svg)](https://github.com/your-org/opencode-nix/actions/workflows/check.yml)
