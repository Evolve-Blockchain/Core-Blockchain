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

#########################################################################

#+-----------------------------------------------------------------------------------------------+
#|                                                                                                                              |
#|                                                      FUNCTIONS                                                |
#|                                                                                                                              |     
#+------------------------------------------------------------------------------------------------+

task1(){
  # update and upgrade the server TASK 1
  echo -e "\n\n${ORANGE}TASK: ${GREEN}[Setting up environment]${NC}\n"
  apt update && apt upgrade -y
  echo -e "\n${GREEN}[TASK 1 PASSED]${NC}\n"
}

task2(){
  # installing build-essential TASK 2
  echo -e "\n${ORANGE}TASK: ${GREEN}[Setting up environment]${NC}\n"
  apt -y install build-essential tree
  echo -e "\n${GREEN}[TASK 2 PASSED]${NC}\n"
}

task3(){
  # getting golang TASK 3
  echo -e "\n${ORANGE}TASK: ${GREEN}[Getting GO]${NC}\n"
  cd ./tmp && wget "https://go.dev/dl/go1.17.3.linux-amd64.tar.gz"
  echo -e "\n${GREEN}[TASK 3 PASSED]${NC}\n"
}

task4(){
  # setting up golang TASK 4
  echo -e "\n${ORANGE}TASK: ${GREEN}[Setting GO]${NC}\n"
  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.3.linux-amd64.tar.gz

  LINE='PATH=$PATH:/usr/local/go/bin'
  if grep -Fxq "$LINE" /etc/profile
  then
    # code if found
    echo -e "${ORANGE}golang path is already added"
  else
    # code if not found
    echo -e '\nPATH=$PATH:/usr/local/go/bin' >>/etc/profile
  fi

  echo -e '\nsource ~/.bashrc' >>/etc/profile
  
  if [[ $totalValidator -gt 0 ]]; then
    
    LINE='cd /root/core-blockchain/'
    if grep -Fxq "$LINE" /etc/profile
    then
      # code if found
      echo -e "${ORANGE}path is already added"
    else
      # code if not found
      echo -e '\ncd /root/core-blockchain/' >>/etc/profile
    fi

    LINE='bash /root/core-blockchain/node-start.sh --validator'
    if grep -Fxq "$LINE" /etc/profile
    then
      # code if found
      echo -e "${ORANGE}autostart is already added"
    else
      # code if not found
      echo -e '\nbash /root/core-blockchain/node-start.sh --validator' >>/etc/profile
    fi
      
      
  fi

  if [[ $totalRpc -gt 0 ]]; then

    LINE='cd /root/core-blockchain/'
    if grep -Fxq "$LINE" /etc/profile
    then
      # code if found
      echo -e "${ORANGE}path is already added"
    else
      # code if not found
      echo -e '\ncd /root/core-blockchain/' >>/etc/profile
    fi

    LINE='bash /root/core-blockchain/node-start.sh --rpc'
    if grep -Fxq "$LINE" /etc/profile
    then
      # code if found
      echo -e "${ORANGE}autostart is already added"
    else
      # code if not found
      echo -e '\nbash /root/core-blockchain/node-start.sh --rpc' >>/etc/profile
    fi
    
  fi

  

  export PATH=$PATH:/usr/local/go/bin
  go env -w GO111MODULE=off
  echo -e "\n${GREEN}[TASK 4 PASSED]${NC}\n"
}

task5(){
  # set proper group and permissions TASK 5
  echo -e "\n${ORANGE}TASK: ${GREEN}[Setting up Permissions]${NC}\n"
  ls -all
  cd ../
  ls -all
  chown -R root:root ./
  chmod a+x ./node-start.sh
  echo -e "\n${GREEN}[TASK 5 PASSED]${NC}\n"
}

task6(){
  # do make all TASK 6
  echo -e "\n${ORANGE}TASK: ${GREEN}[Building Backend]${NC}\n"
  cd node_src
  make all
  echo -e "\n${GREEN}[TASK 6 PASSED]${NC}\n"
}

task7(){
  # setting up directories and structure for node/s TASK 7
  echo -e "\n${ORANGE}TASK: ${GREEN}[Building Backend]${NC}\n"

  cd ../

  i=1
  while [[ $i -le $totalNodes ]]; do
    mkdir ./chaindata/node$i
    ((i += 1))
  done

  tree ./chaindata
  echo -e "\n${GREEN}[TASK 7 PASSED]${NC}\n"
}

task8(){
  #TASK 8
  echo -e "\n${ORANGE}TASK: ${GREEN}[Setting up Accounts]${NC}\n"
  echo -e "\n${ORANGE}This step is very important. Input a password that will be used for a newly created validator account. In next step you will recieve a public key for your validator account"
  echo -e "${ORANGE}Once a validator account is created using your given password, I'll give you where the keystore file is located so you can import it in metamask\n\n${NC}"

  i=1
  while [[ $i -le $totalValidator ]]; do
    echo -e "\n\n${GREEN}+-----------------------------------------------------------------------------------------------------+\n"
    read -p "Enter password for validator $i:  " password
    echo $password >./chaindata/node$i/pass.txt
    ./node_src/build/bin/geth --datadir ./chaindata/node$i account new --password ./chaindata/node$i/pass.txt
    ((i += 1))
  done

  echo -e "\n${GREEN}[TASK 8 PASSED]${NC}\n"
}

labelNodes(){
  i=1
  while [[ $i -le $totalValidator ]]; do
    touch ./chaindata/node$i/.validator
    ((i += 1))
  done 

  i=$((totalValidator + 1))
  while [[ $i -le $totalNodes ]]; do
    touch ./chaindata/node$i/.rpc
    ((i += 1))
  done 
}

displayStatus(){
  # start the node
  echo -e "\n${ORANGE}STATUS: ${GREEN}ALL TASK PASSED!\n This program will now exit\n Now run ./node-start.sh${NC}\n"
}

displayWelcome(){
  # display welcome message
  echo -e "\n\n\t${ORANGE}Total RPC to be created: $totalRpc"
  echo -e "\t${ORANGE}Total Validators to be created: $totalValidator"
  echo -e "\t${ORANGE}Total nodes to be created: $totalNodes"
  echo -e "${GREEN}
  \t+------------------------------------------------+
  \t+   DPos node installation Wizard
  \t+   Target OS: Ubuntu 20.04 LTS (Focal Fossa)
  \t+   Your OS: $(. /etc/os-release && printf '%s\n' "${PRETTY_NAME}") 
  \t+------------------------------------------------+
  ${NC}\n"

  echo -e "${ORANGE}
  \t+------------------------------------------------+
  \t+------------------------------------------------+
  ${NC}"
}

doUpdate(){
  echo -e "${GREEN}
  \t+------------------------------------------------+
  \t+       UPDATING TO LATEST    
  \t+------------------------------------------------+
  ${NC}"
  git pull
}

createRpc(){
  task1
  task2
  task3
  task4
  task5
  task6
  task7
  i=$((totalValidator + 1))
  while [[ $i -le $totalNodes ]]; do
    read -p "Enter Virtual Host(example: rpc.yourdomain.tld) without https/http: " vhost
    echo -e "\nVHOST=$vhost" >> ./.env
    ./node_src/build/bin/geth --datadir ./chaindata/node$i init ./genesis.json
    ((i += 1))
  done

}

createValidator(){
  if [[ $totalValidator -gt 0 ]]; then
      task8
  fi
   i=1
  while [[ $i -le $totalValidator ]]; do
    ./node_src/build/bin/geth --datadir ./chaindata/node$i init ./genesis.json
    ((i += 1))
  done
}

# get external IP of this server
fetchNsetIP(){
  echo -e "\nIP=$(curl http://checkip.amazonaws.com)" >> ./.env
}

install_nvm() {
  # Check if nvm is installed
  if ! command -v nvm &> /dev/null; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

    # Source NVM scripts for the current session
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

    # Add NVM initialization to shell startup file
    if [ -n "$BASH_VERSION" ]; then
      SHELL_PROFILE="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
      SHELL_PROFILE="$HOME/.zshrc"
    fi

    if ! grep -q 'export NVM_DIR="$HOME/.nvm"' "$SHELL_PROFILE"; then
      echo 'export NVM_DIR="$HOME/.nvm"' >> "$SHELL_PROFILE"
      echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$SHELL_PROFILE"
      echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$SHELL_PROFILE"
    fi
  else
    echo "NVM is already installed."
  fi

  # Source NVM scripts (if not sourced already)
  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

  # Install Node.js version 21.7.1 using nvm
  echo "Installing Node.js version 21.7.1..."
  nvm install 21.7.1

  # Use the installed Node.js version
  nvm use 21.7.1

  # Verify the installation
  node_version=$(node --version)
  if [[ $node_version == v21.7.1 ]]; then
    echo "Node.js version 21.7.1 installed successfully: $node_version"
  else
    echo "There was an issue installing Node.js version 21.7.1."
  fi

  source ~/.bashrc

  npm install --global yarn
  npm install --global pm2

  source ~/.bashrc
}


finalize(){
  displayWelcome
  createRpc
  createValidator
  labelNodes

  # resource paths
  nodePath=/root/core-blockchain
  ipcPath=$nodePath/chaindata/node1/geth.ipc
  chaindataPath=$nodePath/chaindata/node1/geth
  snapshotName=$nodePath/chaindata.tar.gz

  # echo -e "\n\n\t${ORANGE}Removing existing chaindata, if any${NC}"
  
  # rm -rf $chaindataPath/chaindata

  # echo -e "\n\n\t${GREEN}Now importing the snapshot"
  # wget https://snapshots.evolveblockchain.io/chaindata.tar.gz

  # # Create the directory if it does not exist
  # if [ ! -d "$chaindataPath" ]; then
  #   mkdir -p $chaindataPath
  # fi

  # # Extract archive to the correct directory
  # tar -xvf $snapshotName -C $chaindataPath --strip-components=1

  # Set proper permissions
  echo -e "\n\n\t${GREEN}Setting directory permissions${NC}"
  chown -R root:root /root/core-blockchain/chaindata
  chmod -R 755 /root/core-blockchain/chaindata

  echo -e "\n\n\tImport is done, now configuring sync-helper${NC}"
  sleep 3
  cd $nodePath
  

  install_nvm
  cd plugins/sync-helper
  yarn
  cd ../../


  displayStatus
}


#########################################################################

#+-----------------------------------------------------------------------------------------------+
#|                                                                                                                             |
#|                                                                                                                             |
#|                                                      UTILITY                                                        |
#|                                                                                                                             |
#|                                                                                                                             |
#+-----------------------------------------------------------------------------------------------+


# Default variable values
verbose_mode=false
output_file=""

# Function to display script usage
usage() {
  echo -e "\nUsage: $0 [OPTIONS]"
  echo "Options:"
  echo -e "\t\t -h, --help      Display this help message"
  echo -e " \t\t -v, --verbose   Enable verbose mode"
  echo -e "\t\t --rpc      Specify to create RPC node"
  echo -e "\t\t --validator  <whole number>     Specify number of validator node to create"
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
      totalRpc=1
      totalNodes=$(($totalRpc + $totalValidator))
      ;;

    # take validator count
    --validator*)
      if ! has_argument $@; then
        echo "No number given" >&2
        usage
        exit 1
      fi
      totalValidator=$(extract_argument $@)
      totalNodes=$(($totalRpc + $totalValidator))
      shift
      ;;

      # check for update and do update
      --update)
      doUpdate
      exit 0
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


# bootstraping
finalize
