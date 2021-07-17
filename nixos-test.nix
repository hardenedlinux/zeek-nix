{ makeTest, pkgs, self }:
{
  zeek-vm-systemd = makeTest
    {
      name = "zeek-systemd";
      machine = { config, pkgs, ... }: {
        imports = [
          self.nixosModules.zeek
        ];

        virtualisation.memorySize = 2046;

        services.zeek = {
          enable = true;
          standalone = true;
          interface = "eth0";
          listenAddress = "localhost";
          package = self.packages."${pkgs.system}".zeek-release.override {
            KafkaPlugin = true;
            PostgresqlPlugin = true;
            Http2Plugin = true;
            CommunityIdPlugin = true;
            ZipPlugin = true;
            PdfPlugin = true;
            SpicyPlugin = true;
          };
        };
      };
      testScript = ''
        start_all()
        machine.wait_for_unit("network.target")
        machine.wait_for_unit("zeek.service")
        machine.sleep(5)
        print(machine.succeed("ls -il /var/lib/zeek"))
      '';
    }
    {
      inherit pkgs;
      inherit (pkgs) system;
    };
}
