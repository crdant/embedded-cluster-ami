{ pkgs ? import <nixpkgs> {} }:
let
  unstable =  import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {};
in
pkgs.mkShell {
  packages = [ 
    pkgs.openssl
    pkgs.coreutils
    pkgs.git
    pkgs.jq
    unstable.packer
    pkgs.ansible
    pkgs.terraform
    pkgs.libisoburn
    pkgs.gomplate
    unstable.ovftool
    pkgs.powershell
    pkgs.python311  # Ensure a specific Python version
    pkgs.python311Packages.lxml  # For XML handling
    pkgs.sops
    pkgs.awscli2
  ];
}

