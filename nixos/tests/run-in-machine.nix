{ pkgs, nixpkgsFolder, system ? builtins.currentSystem, ... }:

with import "${nixpkgsFolder}/lib/testing/testing.nix" { inherit system; };

runInMachine {
  drv = pkgs.hello;
  machine = { config, pkgs, ... }: { /* services.sshd.enable = true; */ };
}
