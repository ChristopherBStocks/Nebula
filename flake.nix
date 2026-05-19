{
  description = "A collection of re-usable modules for NixOS, Darwin, and Home Manager.";

  # ── Inputs ────────────────────────────────────────────────────────────
  inputs = {
    # NixOS
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Darwin
    nixDarwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home-manager
    hm = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Utilities
    flakeParts.url = "github:hercules-ci/flake-parts";
  };

  # ── Outputs ───────────────────────────────────────────────────────────
  outputs = inputs:
    inputs.flakeParts.lib.mkFlake {inherit inputs;} {
      ## ── Systems ──────────────────────────────────────────────────────
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];

      ## ── Modules ──────────────────────────────────────────────────────
      imports = [
        ./lib
        ./modules
      ];

      ## ── Per-system ───────────────────────────────────────────────────
      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;

        #### ── Dev Shell(s) ─────────────────────────────────────────────
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [statix deadnix just git-cliff];
        };
      };
    };
}
