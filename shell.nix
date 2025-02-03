{ pkgs ? import <nixpkgs> {} }:
let
  unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {};
in
pkgs.mkShell {
  packages = [ 
    pkgs.openssl
    pkgs.coreutils
    pkgs.git
    pkgs.jq
    unstable.packer
    pkgs.libisoburn
    pkgs.gomplate
    pkgs.python311
    pkgs.sops
    pkgs.awscli2
  ] ++ (if pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64 then [] else [ unstable.ovftool ]);

  shellHook = ''
    if [[ "$(uname -m)" == "arm64" && "$(uname -s)" == "Darwin" ]]; then
      echo "⚠️ 🛠️You will need to manually install the OVF Tool on your Apple Silicon Mac";
    fi
  '';
}

