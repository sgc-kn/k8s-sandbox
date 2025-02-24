{ pkgs, lib, config, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };
in

{
  packages = [
    unstable.argocd
    unstable.just
    unstable.kubectl
  ];
}
