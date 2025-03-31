{ pkgs, lib, config, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };
in

{
  packages = [
    unstable.argocd
    unstable.just
    unstable.kind
    unstable.kubectl
    unstable.kubernetes-helm
    unstable.updatecli
  ];

  dotenv.disableHint = true; # we load this from .envrc
}
