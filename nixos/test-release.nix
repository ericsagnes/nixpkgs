{ nixpkgs ? { outPath = ./..; revCount = 56789; shortRev = "gfedcba"; }
, stableBranch ? false
, supportedSystems ? [ "x86_64-linux" "i686-linux" ]
}:

with {
  inherit (import ../lib/testing { inherit supportedSystems; }) callTest;
} // (import ../lib);

let

  version = fileContents ../.version;
  versionSuffix =
    (if stableBranch then "." else "pre") + "${toString nixpkgs.revCount}.${nixpkgs.shortRev}";

  forAllSystems = genAttrs supportedSystems;

  importTest = fn: args: system: import fn ({
    inherit system;
  } // args);

  pkgs = import nixpkgs { system = "x86_64-linux"; };

  versionModule =
    { system.nixosVersionSuffix = versionSuffix;
      system.nixosRevision = nixpkgs.rev or nixpkgs.shortRev;
    };


  makeIso =
    { module, type, maintainers ? ["eelco"], system }:

    with import nixpkgs { inherit system; };

    hydraJob ((import lib/eval-config.nix {
      inherit system;
      modules = [ module versionModule { isoImage.isoBaseName = "nixos-${type}"; } ];
    }).config.system.build.isoImage);


  makeSystemTarball =
    { module, maintainers ? ["viric"], system }:

    with import nixpkgs { inherit system; };

    let

      config = (import lib/eval-config.nix {
        inherit system;
        modules = [ module versionModule ];
      }).config;

      tarball = config.system.build.tarball;

    in
      tarball //
        { meta = {
            description = "NixOS system tarball for ${system} - ${stdenv.platform.name}";
            maintainers = map (x: lib.maintainers.${x}) maintainers;
          };
          inherit config;
        };


  makeClosure = module: buildFromConfig module (config: config.system.build.toplevel);


  buildFromConfig = module: sel: forAllSystems (system: hydraJob (sel (import ./lib/eval-config.nix {
    inherit system;
    modules = [ module versionModule ] ++ singleton
      ({ config, lib, ... }:
      { fileSystems."/".device  = mkDefault "/dev/sda1";
        boot.loader.grub.device = mkDefault "/dev/sda";
      });
  }).config));

  # list of blacklisted module tests that shouldn't end in `tests.module`
  # example: blacklistedModuleTests = [ "panamax" ];
  blacklistedModuleTests = [ ];

  # Gather tests declared in modules meta.tests
  # args is a set of { "testName" = { extra args }; } to override test arguments, typically systems
  moduleTests = args:
    let tests = (import lib/eval-config.nix { modules = []; }).config.meta.tests;
        filteredTests = filterAttrs (k: _: !(elem k blacklistedModuleTests)) tests;
        args' = k: attrByPath [k] {} args;
    in mapAttrs (k: v: callTest (head v).value (args' k)) filteredTests;

in rec {

  # Run the tests for each platform.  You can run a test by doing
  # e.g. ‘nix-build -A tests.login.x86_64-linux’, or equivalently,
  # ‘nix-build tests/login.nix -A result’.
  tests.bittorrent = callTest tests/bittorrent.nix {};
  tests.blivet = callTest tests/blivet.nix {};
  tests.boot = callTest tests/boot.nix {};
  tests.boot-stage1 = callTest tests/boot-stage1.nix {};
  tests.chromium = (callTest tests/chromium.nix { systems = [ "x86_64-linux" ]; }).stable;
  tests.dnscrypt-proxy = callTest tests/dnscrypt-proxy.nix { systems = [ "x86_64-linux" ]; };
  tests.ecryptfs = callTest tests/ecryptfs.nix {};
  tests.ec2-nixops = (callTest tests/ec2.nix { system = "x86_64-linux"; }).boot-ec2-nixops;
  tests.ec2-config = (callTest tests/ec2.nix { system = "x86_64-linux"; }).boot-ec2-config;
  tests.firefox = callTest tests/firefox.nix {};
  tests.firewall = callTest tests/firewall.nix {};
  #tests.gitlab = callTest tests/gitlab.nix {};
  tests.hibernate = callTest tests/hibernate.nix {};
  tests.installer = callTest tests/installer.nix {};
  tests.ipv6 = callTest tests/ipv6.nix {};
  tests.keymap = callTest tests/keymap.nix {};
  tests.initrdNetwork = callTest tests/initrd-network.nix {};
  tests.latestKernel.login = callTest tests/login.nix { latestKernel = true; };
  #tests.lightdm = callTest tests/lightdm.nix {};
  tests.login = callTest tests/login.nix {};
  #tests.logstash = callTest tests/logstash.nix {};
  tests.misc = callTest tests/misc.nix {};
  tests.mumble = callTest tests/mumble.nix {};
  tests.nat.firewall = callTest tests/nat.nix { withFirewall = true; };
  tests.nat.standalone = callTest tests/nat.nix { withFirewall = false; };
  tests.networking.networkd = callTest tests/networking.nix { networkd = true; };
  tests.networking.scripted = callTest tests/networking.nix { networkd = false; };
  # TODO: put in networking.nix after the test becomes more complete
  tests.networkingProxy = callTest tests/networking-proxy.nix {};
  tests.nfs3 = callTest tests/nfs.nix { version = 3; };
  tests.nfs4 = callTest tests/nfs.nix { version = 4; };
  tests.nsd = callTest tests/nsd.nix {};
  tests.printing = callTest tests/printing.nix {};
  tests.proxy = callTest tests/proxy.nix {};
  tests.quake3 = callTest tests/quake3.nix {};
  tests.runInMachine = callTest tests/run-in-machine.nix {};
  tests.simple = callTest tests/simple.nix {};
  tests.virtualbox = callTest tests/virtualbox.nix { system = "x86_64-linux"; };
  tests.module = moduleTests {
    cadvisor = { systems = [ "x86_64-linux" ]; };
    kubernetes = { systems = [ "x86_64-linux" ]; };
    docker = { systems = [ "x86_64-linux" ]; };
    dockerRegistry = { systems = [ "x86_64-linux" ]; };
    etcd = { systems = [ "x86_64-linux" ]; };
    fleet = { systems = [ "x86_64-linux" ]; };
    panamax = { systems = [ "x86_64-linux" ]; };
  };

}
