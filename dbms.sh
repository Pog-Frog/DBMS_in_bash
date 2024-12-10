#!/bin/bash

HOME_DIR="$HOME/bash_dbms"
DB_DIR="$HOME_DIR/dbs"

RED="\e[31m" 
GREEN="\e[32m" 
YELLOW="\e[33m" 
BLUE="\e[34m" 
RESET="\e[0m"

db_loop() {
    local db_name="$1"
    while true; do
        choice=$(yad --list --title="Database Menu - $db_name" --on-top --width=400 --height=300 --center --radiolist --column="Choice" --column="Action" \
            TRUE "Show Tables" \
            FALSE "Create Table" \
            FALSE "Drop Table" \
            FALSE "Insert into Table" \
            FALSE "Select from Table" \
            FALSE "Delete from Table" \
            FALSE "Exit")

        if [ $? -eq 1 ]; then
            yad --info --text="Returning to the main menu..." --center --width=400 --height=100 --button="OK"
            break
        fi

        choice=$(echo $choice | awk -F'|' '{print $2}')

        case $choice in
            "Exit") yad --info --text="Exiting database '$db_name'" --center --width=400 --height=100 ; break ;;
            *) yad --error --text="Invalid option, please try again" --center --width=400 --height=100 ;;
        esac
    done
}

connect_db() {
    db_name=""

    while true; do
        db_name=$(yad --entry --title="Connect To Database" --text="Enter the database name to connect to:" --center --width=400 --height=100)
        
        if [ -z "$db_name" ]; then
            yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="Ok"
            break
        elif [ -d "$DB_DIR/$db_name" ]; then
            yad --info --text="Connected to database '$db_name'" --center --width=400 --height=100 --button="Ok"
            db_loop "$db_name"
            break
        else
            yad --error --text="Database '$db_name' does not exist" --center --width=400 --height=100
        fi
    done
}

create_db() {
    db_name=""

    while true; do
        db_name=$(yad --entry --title="Create Database" --text="Enter the database name:" --center --width=400 --height=100)

        if [ -z "$db_name" ]; then
            yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="Ok"
            break
        elif [ -d "$DB_DIR/$db_name" ]; then
            yad --error --text="This database already exists" --center --width=400 --height=100
        else
            mkdir "$DB_DIR/$db_name"
            yad --info --text="Database '$db_name' created successfully" --center --width=400 --height=100 --button="Ok"
            break
        fi
    done
}

list_dbs() {
    db_list=$(ls -1 "$DB_DIR")
    yad --list --title="List Databases" --column="Databases" --center --width=400 --height=200 <<< "$db_list"
}

drop_db() {
    db_name=""

    while true; do
        db_name=$(yad --entry --title="Drop Database" --text="Enter the database name to drop:" --center --width=400 --height=100)

        if [ -z "$db_name" ]; then
            yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="Ok"
            break
        elif [ -d "$DB_DIR/$db_name" ]; then
            rm -rf "$DB_DIR/$db_name"
            yad --info --text="Database '$db_name' dropped successfully" --center --width=400 --height=100 --button="Ok"
            break
        else
            yad --error --text="Database '$db_name' does not exist" --center --width=400 --height=100
        fi
    done
}

dbms_loop() {
    while true; do
        choice=$(yad --list --title="Main Menu" --on-top --width=400 --height=300 --center --radiolist --column="Choice" --column="Action" \
            TRUE "Create Database" \
            FALSE "List Databases" \
            FALSE "Connect To Database" \
            FALSE "Drop Database" \
            FALSE "Exit")

        if [ $? -eq 1 ]; then
            yad --info --text="Exiting..." --center --width=400 --height=100 --timeout=1  --button="OK"
            break
        fi

        choice=$(echo $choice | awk -F'|' '{print $2}')

        case $choice in
            "Create Database") create_db ;;
            "List Databases") list_dbs ;;
            "Connect To Database") connect_db ;;
            "Drop Database") drop_db ;;
            "Exit") yad --info --text="Exiting..." --center --width=400 --height=100 ; break ;;
            *) yad --error --text="Invalid option, please try again" --center --width=400 --height=100 ;;
        esac
    done
}

setup() {
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
    clear
    setup
}

main() {
    init_dbms
    dbms_loop
}

main
