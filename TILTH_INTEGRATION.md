# Tilth MCP Integration

This repository now includes [Tilth](https://github.com/jahala/tilth) as a flake input, providing tree-sitter-powered code navigation for OpenCode.

## What Changed

### 1. Flake Inputs
Added `tilth` as a flake input in `flake.nix`:

```nix
inputs.tilth.url = "github:jahala/tilth";
inputs.tilth.inputs.nixpkgs.follows = "nixpkgs";
```

### 2. Overlay
The `overlays.default` now provides `pkgs.tilth`:

```nix
overlays.default = final: prev: {
  lib = prev.lib // {
    opencode = mkLib final;
  };
  opencode = opencode.packages.${final.system}.default;
  tilth = tilth.packages.${final.system}.default;  # <-- Added
};
```

### 3. Config Generation
Updated `mkOpenCodeConfig` in `nix/config/lib.nix` to pass `pkgs` as a `specialArgs` so modules can reference packages:

```nix
evaluated = lib.evalModules {
  modules = [ moduleSystem ] ++ modules;
  specialArgs = { inherit pkgs; };  # <-- Added
};
```

### 4. Example Configurations
Updated `examples/chief-coding-assistant/mcp.nix` to use `pkgs.tilth`:

```nix
command = [
  (lib.getExe pkgs.tilth)  # Uses pkgs.tilth from overlay
  "--mcp"
];
```

## Usage

### For NixOS Services

```nix
{
  inputs.ocnix.url = "github:jmatsushita/ocnix";
  
  outputs = { self, nixpkgs, ocnix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ ocnix.overlays.default ];
        })
        ocnix.nixosModules.opencode
        {
          services.opencode.instances.my-project = {
            directory = "/srv/projects/my-project";
            
            # tilth is available via pkgs.tilth from the overlay
            # No need to add it to path - it's already in the config
            path = [ pkgs.git pkgs.ripgrep ];
            
            configFile = pkgs.lib.opencode.mkOpenCodeConfig [
              ocnix.nixosModules.example-chief-coding-assistant
            ];
          };
        }
      ];
    };
  };
}
```

### For Standalone Config Generation

```nix
{
  inputs.ocnix.url = "github:jmatsushita/ocnix";
  
  outputs = { self, nixpkgs, ocnix, ... }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ ocnix.overlays.default ];
    };
  in {
    packages.x86_64-linux.my-config = 
      pkgs.lib.opencode.mkOpenCodeConfig [
        ocnix.nixosModules.example-chief-coding-assistant
        # Your customizations
      ];
  };
}
```

### For Wrapped OpenCode Binary

```nix
{
  packages.x86_64-linux.my-opencode = 
    pkgs.lib.opencode.wrapOpenCode {
      name = "opencode";
      modules = [
        ocnix.nixosModules.example-chief-coding-assistant
      ];
    };
}
```

## Benefits

1. **Declarative**: Tilth is managed through Nix, ensuring reproducible builds
2. **No manual installation**: Users don't need to `cargo install tilth` separately
3. **Version pinning**: The tilth version is locked in `flake.lock`
4. **Automatic updates**: Update tilth with `nix flake update tilth`

## Alternative: Manual Installation

If you prefer to install tilth manually (outside of Nix), you can:

1. Install via cargo: `cargo install tilth`
2. Or via npm: `npx tilth`
3. Or via Nix profile: `nix profile install github:jahala/tilth`

Then configure MCP to use the system `tilth` instead of `pkgs.tilth`:

```nix
{
  opencode.mcp.tilth = {
    type = "local";
    command = [ "tilth" "--mcp" ];  # Uses system PATH
    enabled = true;
    timeout = 30000;
  };
}
```
