{ lib, ... }:

let
  inherit (lib) mkOption types;
  mkKeybind = desc: mkOption {
    type = types.nullOr types.str;
    default = null;
    description = desc;
  };
in
{
  options.opencode.keybinds = mkOption {
    type = types.nullOr (types.submodule {
      options = {
        leader = mkKeybind "Leader key for keybind sequences";
        app = mkKeybind "App help/info";
        session = mkKeybind "Session management";
        editor_open = mkKeybind "Open external editor";
        theme_list = mkKeybind "Open theme picker";
        input_submit = mkKeybind "Submit input";
        input_newline = mkKeybind "Insert newline in input";
        input_paste = mkKeybind "Paste from clipboard";
        input_clear = mkKeybind "Clear input buffer";
        input_undo = mkKeybind "Undo last input change";
        messages_scroll_up = mkKeybind "Scroll messages up";
        messages_scroll_down = mkKeybind "Scroll messages down";
        messages_first = mkKeybind "Jump to first message";
        messages_last = mkKeybind "Jump to last message";
        messages_copy = mkKeybind "Copy message content";
        app_exit = mkKeybind "Exit the application";
        interrupt = mkKeybind "Interrupt current operation";
        revert = mkKeybind "Revert last change";
        expand = mkKeybind "Expand/collapse view";
        history_previous = mkKeybind "Navigate to previous history entry";
        history_next = mkKeybind "Navigate to next history entry";
        commands_list = mkKeybind "Open command list";
        tool_details = mkKeybind "Toggle tool call details";
        file_diff = mkKeybind "Show file diff";
        session_new = mkKeybind "Create new session";
        session_list = mkKeybind "List all sessions";
        session_share = mkKeybind "Share current session";
        model_list = mkKeybind "Open model picker";
        agent_list = mkKeybind "Open agent picker";
        project_init = mkKeybind "Initialize project";
      };
    });
    default = null;
    description = "Keybinding configuration. Values are key strings like '?' or 'ctrl+s'";
  };
}
