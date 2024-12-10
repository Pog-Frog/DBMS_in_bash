#!/bin/bash

HOME_DIR="$HOME/bash_dbms"
DB_DIR="$HOME_DIR/dbs"

RED="\e[31m" 
GREEN="\e[32m" 
YELLOW="\e[33m" 
BLUE="\e[34m" 
RESET="\e[0m"


create_table() {
    local current_db="$1"

    table_name=$(yad --entry --title="Create Table - $current_db" --text="Enter the table name:" --center --width=400 --height=100)
    if [ -z "$table_name" ]; then
        yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi

    num_columns=$(yad --entry --title="Number of Columns" --text="Enter the number of columns:" --center --width=400 --height=100)
    if ! [[ "$num_columns" =~ ^[0-9]+$ ]]; then
        yad --error --text="Invalid number of columns" --center --width=400 --height=100
        return
    fi

    column_definitions=""
    for (( i=1; i<=num_columns; i++ )); do
        column_info=$(yad --form --title="Column Definition $i" --text="Enter details for column $i" --center --width=400 --height=200 \
            --field="Column Name" "" \
            --field="Data Type:CB" "INT!VARCHAR!DATE" "")
        
        if [ $? -eq 1 ]; then
            yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
            return
        fi

        column_name=$(echo $column_info | awk -F'|' '{print $1}')
        column_type=$(echo $column_info | awk -F'|' '{print $2}')
        
        if [ -z "$column_name" ] || [ -z "$column_type" ]; then
            yad --error --text="Invalid column definition" --center --width=400 --height=100
            return
        fi

        column_definitions+="$column_name $column_type,"
    done
    column_definitions=${column_definitions%,}

    touch "$DB_DIR/$current_db/$table_name"
    echo "$column_definitions" > "$DB_DIR/$current_db/$table_name"
    yad --info --text="Table '$table_name' created successfully in database '$current_db'" --center --width=400 --height=100 --button="OK"
}

db_loop() {
    local current_db="$1"

    while true; do
        choice=$(yad --list --title="Database Menu - $current_db" --on-top --width=400 --height=300 --center --radiolist --column="Choice" --column="Action" \
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
            "Show Tables") ;;
            "Create Table") create_table "$current_db" ;;
            "Drop Table") ;;
            "Insert into Table") ;;
            "Select from Table") ;;
            "Delete from Table") ;;
            "Exit") yad --info --text="Exiting database '$current_db'" --center --width=400 --height=100 ; break ;;
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
