import ./make-test.nix ({ pkgs, ...} : {
  name = "i3wm";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ aszlig ];
  };

  machine = { lib, pkgs, ... }: {
    imports = [ ./common/x11.nix ./common/user-account.nix ];
    services.xserver.displayManager.slim.autoLogin = true;
    services.xserver.displayManager.slim.defaultUser = "alice";
    services.xserver.windowManager.enable = lib.mkForce [ "i3" ];
  };

  testScript = { nodes, ... }: ''
    $machine->waitForX;
    $machine->waitForFile("/home/alice/.Xauthority");
    $machine->succeed("xauth merge ~alice/.Xauthority");
    $machine->waitForWindow(qr/first configuration/);
    $machine->sleep(1);
    $machine->screenshot("started");
    $machine->sendKeys("ret");
    $machine->sleep(1);
    $machine->sendKeys("alt");
    $machine->sleep(1);
    $machine->screenshot("configured");
    $machine->sendKeys("ret");
    $machine->sleep(2);
    $machine->sendKeys("alt-ret");
    $machine->waitForWindow(qr/machine.*alice/);
    $machine->sleep(1);
    $machine->screenshot("terminal");
  '';
})
