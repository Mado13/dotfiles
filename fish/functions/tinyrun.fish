function tinyrun
  # Combine arguments into a single string
  set -l args_str (string join " " $argv)
  
  # Call wezterm with the arguments
  wezterm start -- sh -c "echo $args_str; sleep infinity"
end
