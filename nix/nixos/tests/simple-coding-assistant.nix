{ pkgs, ... }:
let
  healthcheckScript = pkgs.writeText "healthcheck.py" ''
    import json
    import urllib.request

    def fetch(url):
        with urllib.request.urlopen(url) as response:
            return json.loads(response.read().decode())

    base = "http://127.0.0.1:8787"

    # 1. Health check - confirms opencode serve is up
    health = fetch(base + "/global/health")
    assert health.get("healthy") is True, \
        "health endpoint returned healthy=false: {}".format(health)
    print("[PASS] healthy=true version={}".format(health.get("version", "?")))

    # 2. Config check - agents from /global/config
    cfg = fetch(base + "/global/config")

    # Agents are keyed by name in opencode.agent (attrsOf)
    agents_raw = cfg.get("agent") or (cfg.get("opencode") or {}).get("agent") or {}
    if isinstance(agents_raw, dict):
        found_agents = set(agents_raw.keys())
    elif isinstance(agents_raw, list):
        found_agents = {a.get("name") for a in agents_raw if isinstance(a, dict) and a.get("name")}
    else:
        found_agents = set()

    expected_agents = {"general", "explorer", "implementer", "reviewer"}
    missing_agents = expected_agents - found_agents
    assert not missing_agents, \
        "missing agents: {}, found: {}".format(sorted(missing_agents), sorted(found_agents))
    print("[PASS] agents: {}".format(sorted(found_agents)))

    # 3. Skills check - opencode.skills.paths should be non-empty
    skills_cfg = cfg.get("skills") or (cfg.get("opencode") or {}).get("skills") or {}
    paths = skills_cfg.get("paths") if isinstance(skills_cfg, dict) else None
    assert isinstance(paths, list) and len(paths) > 0, \
        "expected skills.paths to be a non-empty list, got: {}".format(skills_cfg)
    print("[PASS] skills.paths: {}".format(paths))

    print("")
    print("========== PASS ==========")
  '';
in
pkgs.testers.nixosTest {
  name = "opencode-simple-coding-assistant";

  nodes.machine = { config, lib, pkgs, ... }: {
    imports = [
      (import ../module.nix)
      (import ../../../examples/simple-coding-assistant { inherit config lib pkgs; })
    ];

    environment.systemPackages = [ pkgs.python3 ];

    # Required: the module gates all output on this flag
    services.opencode.enable = true;

    services.opencode.instances.my-project = {
      directory = "/srv/projects/my-project";
      # No secrets file needed for a health-check test
      environmentFile = lib.mkForce null;
    };

    system.activationScripts.testDirs = ''
      mkdir -p /srv/projects/my-project
    '';
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Diagnostic: show all opencode* units so failures are debuggable
    machine.succeed("systemctl list-units 'opencode*' --all --no-pager || true")

    # Setup unit is oneshot + RemainAfterExit=true -> active(exited) after success
    machine.wait_for_unit("opencode-my-project-setup.service")

    # Main service: opencode serve --port 8787 --hostname 127.0.0.1
    machine.wait_for_unit("opencode-my-project.service")

    # Wait for TCP port to be bound before hitting the API
    machine.wait_for_open_port(8787)

    # Dump recent service logs for diagnostics
    machine.succeed("journalctl -u opencode-my-project.service --no-pager -n 30 || true")

    # Run all API assertions from a Nix store Python script (avoids heredoc escaping issues)
    machine.succeed("python3 ${healthcheckScript}")

    # Filesystem layout checks
    machine.succeed("test -d /var/lib/opencode/instance-state/my-project/.config/opencode")
    machine.succeed("test -L /var/lib/opencode/instance-state/my-project/.config/opencode/opencode.json")
    print("[PASS] stateDir layout correct")

    # PATH is injected into service environment
    machine.succeed(
        "systemctl show opencode-my-project.service --property=Environment | grep -q PATH"
    )
    print("[PASS] PATH is set in service environment")

    print("")
    print("========================================")
    print("simple-coding-assistant e2e test: PASS")
    print("========================================")
  '';
}
