
#!/bin/bash
#
# This script creates a new tmux session with a specific pane layout.
# It first splits the window vertically, then splits the right pane horizontally.
# Finally, it echoes the pane number into each pane.
#

# Define a name for the new session to avoid conflicts
SESSION_NAME="my_split_session"

# Check if a session with this name already exists. If so, kill it.
tmux has-session -t $SESSION_NAME 2>/dev/null
if [ $? -eq 0 ]; then
  tmux kill-session -t $SESSION_NAME
fi

# 1. Start a new, detached tmux session.
# The initial window is 0, and the initial pane is 0.
tmux new-session -d -s $SESSION_NAME

# 2. Split the first pane (0) vertically.
# This creates a new pane (1) to the right.
tmux split-window -v -t $SESSION_NAME:0.0

# 3. Split the newly created pane (1) horizontally.
# This creates another new pane (2) below it.
tmux split-window -h -t $SESSION_NAME:0.1

# 4. Send the `echo` command to each pane.
# The `-t` flag targets a specific pane using the format: session:window.pane
# `C-m` is equivalent to pressing the Enter key.
tmux send-keys -t $SESSION_NAME:0.0 'echo "--- This is Pane 0 ---"' C-m
tmux send-keys -t $SESSION_NAME:0.1 'echo "--- This is Pane 1 ---"' C-m
tmux send-keys -t $SESSION_NAME:0.2 'echo "--- This is Pane 2 ---"' C-m

# Optional: Select a more balanced layout after splitting
tmux select-layout -t $SESSION_NAME:0 tiled

# 5. Attach to the newly created session to view the result.
tmux attach-session -t $SESSION_NAME

