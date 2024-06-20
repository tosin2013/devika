#!/bin/bash
#export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
#set -xe

GITHUB_USER="tosin2013"
LOG_FILE_FRONTEND="devika-frontend.log"
LOG_FILE_BACKEND="devika-backend.log"
NOUP=true
RUN_APPLICATION=true
if [ ! -z $VITE_API_BASE_URL ];
then
    echo "VITE_API_BASE_URL is set to $VITE_API_BASE_URL"
else
    echo "VITE_API_BASE_URL is not set."
fi 

# Function to clone or pull repository
clone_or_pull() {
    if [ -d "devika" ]; then
        echo "devika directory exists. Performing git pull..."
        cd devika/
        git pull
    else
        echo "devika directory does not exist. Cloning repository..."
        git clone https://github.com/${GITHUB_USER}/devika.git
        cd devika/
    fi
}

# Function to create or source virtual environment
create_or_source_venv() {
    if [ -d $HOME/devika ]; then 
        cd $HOME/devika/
    fi

    if [ -d "venv" ]; then
        if [ -f "venv/bin/activate" ]; then
            echo "venv/bin/activate exists. Sourcing it..."
            source venv/bin/activate  
        else
            echo "venv/bin/activate does not exist. Creating it..."
            python3 -m venv venv
            source venv/bin/activate
            pip install  -r requirements.txt
            playwright install
            python3 -m playwright install-deps
        fi
    else
        echo "venv directory does not exist. Creating it..."
        python3 -m venv venv
        source venv/bin/activate
        pip install  -r requirements.txt # optional add timeout --timeout 1000
        playwright install
        python3 -m playwright install-deps
    fi
}

# Function to handle front-end
handle_front_end() {
    cd $HOME/devika/ui/
    npm install
    export VITE_API_BASE_URL=${VITE_API_BASE_URL}
    npm run build
}

install_dependancies(){
    # Set the frontend for automatic package installation
    export DEBIAN_FRONTEND=noninteractive
    sudo apt update && apt upgrade -y
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt update -y
    sudo apt install python3.12 python3-pip python3.10-venv -y || exit $?

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
    node -v
    npm -v
    handle_front_end
}

# Function to run devika
run_devika() {
    ls -lath ${HOME}/devika/venv/bin/activate || exit $?
    source ${HOME}/devika/venv/bin/activate
    if [ "$NOUP" = true ]; then
        cd $HOME/devika/
        nohup python devika.py > $LOG_FILE_BACKEND 2>&1 &
        cd $HOME/devika/ui/
        nohup npm run preview --host=0.0.0.0 > $LOG_FILE_FRONTEND 2>&1 &
    else
        cd $HOME/devika/
        python devika.py &
        cd $HOME/devika/ui/
        npm run preview --host=0.0.0.0 &
    fi
}

show_help() {
    echo "Usage: $0 [-n] [-i] [-r] [-h]"
    echo "Options:"
    echo "  -n   Do not update (NOUP)"
    echo "  -i   Install dependencies"
    echo "  -r   Run the application"
    echo "  -h   Show this help message"
}

# Main function
main() {
    if [ "$#" -eq 0 ]; then
        show_help
        exit 0
    fi

    while getopts ":nihr" opt; do
        case ${opt} in
            n )
                NOUP=true
                ;;
            i )
                INSTALL_DEPENDENCIES=true
                ;;
            r )
                RUN_APPLICATION=true
                ;;
            h )
                show_help
                exit 0
                ;;
            \? )
                echo "Invalid option: -$OPTARG" 1>&2
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    clone_or_pull
    if [ "$INSTALL_DEPENDENCIES" = true ]; then
        install_dependancies
        create_or_source_venv
    fi
    
    if [ "$RUN_APPLICATION" = true ]; then
        run_devika
    fi
}

main "$@"
