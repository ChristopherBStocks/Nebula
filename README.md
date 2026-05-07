# Nebula
[LICENSE](./LICENSE.md) | [CONTRIBUTING](./CONTRIBUTING.md)

> A collection of re-usable modules for NixOS, Darwin, and Home Manager.

## Prerequisites

**NixOS >= 25.11** or **Nix** package manager with flakes enabled.

## Installation

Add Nebula as a flake input:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  ...
  nebula.url = "github:christopherbstocks/nebula";
  nebula.inputs.nixpkgs.follows = "nixpkgs";
  ...
};
```

### Usage

```nix
outputs = { nixpkgs, nebula, ... }: {
  nixosConfigurations.host = nixpkgs.lib.nixosSystem {
    ...
    specialArgs = { inherit nebula; };
    ...
  };
};
```

```nix
{ nebula, ... }: {
  imports = with nebula.nixosModules; [ ... ];
  ...
}
```