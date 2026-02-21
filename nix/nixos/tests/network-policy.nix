{ pkgs, ... }:
let
  healthcheckScript = pkgs.writeText "healthcheck-network-policy.py" ''
    import json
    import urllib.request
    import sys

    def fetch(url):
        with urllib.request.urlopen(url, timeout=10) as response:
            return json.loads(response.read().decode())

    health = fetch(sys.argv[1])
    assert health.get("healthy") is True, "health failed: {}".format(health)
    print("[PASS] healthy version={}".format(health.get("version", "?")))
  '';

  httpServerScript = pkgs.writeText "http-server.py" ''
    import http.server
    import socketserver
    import sys

    PORT = int(sys.argv[1])
    LOG_FILE = sys.argv[2] if len(sys.argv) > 2 else "/tmp/http-connections.log"

    class LoggingHandler(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):
            with open(LOG_FILE, "a") as f:
                f.write(f"CONNECTION from {self.client_address[0]}:{self.client_address[1]}\\n")
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(b"OK\\n")

        def log_message(self, format, *args):
            pass

    with socketserver.TCPServer(("0.0.0.0", PORT), LoggingHandler) as httpd:
        httpd.serve_forever()
  '';
in
pkgs.testers.nixosTest {
  name = "opencode-network-policy";

  nodes = {
    allowed =
      { pkgs, ... }:
      {
        system.stateVersion = "24.11";
        environment.systemPackages = [ pkgs.python3 ];
        networking.firewall.enable = false;
      };

    blocked =
      { pkgs, ... }:
      {
        system.stateVersion = "24.11";
        environment.systemPackages = [ pkgs.python3 ];
        networking.firewall.enable = false;
      };

    client =
      { pkgs, ... }:
      {
        system.stateVersion = "24.11";
        environment.systemPackages = [
          pkgs.curl
          pkgs.python3
        ];
      };

    machine =
      { pkgs, ... }:
      {
        imports = [ (import ../module.nix) ];
        system.stateVersion = "24.11";
        environment.systemPackages = [
          pkgs.curl
          pkgs.python3
        ];

        networking.nftables.enable = true;
        networking.firewall.enable = true;

        users.users.opencode-isolated.uid = 975;

        services.opencode = {
          enable = true;
          defaults.directory = "/var/lib/opencode/default-directory";
          instances.isolated = {
            directory = "/srv/isolated";
            listen = {
              address = "0.0.0.0";
              port = 8787;
            };
            openFirewall = true;
            networkIsolation = {
              enable = true;
              outboundAllowCidrs = [ "192.168.1.1/32" ];
            };
          };
        };

        system.activationScripts.testDirs = "mkdir -p /srv/isolated";
      };
  };

  testScript = ''
    start_all()

    allowed.wait_for_unit("multi-user.target")
    blocked.wait_for_unit("multi-user.target")
    client.wait_for_unit("multi-user.target")

    allowed.succeed("python3 ${httpServerScript} 19999 /tmp/http-connections.log &>/dev/null &")
    blocked.succeed("python3 ${httpServerScript} 19999 /tmp/http-connections.log &>/dev/null &")
    allowed.sleep(1)
    blocked.sleep(1)

    allowed.wait_for_open_port(19999)
    blocked.wait_for_open_port(19999)

    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("nftables.service")
    machine.wait_for_unit("opencode-isolated-setup.service")
    machine.wait_for_unit("opencode-isolated.service")
    machine.wait_for_open_port(8787)

    output = machine.succeed("nft list table inet opencode-egress")
    assert "opencode-isolated-blocked" in output, f"Expected log prefix in nftables output: {output}"
    assert "192.168.1.1" in output, f"Expected allowed CIDR in nftables output: {output}"
    print("Test 1 PASS: nftables structure correct")

    client.succeed("python3 ${healthcheckScript} http://machine:8787/global/health")
    print("Test 2 PASS: inbound through firewall works (openFirewall=true)")

    machine.succeed(
      "sudo -u opencode-isolated curl --max-time 5 --silent http://allowed:19999/"
    )
    allowed.succeed("grep -q 'CONNECTION from' /tmp/http-connections.log")
    print("Test 3 PASS: outbound to allowed CIDR succeeds (verified at target)")

    blocked.succeed("truncate -s 0 /tmp/http-connections.log")

    machine.fail(
      "sudo -u opencode-isolated curl --max-time 3 --silent http://blocked:19999/"
    )
    blocked.succeed("test ! -s /tmp/http-connections.log")
    print("Test 4 PASS: outbound to non-allowed IP blocked (verified at target - no connection received)")

    machine.wait_until_succeeds(
      "journalctl -k | grep -q 'opencode-isolated-blocked'",
      timeout=10
    )
    print("Test 5 PASS: blocked outbound logged with instance prefix")

    for i in range(10):
      machine.execute(
        "sudo -u opencode-isolated curl --max-time 1 --silent http://blocked:19999/ || true"
      )
    machine.sleep(2)

    count = int(machine.succeed(
      "journalctl -k | grep -c 'opencode-isolated-blocked' || echo 0"
    ).strip())
    assert 1 <= count <= 6, f"Expected 1-6 rate-limited log entries, got {count}"
    print(f"Test 6 PASS: rate limiting works (logged {count} of 11+ blocked attempts)")

    blocked.succeed("test ! -s /tmp/http-connections.log")
    print("Test 7 PASS: blocked node received zero connections even after burst")

    print("network-policy: ALL TESTS PASS")
  '';
}
