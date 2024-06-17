#!/bin/bash

GITHUB_USER="tosin2013"

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
    if [ -f "venv/bin/activate" ]; then
        echo "venv/bin/activate exists. Sourcing it..."
        source venv/bin/activate
        
    else
        echo "venv/bin/activate does not exist. Creating it..."
        python3 -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt
        playwright install
        python3 -m playwright install-deps
    fi
}

# Function to handle front-end
handle_front_end() {
    cd ui/
    npm install
    npm run build
    npm run preview &
}

install_dependancies(){
    sudo apt update
    sudo apt install python3.12 python3.12-venv
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
    node -v
    npm -v
}

# Main function
main() {
    clone_or_pull
    install_dependancies 
    create_or_source_venv
    handle_front_end
    cd ..
    source venv/bin/activate
    python devika.py &
    wait
}

main
