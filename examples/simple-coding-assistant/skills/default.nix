{ lib, ... }:
{
  # Skills are markdown files in a directory, loaded by opencode at runtime.
  # Each .md file in the paths directory becomes a skill.
  # The Nix store path ensures skills are immutable and reproducible.
  opencode.skills.paths = [ "${./skill-files}" ];
}
