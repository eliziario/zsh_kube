############################################################
# Display all Zsh hook arrays and functions
#
# Returns true if any functions have been associated with
# Zsh hooks
############################################################
zhooks() {

  (( ${+terminfo} )) || zmodload zsh/terminfo
  if (( ${terminfo[colors]:-0} >= 8 )); then
    local start_color=${(%):-%F{yellow}}
    local end_color=${(%):-%f}
  fi

  local -a hooks
  hooks=(
    'chpwd' \
    'periodic' \
    'precmd' \
    'preexec' \
    'zshaddhistory' \
    'zsh_directory_name' \
    'zshexit'
    )

  local hook hook_array_name hook_array_content hook_function ret
  for hook in ${hooks[@]}; do
    # Display contents of hook arrays
    hook_array_name="${hook}_functions"
    hook_array_content=$(print -l -- ${${(P)hook_array_name}[@]})
    if [[ -n $hook_array_content ]]; then
      printf -- '%s:\n%s\n\n' "${start_color}${hook_array_name}${end_color}" "$hook_array_content"
      (( ret++ ))
    fi
    # Display defined hook functions
    if (( ${+functions[$hook]} )); then
      hook_function=$(whence -c $hook)
      printf -- '%s\n\n' "${start_color}${hook_function%%\(*}${end_color}${hook_function#* }"
      (( ret++ ))
    fi
  done

  (( ret ))
}

############################################################
# Unload function
#
# See https://github.com/agkozak/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc#unload-fun
############################################################
zhooks_plugin_unload() {
  unfunction zhooks $0
}