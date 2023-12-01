# Define the function to intercept kubectl commands
# Function to deactivate kubectl aliases
deactivate_kalias() {
  # Unset functions
  unset -f watch_kubectl_get watch_kubectl_command intercept_kubectl_command deactivate_kalias

  # Unset environment variables
  unset KNS KT K_RS_COUNT K_RS_JSON
  for var in ${(M)parameters:#K_RS_NUMBER*}; do
    unset $var
  done
  if [[ -v KALIAS_ORIGINAL_PRECMD ]]; then
    preexec "${KALIAS_ORIGINAL_PRECMD}"
  else 
    preexec() {}
  fi
}

intercept_kubectl_command() {  
  local command_line=$(echo $1 | xargs)  
  # Check if the command line contains "kubectl get"
  if [[ $command_line == *"kubectl get"* ]]; then  
    watch_kubectl_get "${(@s/ /)command_line}"
  elif [[ $command_line == *"kubectl"* ]]; then
    watch_kubectl_command "${(@s/ /)command_line}"
  fi
}

if [[ -n "$(functions -M precmd)" ]]; then
     export KALIAS_ORIGINAL_PRECMD="${preexec}" 
fi

# Set up the precmd hook to execute the intercept_kubectl_command function
preexec() {    
    intercept_kubectl_command $1
}



# Function to watch kubectl get commands 
# capture results, save last used arguments
# and save list of results in convenience variables
# Function to watch kubectl get commands
watch_kubectl_get() {
  # Clear existing K_RS_* variables
  if [[ -v K_RS_COUNT ]]; then
    for ((i=1; i<=$K_RS_COUNT; i++)); do
        unset K_RS_$i;
        unset K_NS_$i;
    done
  fi  
  export K_RS_COUNT=0
  export K_RS_JSON=""

  local namespace=""
  local object=""
  local count=0

  for arg in "$@"; do
    case $arg in
      -n=*|--namespace=*) namespace="${arg#*=}" ;;
      get) object="$2" ;;
    esac
  done

  # Set environment variables
  export KNS="$namespace"
  export KT="$object"
  export K_TYPE=$(echo "$@" | cut -d ' ' -f 3)

  # Process plain or wide output
  export output=$("$@")

  if [[ -n "$output" ]]; then
    export index_of_name=$(echo "$output" | awk '{for(i=1; i<=NF; i++) if($i == "NAME") print i}')
    export index_of_ns=$(echo "$output" | awk '{for(i=1; i<=NF; i++) if($i == "NAMESPACE") print i}')
    export lines=$(echo "$output" | awk 'FNR > 1 {print }')
    export K_RS_COUNT=$(echo "$lines" | wc -l) 

    # Store each first column in a series of K_RS_NUMBER
    
    for ((i=1; i<=$K_RS_COUNT; i++)); do
        if [[ "$index_of_name"  ==  "2" ]]; then 
            export K_RS_$i=$(echo "$lines" | awk -v i=$i -v index=$index_of_name 'NR == i {print $index}')
            export K_NS_$i=$(echo "$lines" | awk -v i=$i -v index_ns=$index_of_ns 'NR == i {print $index_ns}')
            
        else 
            export K_RS_$i=$(echo "$lines" | awk -v i=$i -v index=$index_of_name 'NR == i {print $index}')
            export K_NS_$i="$KNS"
        fi
    done                 
  fi
}

# Example usage:
# watch_kubectl_get pods
# echo "Count: $K_RS_COUNT"
# echo "Pod 1: $K_RS_NUMBER1"
# echo "Pod 2: $K_RS_NUMBER2"


# Function to watch any kubectl command
watch_kubectl_command() {
  local namespace=""
  local object=""

  for arg in "$@"; do
    case $arg in
      -n=*|--namespace=*) namespace="${arg#*=}" ;;
      *) object="$arg" && break ;;
    esac
  done

  # Set environment variables
  export KNS="$namespace"
  export KT="$object"

  # Execute the kubectl command
  "$@"
}

# Alias commonly used kubectl commands
alias k="kubectl"
alias kg="watch_kubectl_get get"
alias kga="watch_kubectl_get get all"
alias kgs="watch_kubectl_get get pods --all-namespaces"
alias kdes="watch_kubectl_command describe"
alias klogs="watch_kubectl_command logs"
alias kex="watch_kubectl_command exec -it"
alias kapp="watch_kubectl_command apply -f"
alias kd="watch_kubectl_command delete"
alias kdel="watch_kubectl_command delete"
alias krm="watch_kubectl_command delete"

# Function to display help for kubectl aliases and commands
kalias_help() {
  echo "=== kubectl Aliases ==="
  echo "k      - Alias for 'kubectl'"
  echo "kga    - Alias for 'watch_kubectl_get get all'"
  echo "kgs    - Alias for 'watch_kubectl_get get pods --all-namespaces'"
  echo "kdes   - Alias for 'watch_kubectl_command describe'"
  echo "klogs  - Alias for 'watch_kubectl_command logs'"
  echo "kex    - Alias for 'watch_kubectl_command exec -it'"
  echo "kapp   - Alias for 'watch_kubectl_command apply -f'"
  echo "kd     - Alias for 'watch_kubectl_command delete'"
  echo "kdel   - Alias for 'watch_kubectl_command delete'"
  echo "krm    - Alias for 'watch_kubectl_command delete'"
  echo ""
  echo "=== kubectl Functions ==="
  echo "watch_kubectl_get - Watch 'kubectl get' commands and set environment variables:"
  echo "                    KNS, KT, K_RS_COUNT, K_RS_NUMBER* (for plain or wide output), K_RS_JSON"
  echo "watch_kubectl_command - Watch any 'kubectl' command and set environment variables: KNS, KT"
}


