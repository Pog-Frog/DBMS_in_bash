#!/bin/bash

HOME_DIR="$HOME/bash_dbms"
DB_DIR="$HOME_DIR/dbs"

RED="\e[31m" 
GREEN="\e[32m" 
YELLOW="\e[33m" 
BLUE="\e[34m" 
RESET="\e[0m"

insert_into_table() {
    local current_db="$1"

    table_list=$(ls -1 "$DB_DIR/$current_db")
    if [ -z "$table_list" ]; then
        yad --info --text="No tables found in database '$current_db'" --center --width=400 --height=100 --button="OK"
        return
    fi

    table_to_insert=$(echo "$table_list" | yad --list --title="Insert into Table - $current_db" --column="Tables" --center --width=400 --height=200 --button="Insert:0" --button="Cancel:1" --print-column=1 --separator="")

    if [ $? -eq 1 ]; then
        yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi

    if [ -z "$table_to_insert" ]; then
        yad --info --text="No table selected" --center --width=400 --height=100 --button="OK"
        return
    fi

    column_definitions=$(head -n 1 "$DB_DIR/$current_db/$table_to_insert")

    column_names=""
    IFS=',' read -ra columns <<< "$column_definitions"
    for col in "${columns[@]}"; do
        column_name=$(echo $col | awk '{print $1}')
        column_names+="$column_name "
    done

    form_fields=""
    for col_name in $column_names; do
        form_fields+="--field=$col_name: "
    done

    data=$(yad --form --title="Insert Data into $table_to_insert" --center --width=400 --height=300 $form_fields)

    if [ $? -eq 1 ]; then
        yad --info --text="Data insertion cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi

    formatted_data=$(echo $data | tr '|' ',')

    echo $formatted_data

    echo "$formatted_data" >> "$DB_DIR/$current_db/$table_to_insert"
    yad --info --text="Data inserted into table '$table_to_insert' successfully" --center --width=400 --height=100 --button="OK"
}

drop_table() {
    local current_db="$1"

    table_list=$(ls -1 "$DB_DIR/$current_db")
    if [ -z "$table_list" ]; then
        yad --info --text="No tables found in database '$current_db'" --center --width=400 --height=100 --button="OK"
        return
    fi

    table_to_drop=$(echo "$table_list" | yad --list --title="Drop Table - $current_db" --column="Tables" --center --width=400 --height=200 --button="Cancel:1" --button="Drop:0" --print-column=1 --separator="")

    if [ $? -eq 1 ]; then
        yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi

    if [ -z "$table_to_drop" ]; then
        yad --info --text="No table selected" --center --width=400 --height=100 --button="OK"
        return
    fi

    rm -f "$DB_DIR/$current_db/$table_to_drop"
    yad --info --text="Table '$table_to_drop' dropped successfully from database '$current_db'" --center --width=400 --height=100 --button="OK"
}

show_tables() {
    local current_db="$1"

    if [ -d "$DB_DIR/$current_db" ]; then
        table_list=$(ls -1 "$DB_DIR/$current_db")
        if [ -z "$table_list" ]; then
            yad --info --text="No tables found in database '$current_db'" --center --width=400 --height=100 --button="OK"
        else
            yad --list --title="Tables in Database - $current_db" --column="Tables" --center --width=400 --height=200 --button="OK" <<< "$table_list"
        fi
    else
        yad --error --text="Database '$current_db' does not exist" --center --width=400 --height=100
    fi
}

create_table() {
    local current_db="$1"

    table_name=$(yad --entry --title="Create Table - $current_db" --text="Enter the table name (no spaces or special characters):" --center --width=400 --height=100)
    if [[ -z "$table_name" || "$table_name" =~ [^a-zA-Z0-9_] ]]; then
        yad --error --text="Invalid table name. Only alphanumeric characters and underscores are allowed." --center --width=400 --height=100
        return
    fi

    num_columns=$(yad --entry --title="Number of Columns" --text="Enter the number of columns:" --center --width=400 --height=100)
    if ! [[ "$num_columns" =~ ^[0-9]+$ ]]; then
        yad --error --text="Invalid number of columns" --center --width=400 --height=100
        return
    fi

    column_definitions=""
    for (( i=1; i<=num_columns; i++ )); do
        column_info=$(yad --form --title="Column Definition $i" --text="Enter details for column $i (no spaces or special characters in names):" --center --width=400 --height=200 \
            --field="Column Name" "" \
            --field="Data Type:CB" "INT!VARCHAR!DATE" "")
        
        if [ $? -eq 1 ]; then
            yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
            return
        fi

        column_name=$(echo $column_info | awk -F'|' '{print $1}')
        column_type=$(echo $column_info | awk -F'|' '{print $2}')
        
        if [[ -z "$column_name" || "$column_name" =~ [^a-zA-Z0-9_] || -z "$column_type" ]]; then
            yad --error --text="Invalid column definition. Only alphanumeric characters and underscores are allowed for column names." --center --width=400 --height=100
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
            "Show Tables") show_tables "$current_db" ;;
            "Create Table") create_table "$current_db" ;;
            "Drop Table") drop_table "$current_db" ;;
            "Insert into Table") insert_into_table "$current_db" ;;
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
