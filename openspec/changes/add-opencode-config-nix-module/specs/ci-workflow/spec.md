# ci-workflow

GitHub Actions workflow running `nix flake check` with Cachix binary caching.

## ADDED Requirements

### Requirement: Workflow triggers

The workflow runs on relevant code changes.

#### Scenario: Push to main

WHEN a commit is pushed to `main`
THEN the workflow runs.

#### Scenario: Pull request

WHEN a pull request is opened or updated
THEN the workflow runs.

---

### Requirement: Nix installation

The workflow uses a modern Nix installer with flakes support.

#### Scenario: Deterministic installer

WHEN the workflow runs
THEN it uses `DeterminateSystems/nix-installer-action` (or equivalent) to install Nix with flakes enabled by default.

---

### Requirement: Cachix integration

Binary caching avoids rebuilding dependencies on every run.

#### Scenario: Cachix configured

WHEN the workflow runs
THEN it sets up Cachix with `cachix/cachix-action` using a configured cache name.

#### Scenario: Cache name from secret

WHEN Cachix is configured
THEN the cache name is parameterized (repository variable or hardcoded) and the auth token comes from a repository secret (`CACHIX_AUTH_TOKEN`).

---

### Requirement: Check execution

The workflow runs the full Nix flake check.

#### Scenario: Flake check runs

WHEN the Nix and Cachix setup completes
THEN the workflow runs `nix flake check` which executes all checks (including config validation tests).

#### Scenario: Failure blocks merge

WHEN `nix flake check` fails
THEN the workflow fails, blocking PR merge (assuming branch protection).

---

### Requirement: Workflow file location

#### Scenario: Standard location

WHEN the repository is inspected
THEN `.github/workflows/check.yml` exists and defines the CI workflow.
