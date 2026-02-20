# Primary agents: chief, bird, plan, explore, general, data-processor
{ ... }:

{
  opencode.agent = {
    # chief — the primary orchestrating agent
    chief = {
      mode = "primary";
      prompt = "{file:./SYSTEM_PROMPT.md}";
      permission = {
        question = "allow";
        external_task = "allow";
      };
    };

    # bird — the drinking-bird loop agent (primary, with compaction monitoring)
    bird = {
      mode = "primary";
      # NOTE: agent.options is an escape hatch for plugin-specific options
      # (here: opencode-dcp compaction monitoring settings)
      options = {
        compaction = {
          monitorEnabled = true;
          warningThreshold = 0.55;
          criticalThreshold = 0.75;
          forceCompactionEnabled = true;
          cooldownMs = 60000;
        };
      };
      permission = {
        question = "allow";
      };
    };

    # plan — planning agent (read-only, no edits)
    plan = {
      permission = {
        edit = "deny";
        apply_patch = "deny";
        question = "allow";
        bash = "deny";
      };
    };

    # explore — codebase exploration
    explore = {
      model = "{env:OPENCODE_MODEL_EXPLORE}";
    };

    # general — general purpose
    general = {
      model = "{env:OPENCODE_MODEL_GENERAL}";
    };

    # data-processor — specialized data processing agent (uses vision model)
    data-processor = {
      model = "ollama/llava-v1.6-34b";
      prompt = "{file:./prompts/data-processor.md}";
      permission = {
        "*" = "deny";
        # NOTE: skill sub-permissions (skill.data-import-tool) not yet modeled
        read = "allow";
        bash = "allow";
        glob = "allow";
        prune = "deny";
        distill = "deny";
        # external_directory nested rules not yet modeled
      };
    };

    # Disable legacy/unused agents
    beads-task-agent = {
      disable = true;
    };
  };
}
