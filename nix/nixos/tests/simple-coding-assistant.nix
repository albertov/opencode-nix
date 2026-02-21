{ pkgs, ... }:
pkgs.testers.nixosTest {
  name = "opencode-simple-coding-assistant";

  nodes.machine = { config, lib, pkgs, ... }: {
    imports = [
      (import ../module.nix)
      (import ../../../examples/simple-coding-assistant { inherit config lib pkgs; })
    ];

    services.opencode.instances.my-project = {
      directory = "/srv/projects/my-project";
      environmentFile = pkgs.lib.mkForce null;
    };

    system.activationScripts.testDirs = ''
      mkdir -p /srv/projects/my-project
    '';
  };

  testScript = ''
    import json


    def fetch_json(url: str):
        payload = machine.succeed(
            "python3 - <<'PY'\n"
            "import json\n"
            "import urllib.request\n"
            f"with urllib.request.urlopen('{url}') as response:\n"
            "    data = json.loads(response.read().decode())\n"
            "print(json.dumps(data))\n"
            "PY"
        )
        return json.loads(payload)


    def names_from_collection(value, label: str):
        if value is None:
            raise AssertionError(f"missing '{label}' in /global/config response")
        if isinstance(value, dict):
            return set(value.keys())
        if isinstance(value, list):
            names = set()
            for entry in value:
                if isinstance(entry, str):
                    names.add(entry)
                elif isinstance(entry, dict):
                    name = entry.get("name")
                    if name:
                        names.add(name)
            return names
        raise AssertionError(
            f"expected '{label}' to be a dict or list, got {type(value).__name__}"
        )


    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("opencode-my-project-setup.service")
    machine.wait_for_unit("opencode-my-project.service")
    machine.wait_for_open_port(8787)

    health = fetch_json("http://127.0.0.1:8787/global/health")
    assert health.get("healthy") is True, f"expected healthy=true from /global/health, got: {health}"
    version = health.get("version", "<unknown>")
    print(f"health endpoint OK, version={version}")

    config_json = fetch_json("http://127.0.0.1:8787/global/config")
    agents = names_from_collection(
        config_json.get("agents", config_json.get("opencode", {}).get("agents")),
        "agents",
    )
    expected_agents = {"general", "explorer", "implementer", "reviewer"}
    missing_agents = sorted(expected_agents - agents)
    assert not missing_agents, (
        "missing expected agents in /global/config: "
        + ", ".join(missing_agents)
        + f"; found={sorted(agents)}"
    )

    skills = names_from_collection(
        config_json.get("skills", config_json.get("opencode", {}).get("skills")),
        "skills",
    )
    expected_skills = {"commit", "code-review"}
    missing_skills = sorted(expected_skills - skills)
    assert not missing_skills, (
        "missing expected skills in /global/config: "
        + ", ".join(missing_skills)
        + f"; found={sorted(skills)}"
    )

    machine.succeed(
        "systemctl show opencode-my-project.service --property=ActiveState | grep -q active"
    )
    machine.succeed("test -d /var/lib/opencode/instance-state/my-project/.config/opencode")
    machine.succeed(
        "test -L /var/lib/opencode/instance-state/my-project/.config/opencode/opencode.json"
    )
    machine.succeed(
        "systemctl show opencode-my-project.service --property=Environment | grep -q PATH"
    )

    print("simple-coding-assistant e2e test: PASS")
  '';
}
