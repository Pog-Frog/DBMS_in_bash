#!/bin/bash

HOME_DIR="$HOME/bash_dbms"
DB_DIR="$HOME_DIR/dbs"

RED="\e[31m" 
GREEN="\e[32m" 
YELLOW="\e[33m" 
BLUE="\e[34m" 
RESET="\e[0m"


# create_db () {
#     db_name=""

#     while true; do
#         read -p "Enter the db name: " db_name

#         if [ -d "$DB_DIR/$db_name" ]; then
#             echo -e "${RED}This database already exists${RESET}\n"
#         else
#             mkdir "$DB_DIR/$db_name"
#             echo -e "${GREEN}Database '$db_name' created successfully${RESET}\n"
#             break
#         fi
#     done
# }

dbms_loop() {
    
}

setup() {
    clear

    echo -e "${BLUE}"
    echo "
    $(tput setaf 4)
    
        ██████╗  █████╗ ███████╗██╗  ██╗    ██████╗ ██████╗ ███╗   ███╗███████╗
        ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔══██╗██╔══██╗████╗ ████║██╔════╝
        ██████╔╝███████║███████╗███████║    ██║  ██║██████╔╝██╔████╔██║███████╗
        ██╔══██╗██╔══██║╚════██║██╔══██║    ██║  ██║██╔══██╗██║╚██╔╝██║╚════██║
        ██████╔╝██║  ██║███████║██║  ██║    ██████╔╝██████╔╝██║ ╚═╝ ██║███████║
        ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝
                                                                       

    $(tput sgr0)
    "
    echo -e "${RESET}"

    echo -e "${GREEN}Setting up the database management system...${RESET}"

    if [ ! -d "$HOME_DIR" ]; then
        mkdir -p "$HOME_DIR"
    fi

    if [ ! -d "$DB_DIR" ]; then 
        mkdir -p "$DB_DIR"
    fi

    echo -e "${GREEN}Setup completed.${RESET}\n"
}

init_dbms() {
    setup

}

main() {
    init_dbms
}

main