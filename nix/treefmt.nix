_: {
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    prettier = {
      enable = true;
      includes = [
        "*.js"
        "*.ts"
        "**/*.js"
        "**/*.ts"
      ];
    };
  };

  settings.global.excludes = [
    "*.md"
    "node_modules/**"
    ".git/**"
  ];
}
