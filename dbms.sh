#!/bin/bash

HOME_DIR="$HOME/bash_dbms"
DB_DIR="$HOME_DIR/dbs"


create_db () {
    db_name=""

    while(true); do
        read -p "Enter the db name: " db_name

        if [ -d $db_name ];
        then
            echo -e "This database already exists\n" 
        else
            mkdir $db_name
            
}

setup() {
    if [ ! -d $HOME_DIR ]; then
        mkdir $HOME_DIR
    fi

    if [ ! -d $DB_DIR ]; then 
        mkdir $DB_DIR
    fi
}

init_dbms() {
    clear
    setup
    
}

main() {
    init_dbms
}

main