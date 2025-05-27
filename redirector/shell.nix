{pkgs ? import <nixpkgs> {}}:
with pkgs;
  pkgs.mkShell {
    buildInputs = [
		nodejs_24
    ];
  }

