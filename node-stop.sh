#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

#########################################################################
totalRpc=0
totalValidator=0
totalNodes=$(($totalRpc + $totalValidator))

isRPC=false
isValidator=false

#########################################################################
source ./.env
#########################################################################

#+-----------------------------------------------------------------------------------------------+
#|                                                                                                                             |
#|                                                                                                                             |
#|                                                      FUNCTIONS                                                |
#|                                                                                                                             |
#|                                                                                                                             |
#+-----------------------------------------------------------------------------------------------+

countNodes(){
  local i=1
  totalNodes=$(ls -l ./chaindata/ | grep -c ^d)
  while [[ $i -le $totalNodes ]]; do
    
    if [ -f "./chaindata/node$i/.rpc" ]; then  
      ((totalRpc += 1))
    else  
        if [ -f "./chaindata/node$i/.validator" ]; then
        ((totalValidator += 1))
        fi
    fi  
    
    ((i += 1))
  done 
}

stopNode(){
  local session=$1
  local nodePath="/root/core-blockchain/chaindata/$session"
  
  if tmux has-session -t "$session" 2>/dev/null; then
    tmux send-keys -t "$session" "exit" Enter
    sleep 2

    # Check if the geth.ipc file exists after stopping the node
    if [ -e "$nodePath/geth.ipc" ]; then
      echo -e "${ORANGE}Node $session did not stop gracefully. Retrying...${NC}"
      tmux send-keys -t "$session" "exit" Enter
      sleep 2
    fi

    # Final check
    if [ -e "$nodePath/geth.ipc" ]; then
      echo -e "${RED}Node $session is still running. Killing tmux session...${NC}"
      tmux kill-session -t "$session"
    else
      echo -e "${GREEN}Node $session stopped successfully.${NC}"
      tmux kill-session -t "$session"
    fi
  else
    echo -e "${RED}Session $session does not exist.${NC}"
  fi
}

stopRpc(){
  i=$((totalValidator + 1))
  while [[ $i -le $totalNodes ]]; do
    stopNode "node$i"
    ((i += 1))
  done 
}

stopValidator(){
  i=1
  while [[ $i -le $totalValidator ]]; do
    stopNode "node$i"
    ((i += 1))
  done 
}

finalize(){
  pm2 stop all
  countNodes
  
  if [ "$isRPC" = true ]; then
    echo -e "\n${GREEN}+------------------- Stopping RPC -------------------+"
    stopRpc
  fi

  if [ "$isValidator" = true ]; then
    echo -e "\n${GREEN}+------------------- Stopping Validator -------------------+"
    stopValidator
  fi

  echo -e "\n${GREEN}+------------------ Active Nodes -------------------+"
  tmux ls || echo -e "${RED}No active tmux sessions found.${NC}"
  echo -e "\n${GREEN}+------------------ Active Nodes -------------------+${NC}"
}

# Default variable values
verbose_mode=false
output_file=""

# Function to display script usage
usage() {
  echo -e "\nUsage: $0 [OPTIONS]"
  echo "Options:"
  echo -e "\t\t -h, --help      Display this help message"
  echo -e " \t\t -v, --verbose   Enable verbose mode"
  echo -e "\t\t --rpc       Stop all the RPC nodes installed"
  echo -e "\t\t --validator       Stop all the Validator nodes installed"
}

has_argument() {
  [[ ("$1" == *=* && -n ${1#*=}) || (! -z "$2" && "$2" != -*) ]]
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

# Function to handle options and arguments
handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in

    # display help
    -h | --help)
      usage
      exit 0
      ;;

    # toggle verbose
    -v | --verbose)
      verbose_mode=true
      ;;

    # take file input
    -f | --file*)
      if ! has_argument $@; then
        echo "File not specified." >&2
        usage
        exit 1
      fi

      output_file=$(extract_argument $@)

      shift
      ;;

    # take ROC count
    --rpc)
        isRPC=true
      ;;

    # take validator count
    --validator)
        isValidator=true
      ;;

    *)
      echo "Invalid option: $1" >&2
      usage
      exit 1
      ;;

    esac
    shift
  done
}

# Main script execution
handle_options "$@"

# Perform the desired actions based on the provided flags and arguments
if [ "$verbose_mode" = true ]; then
  echo "Verbose mode enabled."
fi

if [ -n "$output_file" ]; then
  echo "Output file specified: $output_file"
fi

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    usage
    exit 1
fi

finalize
