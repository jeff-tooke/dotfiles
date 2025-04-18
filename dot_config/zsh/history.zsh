# ---- History function ----
function my_history {
  local clear
  zparseopts -E c=clear  # Parse the -c option for clearing history

  if [[ -n "$clear" ]]; then
    echo -n >| "$HISTFILE"  # Clear the history file
    echo "History cleared."
  else
    fc -l 1  # Show all history starting from the first command
  fi
}

# History file configuration
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000       # Number of lines in memory
SAVEHIST=100000      # Number of lines stored in history file

# History options
setopt hist_ignore_dups
setopt hist_ignore_space      
setopt inc_append_history     
setopt extended_history       