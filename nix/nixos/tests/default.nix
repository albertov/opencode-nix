{ pkgs }:
{
  multi-instance = import ./multi-instance.nix { inherit pkgs; };
  sandbox-isolation = import ./sandbox-isolation.nix { inherit pkgs; };
  setup-idempotence = import ./setup-idempotence.nix { inherit pkgs; };
  env-and-config = import ./env-and-config.nix { inherit pkgs; };
  postgres-socket = import ./postgres-socket.nix { inherit pkgs; };
}
