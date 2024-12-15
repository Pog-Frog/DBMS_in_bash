#!/bin/bash

HOME_DIR="$HOME/bash_dbms"
DB_DIR="$HOME_DIR/dbs"

RED="\e[31m" 
GREEN="\e[32m" 
YELLOW="\e[33m" 
BLUE="\e[34m" 
RESET="\e[0m"


select_from_table() {
    local current_db="$1"

    table_list=$(ls -1 "$DB_DIR/$current_db")
    if [ -z "$table_list" ]; then
        yad --info --text="No tables found in database '$current_db'" --center --width=400 --height=100 --button="OK"
        return
    fi

    table_to_select=$(echo "$table_list" | yad --list --title="Select from Table - $current_db" --column="Tables" --center --width=400 --height=200 --button="Select:0" --button="Cancel:1" --print-column=1 --separator="")

    if [ $? -eq 1 ]; then
        yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi

    if [ -z "$table_to_select" ]; then
        yad --info --text="No table selected" --center --width=400 --height=100 --button="OK"
        return
    fi

    column_definitions=$(head -n 1 "$DB_DIR/$current_db/$table_to_select")
    primary_key=$(echo "$column_definitions" | grep -oP 'PRIMARY_KEY\(\K[^)]+')
    echo -e "Primary key: $primary_key" #TODO: remove

    #remove the primary key from the column definitions
    column_definitions=$(echo "$column_definitions" | sed "s/PRIMARY_KEY($primary_key)//g")
    echo -e "Column definitions: $column_definitions" #TODO: remove

    column_names=""
    column_count=1
    primary_key_index=-1
    IFS=',' read -ra columns <<< "$column_definitions"
    for col in "${columns[@]}"; do
        column_name=$(echo $col | awk '{print $1}')
        if [ "$column_name" == "$primary_key" ]; then
            echo -e "Primary key found , column name: $column_name, primary key: $primary_key, index: $column_count" #TODO: remove
            primary_key_index=$column_count
        fi
        column_names+="$column_name "
        ((column_count++))
    done

    form_fields=""
    for col_name in $column_names; do
        form_fields+="--field=$col_name: "
    done

    data=$(yad --form --title="Select Data from $table_to_select" --center --width=400 --height=300 $form_fields)

    if [ $? -eq 1 ]; then
        yad --info --text="Data selection cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi
    echo -e "Data: $data" #TODO: remove

    # formatted_data=$(echo $data | tr '|' ' ')
    # echo -e "Formatted data: $formatted_data" #TODO: remove

    #know which of the columns are filled by the user, here 12|| this means there were 2 fields in the data the 2nd one was empty, so we need to know which of the fields are filled and there index so that we can search for them in the table and need to make an array of there indexes
    IFS='|' read -ra data_fields <<< "$data"
    filled_fields_indexes=()
    for i in "${!data_fields[@]}"; do
        if [ -n "${data_fields[$i]}" ]; then
            filled_fields_indexes+=($((i + 1)))
        fi
    done
    echo -e "Filled fields indexes: ${filled_fields_indexes[@]}" #TODO: remove

    #get the filled data fields 
    filled_data_fields=()
    for i in "${filled_fields_indexes[@]}"; do
        filled_data_fields+=("${data_fields[$((i - 1))]}")
    done
    echo -e "Filled data fields: ${filled_data_fields[@]}" #TODO: remove

    #search the table for the filled fields and display the results, caution: each line can contain multiple field and display them all
    results=""
    while IFS= read -r line; do
        line_data=$(echo $line | tr ' ' '|')
        for field in "${filled_data_fields[@]}"; do
            if [[ "$line_data" == *"$field"* ]]; then
                results+="$line_data\n"
            fi
        done
    done < "$DB_DIR/$current_db/$table_to_select"
    results=$(echo -e "$results") #to remove the trailing newline
    results=$(echo "$results" | sed 's/,/ /g')
    echo -e "Results: $results" #TODO: remove

    if [ -z "$results" ]; then
        yad --info --text="No matching records found in table '$table_to_select'" --center --width=600 --height=100 --button="OK"
    else
        yad --list --title="Results from $table_to_select" --column="$column_names" --center --width=400 --height=200 <<< "$results"
    fi
}

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
    primary_key=$(echo "$column_definitions" | grep -oP 'PRIMARY_KEY\(\K[^)]+')
    echo -e "Primary key: $primary_key" #TODO: remove 
    echo -e "Column definitions (with primary): $column_definitions" #TODO: remove 

    #remove the primary key from the column definitions
    column_definitions=$(echo "$column_definitions" | sed "s/PRIMARY_KEY($primary_key)//g")
    echo -e "Column definitions: $column_definitions" #TODO: remove

    column_names=""
    primary_key_index=-1
    column_count=1
    IFS=',' read -ra columns <<< "$column_definitions"
    for col in "${columns[@]}"; do
        column_name=$(echo $col | awk '{print $1}')
        if [ "$column_name" == "$primary_key" ]; then
            echo -e "Primary key found , column name: $column_name, primary key: $primary_key, index: $column_count" #TODO: remove
            primary_key_index=$column_count
        fi
        column_names+="$column_name "
        ((column_count++))
    done
    echo -e "Primary key index: $primary_key_index" #TODO: remove

    form_fields=""
    for col_name in $column_names; do
        form_fields+="--field=$col_name: "
    done

    data=$(yad --form --title="Insert Data into $table_to_insert" --center --width=400 --height=300 $form_fields)

    if [ $? -eq 1 ]; then
        yad --info --text="Data insertion cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi
    echo -e "Data: $data" #TODO: remove

    formatted_data=$(echo $data | tr '|' ' ')
    echo -e "Formatted data: $formatted_data" #TODO: remove

    #get the primary key value
    primary_key_value=$(echo $formatted_data | awk -v idx=$primary_key_index '{print $idx}')
    echo -e "Primary key value: $primary_key_value" #TODO: remove

    #check if the primary key value already exists
    if [ -n "$primary_key_value" ]; then
        primary_key_exists=$(awk -v idx=$primary_key_index -v pk=$primary_key_value '{if ($idx == pk) print $0}' "$DB_DIR/$current_db/$table_to_insert")
        if [ -n "$primary_key_exists" ]; then
            yad --error --text="Error!!, Primary key value '$primary_key_value' already exists in table '$table_to_insert'" --center --width=400 --height=100 --button="OK"
            return
        fi
    fi

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
    if [ $? -eq 1 ]; then
        yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi
    if [[ -z "$table_name" || "$table_name" =~ [^a-zA-Z0-9_] ]]; then
        yad --error --text="Invalid table name. Only alphanumeric characters and underscores are allowed." --center --width=400 --height=100
        return
    fi
    if [ -f "$DB_DIR/$current_db/$table_name" ]; then
        yad --error --text="Table '$table_name' already exists in database '$current_db'" --center --width=400 --height=100 --button="OK"
        return
    fi

    num_columns=$(yad --entry --title="Number of Columns" --text="Enter the number of columns (including the primary key):" --center --width=400 --height=100)
    if [ $? -eq 1 ]; then
        yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi
    if ! [[ "$num_columns" =~ ^[0-9]+$ || "$num_columns" -lt 1 ]]; then
        yad --error --text="Invalid number of columns" --center --width=400 --height=100
        return
    fi

    #primary
    primary_key=$(yad --entry --title="Primary Key" --text="Enter the primary key column name:" --center --width=400 --height=100)
    if [ $? -eq 1 ]; then
        yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi
    if [[ -z "$primary_key" || "$primary_key" =~ [^a-zA-Z0-9_] ]]; then
        yad --error --text="Invalid primary key. The primary key must be specified." --center --width=400 --height=100
        return
    fi

    column_definitions=""
    primary_key_valid=false
    for (( i=1; i<=num_columns; i++ )); do
        column_info=$(yad --form --title="Column Definition $i" --text="Enter details for column $i (no spaces or special characters in names):" --center --width=500 --height=200 \
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
        if [[ "$column_name" == "$primary_key" ]]; then
            primary_key_valid=true
        fi
    done
    column_definitions=${column_definitions%,}

    if ! $primary_key_valid; then
        yad --error --text="Creation failed!,  the primary key must be one of the defined columns." --center --width=400 --height=100
        return
    fi

    touch "$DB_DIR/$current_db/$table_name"
    echo "$column_definitions,PRIMARY_KEY($primary_key)" > "$DB_DIR/$current_db/$table_name"
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
            "Select from Table") select_from_table "$current_db" ;;
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
