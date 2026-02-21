{ lib, ... }:

let
  inherit (lib) mkOption types;
  mkKeybind =
    desc:
    mkOption {
      type = types.nullOr types.str;
      default = null;
      description = desc;
    };
in
{
  options.opencode.keybinds = mkOption {
    type = types.nullOr (
      types.submodule {
        options = {
          leader = mkKeybind "Leader key prefix for multi-key sequences. Other keybinds can reference it via '<leader>'.";
          app_exit = mkKeybind "Key to exit the application.";
          editor_open = mkKeybind "Key to open the current content in an external editor ($EDITOR).";
          theme_list = mkKeybind "Key to open the theme picker dialog.";
          sidebar_toggle = mkKeybind "Key to toggle the sidebar panel.";
          scrollbar_toggle = mkKeybind "Key to toggle the session scrollbar.";
          username_toggle = mkKeybind "Key to toggle username visibility.";
          status_view = mkKeybind "Key to view status information.";
          session_export = mkKeybind "Key to export the session to an editor.";
          session_new = mkKeybind "Key to create a new session.";
          session_list = mkKeybind "Key to list all sessions.";
          session_timeline = mkKeybind "Key to show session timeline.";
          session_fork = mkKeybind "Key to fork a session from the current message.";
          session_rename = mkKeybind "Key to rename the current session.";
          session_delete = mkKeybind "Key to delete the current session.";
          stash_delete = mkKeybind "Key to delete a stash entry.";
          model_provider_list = mkKeybind "Key to open provider list from model dialog.";
          model_favorite_toggle = mkKeybind "Key to toggle model favorite status.";
          session_share = mkKeybind "Key to share the current session.";
          session_unshare = mkKeybind "Key to unshare the current session.";
          session_interrupt = mkKeybind "Key to interrupt the currently running operation.";
          session_compact = mkKeybind "Key to compact the session history.";
          messages_page_up = mkKeybind "Key to scroll messages up by one page.";
          messages_page_down = mkKeybind "Key to scroll messages down by one page.";
          messages_line_up = mkKeybind "Key to scroll messages up by one line.";
          messages_line_down = mkKeybind "Key to scroll messages down by one line.";
          messages_half_page_up = mkKeybind "Key to scroll messages up by half page.";
          messages_half_page_down = mkKeybind "Key to scroll messages down by half page.";
          messages_first = mkKeybind "Key to navigate to the first message.";
          messages_last = mkKeybind "Key to navigate to the last message.";
          messages_next = mkKeybind "Key to navigate to the next message.";
          messages_previous = mkKeybind "Key to navigate to the previous message.";
          messages_last_user = mkKeybind "Key to navigate to the last user message.";
          messages_copy = mkKeybind "Key to copy the selected message content to clipboard.";
          messages_undo = mkKeybind "Key to undo the last message.";
          messages_redo = mkKeybind "Key to redo the last undone message.";
          messages_toggle_conceal = mkKeybind "Key to toggle code block concealment in messages.";
          tool_details = mkKeybind "Key to toggle detailed tool call output visibility.";
          model_list = mkKeybind "Key to open the model picker dialog.";
          model_cycle_recent = mkKeybind "Key to cycle to the next recently used model.";
          model_cycle_recent_reverse = mkKeybind "Key to cycle to the previous recently used model.";
          model_cycle_favorite = mkKeybind "Key to cycle to the next favorite model.";
          model_cycle_favorite_reverse = mkKeybind "Key to cycle to the previous favorite model.";
          command_list = mkKeybind "Key to open the slash command list.";
          agent_list = mkKeybind "Key to open the agent picker dialog.";
          agent_cycle = mkKeybind "Key to cycle to the next agent.";
          agent_cycle_reverse = mkKeybind "Key to cycle to the previous agent.";
          variant_cycle = mkKeybind "Key to cycle model variants.";
          input_clear = mkKeybind "Key to clear the entire input buffer.";
          input_paste = mkKeybind "Key to paste clipboard contents into the input buffer.";
          input_submit = mkKeybind "Key to submit the current input to the agent.";
          input_newline = mkKeybind "Key to insert a literal newline in the input buffer.";
          input_move_left = mkKeybind "Key to move cursor left in input.";
          input_move_right = mkKeybind "Key to move cursor right in input.";
          input_move_up = mkKeybind "Key to move cursor up in input.";
          input_move_down = mkKeybind "Key to move cursor down in input.";
          input_select_left = mkKeybind "Key to extend selection left in input.";
          input_select_right = mkKeybind "Key to extend selection right in input.";
          input_select_up = mkKeybind "Key to extend selection up in input.";
          input_select_down = mkKeybind "Key to extend selection down in input.";
          input_line_home = mkKeybind "Key to move to start of line in input.";
          input_line_end = mkKeybind "Key to move to end of line in input.";
          input_select_line_home = mkKeybind "Key to select to start of line in input.";
          input_select_line_end = mkKeybind "Key to select to end of line in input.";
          input_visual_line_home = mkKeybind "Key to move to start of visual line in input.";
          input_visual_line_end = mkKeybind "Key to move to end of visual line in input.";
          input_select_visual_line_home = mkKeybind "Key to select to start of visual line in input.";
          input_select_visual_line_end = mkKeybind "Key to select to end of visual line in input.";
          input_buffer_home = mkKeybind "Key to move to start of buffer in input.";
          input_buffer_end = mkKeybind "Key to move to end of buffer in input.";
          input_select_buffer_home = mkKeybind "Key to select to start of buffer in input.";
          input_select_buffer_end = mkKeybind "Key to select to end of buffer in input.";
          input_delete_line = mkKeybind "Key to delete line in input.";
          input_delete_to_line_end = mkKeybind "Key to delete to end of line in input.";
          input_delete_to_line_start = mkKeybind "Key to delete to start of line in input.";
          input_backspace = mkKeybind "Key to backspace in input.";
          input_delete = mkKeybind "Key to delete character in input.";
          input_undo = mkKeybind "Key to undo in input.";
          input_redo = mkKeybind "Key to redo in input.";
          input_word_forward = mkKeybind "Key to move word forward in input.";
          input_word_backward = mkKeybind "Key to move word backward in input.";
          input_select_word_forward = mkKeybind "Key to select word forward in input.";
          input_select_word_backward = mkKeybind "Key to select word backward in input.";
          input_delete_word_forward = mkKeybind "Key to delete word forward in input.";
          input_delete_word_backward = mkKeybind "Key to delete word backward in input.";
          history_previous = mkKeybind "Key to navigate to the previous input history entry.";
          history_next = mkKeybind "Key to navigate to the next input history entry.";
          session_child_cycle = mkKeybind "Key to navigate to the next child session.";
          session_child_cycle_reverse = mkKeybind "Key to navigate to the previous child session.";
          session_parent = mkKeybind "Key to navigate to the parent session.";
          terminal_suspend = mkKeybind "Key to suspend the terminal.";
          terminal_title_toggle = mkKeybind "Key to toggle terminal title.";
          tips_toggle = mkKeybind "Key to toggle tips on the home screen.";
          display_thinking = mkKeybind "Key to toggle thinking blocks visibility.";
        };
      }
    );
    default = null;
    description = ''
      Keybinding configuration. Values are key strings such as 'ctrl+s', 'ctrl+n',
      or 'alt+x'. Multiple bindings can be comma-separated: 'ctrl+c,ctrl+d'.
      Use '<leader>' to reference the leader key prefix.
    '';
  };
}
