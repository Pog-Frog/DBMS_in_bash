#!/bin/bash

HOME_DIR="$HOME/bash_dbms"
DB_DIR="$HOME_DIR/dbs"

RED="\e[31m" 
GREEN="\e[32m" 
YELLOW="\e[33m" 
BLUE="\e[34m" 
RESET="\e[0m"

update_table() {
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

    #removing the primary key from the column definitions
    column_definitions=$(echo "$column_definitions" | sed "s/PRIMARY_KEY($primary_key)//g")
    echo -e "Column definitions: $column_definitions" #TODO: remove

    column_names=""
    IFS=',' read -ra columns <<< "$column_definitions"
    for col in "${columns[@]}"; do
        column_name=$(echo $col | awk '{print $1}')
        column_names+="$column_name "
    done

    form_fields=""
    if [ -z "$primary_key" ]; then
        yad --error --text="Corrupted table definition: Primary key not found  '$table_to_insert'" --center --width=400 --height=100 --button="OK"
        return
    fi

    column_names="$primary_key $column_names"
    for col_name in $column_names; do
        form_fields+="--field=$col_name: "
    done

    data=$(yad --form --title="Select Data from $table_to_select" --center --width=400 --height=300 $form_fields)

    if [ $? -eq 1 ]; then
        yad --info --text="Data selection cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi
    echo -e "Data: $data" #TODO: remove

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

    #searching the table for the filled fields and display the results
    search_results=""
    while IFS= read -r line; do
        line_data=$(echo $line | tr ' ' '|')
        match=true
        for idx in "${filled_fields_indexes[@]}"; do
            field_value=$(echo $line_data | cut -d'|' -f$idx)
            if [[ ! " ${filled_data_fields[@]} " =~ " ${field_value} " ]]; then
                match=false
                break
            fi
        done
        if $match; then
            search_results+="$line_data\n"
        fi
    done < <(tail -n +2 "$DB_DIR/$current_db/$table_to_select")
    search_results=$(echo -e "$search_results") #to remove the trailing newline
    search_results=$(echo "$search_results" | sed 's/|/ /g')
    echo -e "search_results: $search_results" #TODO: remove

    if [ -z "$search_results" ]; then
        yad --info --text="No matching records found in table '$table_to_select'" --center --width=600 --height=100 --button="OK"
    else
        # yad --list --title="Search results from $table_to_select" --column="$column_names" --center --width=400 --height=200 --button="OK" <<< "$search_results"
        #display the results to the user and make him choose which of them to update he can select multiple records

        parsed_results=()
        while IFS= read -r line; do
            parsed_results+=("FALSE" "$line")
        done <<< "$search_results"
        echo -e "Parsed results: ${parsed_results[@]}" #TODO: remove

        selected_records=$(yad --list --checklist --width=400 --height=200 --center --title="Search results from $table_to_select" --button="Update:0" --button="Cancel:1" --column=Select:chk --column=Results:text "${parsed_results[@]}")
        if [ $? -eq 1 ]; then
            yad --info --text="Data update cancelled" --center --width=400 --height=100 --button="OK"
            return
        fi
        if [ -z "$selected_records" ]; then
            yad --info --text="No records selected for update" --center --width=400 --height=100 --button="OK"
            return
        fi
        echo -e "Selected records: $selected_records" #TODO: remove

        # Mark the line number of each selected record , ex of selected record: TRUE|12 ahmed ahmed@gmail.com| , this is what we want: "12 ahmed ahmed@gmail.com"
        selected_records=$(echo "$selected_records" | awk -F'|' '{print $2}')
        echo -e "Selected records: $selected_records" #TODO: remove

        selected_records_lines=()
        while IFS= read -r line; do
            line_number=$(awk -v record="$line" '{if ($0 == record) print NR}' "$DB_DIR/$current_db/$table_to_select")
            selected_records_lines+=($line_number)
        done <<< "$selected_records"
        
        i=0
        while IFS= read -r line; do
            line_number=${selected_records_lines[$i]}
            #remove the line from the table
            sed -i "/$line/d" "$DB_DIR/$current_db/$table_to_select"

            form_fields=""
            idx=1
            for col_name in $column_names; do
                form_fields+="--field=$col_name: $(echo $line | cut -d' ' -f$idx) "
                idx=$((idx + 1))
            done

            updated_data=$(yad --form --title="Update Data in $table_to_select" --center --width=400 --height=300 $form_fields)
            if [ $? -eq 1 ]; then
                yad --info --text="Data update cancelled" --center --width=400 --height=100 --button="OK"
                return
            fi
            echo -e "Updated data: $updated_data" #TODO: remove
            formatted_data=$(echo $updated_data | tr '|' ' ')
            echo -e "Formatted updated data: $formatted_data" #TODO: remove

            primary_key_index=1
            primary_key_value=$(echo $formatted_data | awk -v idx=$primary_key_index '{print $1}')

            #check if the primary key value already exists
            if [ -n "$primary_key_value" ]; then
                primary_key_exists=$(awk -v idx=$primary_key_index -v pk=$primary_key_value '{if ($idx == pk) print $0}' "$DB_DIR/$current_db/$table_to_select")
                if [ -n "$primary_key_exists" ]; then
                    yad --error --text="Error!!, Primary key value '$primary_key_value' already exists in table '$table_to_select'" --center --width=400 --height=100 --button="OK"
                    #reinsert the deleted line
                    echo "$line" >> "$DB_DIR/$current_db/$table_to_select"
                    return
                fi
            fi

            echo "$formatted_data" >> "$DB_DIR/$current_db/$table_to_select"

            ((i++))
        done <<< "$selected_records"

        yad --info --text="Records updated successfully" --center --width=400 --height=100 --button="OK"
    fi
}

delete_from_table() {
    local current_db="$1"

    table_list=$(ls -1 "$DB_DIR/$current_db")
    if [ -z "$table_list" ]; then
        yad --info --text="No tables found in database '$current_db'" --center --width=400 --height=100 --button="OK"
        return
    fi

    table_to_delete_from=$(echo "$table_list" | yad --list --title="Delete from Table - $current_db" --column="Tables" --center --width=400 --height=200 --button="Delete:0" --button="Cancel:1" --print-column=1 --separator="")
    if [ $? -eq 1 ]; then
        yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi
    if [ -z "$table_to_delete_from" ]; then
        yad --info --text="No table selected" --center --width=400 --height=100 --button="OK"
        return
    fi

    column_definitions=$(head -n 1 "$DB_DIR/$current_db/$table_to_delete_from")
    primary_key=$(echo "$column_definitions" | grep -oP 'PRIMARY_KEY\(\K[^)]+')
    echo -e "Primary key: $primary_key" #TODO: remove

    #remove the primary key from the column definitions
    column_definitions=$(echo "$column_definitions" | sed "s/PRIMARY_KEY($primary_key)//g")
    echo -e "Column definitions: $column_definitions" #TODO: remove

    column_names=""
    IFS=',' read -ra columns <<< "$column_definitions"
    for col in "${columns[@]}"; do
        column_name=$(echo $col | awk '{print $1}')
        column_names+="$column_name "
    done

    form_fields=""
    if [ -z "$primary_key" ]; then
        yad --error --text="Corrupted table definition: Primary key not found  '$table_to_insert'" --center --width=400 --height=100 --button="OK"
        return
    fi

    column_names="$primary_key $column_names"
    for col_name in $column_names; do
        form_fields+="--field=$col_name: "
    done

    data=$(yad --form --title="Delete Data from $table_to_delete_from" --center --width=400 --height=300 $form_fields)
    if [ $? -eq 1 ]; then
        yad --info --text="Data deletion cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi

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

    #search the table for the filled fields and display the results to confirm before deletion, caution: each line can contain multiple field and display them all
    results=""
    while IFS= read -r line; do
        line_data=$(echo $line | tr ' ' '|')
        match=true
        for idx in "${filled_fields_indexes[@]}"; do
            field_value=$(echo $line_data | cut -d'|' -f$idx)
            if [[ ! " ${filled_data_fields[@]} " =~ " ${field_value} " ]]; then
                match=false
                break
            fi
        done
        if $match; then
            results+="$line_data\n"
        fi
    done < <(tail -n +2 "$DB_DIR/$current_db/$table_to_delete_from")
    results=$(echo -e "$results") #to remove the trailing newline
    results=$(echo "$results" | sed 's/|/ /g')
    echo -e "Results: $results" #TODO: remove

    #if results found then show them to the user to confirm before deletion if the user confirms then delete each record from the table
    if [ -z "$results" ]; then
        yad --info --text="No matching records found in table '$table_to_delete_from'" --center --width=600 --height=100 --button="OK"
    else
        yad --list --title="Results from $table_to_delete_from" --column="$column_names" --center --width=400 --height=200 --button="Delete:0" --button="Cancel:1" <<< "$results"
        if [ $? -eq 0 ]; then
            while IFS= read -r line; do
                line_data=$(echo $line | tr ' ' '|')
                for result in $results; do
                    if [[ "$line_data" == *"$result"* ]]; then
                        sed -i "/$line/d" "$DB_DIR/$current_db/$table_to_delete_from"
                    fi
                done
            done < "$DB_DIR/$current_db/$table_to_delete_from"
            yad --info --text="Data deleted from table '$table_to_delete_from' successfully" --center --width=400 --height=100 --button="OK"
        else
            yad --info --text="Data deletion cancelled" --center --width=400 --height=100 --button="OK"
        fi
    fi
}

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
    IFS=',' read -ra columns <<< "$column_definitions"
    for col in "${columns[@]}"; do
        column_name=$(echo $col | awk '{print $1}')
        column_names+="$column_name "
    done

    form_fields=""
    if [ -z "$primary_key" ]; then
        yad --error --text="Corrupted table definition: Primary key not found  '$table_to_insert'" --center --width=400 --height=100 --button="OK"
        return
    fi

    column_names="$primary_key $column_names"
    for col_name in $column_names; do
        form_fields+="--field=$col_name: "
    done

    data=$(yad --form --title="Select Data from $table_to_select" --center --width=400 --height=300 $form_fields)

    if [ $? -eq 1 ]; then
        yad --info --text="Data selection cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi
    echo -e "Data: $data" #TODO: remove

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
        match=true
        for idx in "${filled_fields_indexes[@]}"; do
            field_value=$(echo $line_data | cut -d'|' -f$idx)
            if [[ ! " ${filled_data_fields[@]} " =~ " ${field_value} " ]]; then
                match=false
                break
            fi
        done
        if $match; then
            results+="$line_data\n"
        fi
    done < <(tail -n +2 "$DB_DIR/$current_db/$table_to_select")
    results=$(echo -e "$results") #to remove the trailing newline
    results=$(echo "$results" | sed 's/|/ /g')
    echo -e "Results: $results" #TODO: remove

    if [ -z "$results" ]; then
        yad --info --text="No matching records found in table '$table_to_select'" --center --width=600 --height=100 --button="OK"
    else
        yad --list --title="Results from $table_to_select" --column="$column_names" --center --width=400 --height=200 --button="OK" <<< "$results"
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
    IFS=',' read -ra columns <<< "$column_definitions"
    for col in "${columns[@]}"; do
        column_name=$(echo $col | awk '{print $1}')
        column_names+="$column_name "
    done
    
    form_fields=""
    if [ -z "$primary_key" ]; then
        yad --error --text="Corrupted table definition: Primary key not found  '$table_to_insert'" --center --width=400 --height=100 --button="OK"
        return
    fi

    column_names="$primary_key $column_names"
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
    primary_key_index=1
    primary_key_value=$(echo $formatted_data | awk -v idx=$primary_key_index '{print $1}')
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
    primary_key_info=$(yad --form --title="Primary Key" --text="Enter the primary key column name:" --center --width=400 --height=100 \
        --field="Primary Key" "" --field="Data Type:CB" "INT!VARCHAR!DATE" "")
    if [ $? -eq 1 ]; then
        yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi
    primary_key=$(echo $primary_key_info | awk -F'|' '{print $1}')
    primary_key_type=$(echo $primary_key_info | awk -F'|' '{print $2}')
    if [[ -z "$primary_key" || "$primary_key" =~ [^a-zA-Z0-9_] || -z "$primary_key_type" ]]; then
        yad --error --text="Invalid primary key definition. Only alphanumeric characters and underscores are allowed for column names." --center --width=400 --height=100
        return
    fi 


    column_definitions=""
    for (( i=1; i<num_columns; i++ )); do
        column_info=$(yad --form --title="Column Definition $((i+1))" --text="Enter details for column $((i+1)) (no spaces or special characters in names):" --center --width=500 --height=200 \
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

        #the column name should not be the same as the primary key or be repeated at all
        if [ "$column_name" == "$primary_key" ]; then
            yad --error --text="Column names cannot repeat" --center --width=400 --height=100
            return
        fi
        if [[ "$column_definitions" == *"$column_name"* ]]; then
            yad --error --text="Column name '$column_name' already exists" --center --width=400 --height=100
            return
        fi

        column_definitions+="$column_name $column_type,"
    done
    column_definitions=${column_definitions%,}

    touch "$DB_DIR/$current_db/$table_name"
    echo "PRIMARY_KEY($primary_key),$column_definitions" > "$DB_DIR/$current_db/$table_name"
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
            FALSE "Update Table" \
            FALSE "BACK")

        if [ $? -ne 0 ]; then
            yad --info --text="Returning to the main menu..." --center --width=400 --height=100 --timeout=1 --button="OK"
            break
        fi

        choice=$(echo $choice | awk -F'|' '{print $2}')

        case $choice in
            "Show Tables") show_tables "$current_db" ;;
            "Create Table") create_table "$current_db" ;;
            "Drop Table") drop_table "$current_db" ;;
            "Insert into Table") insert_into_table "$current_db" ;;
            "Select from Table") select_from_table "$current_db" ;;
            "Delete from Table") delete_from_table "$current_db" ;;
            "Update Table") update_table "$current_db" ;;
            "BACK") yad --info --text="Exiting database '$current_db'" --center --width=400 --height=100 --timeout=1 --button="OK"; break ;;
            *) yad --error --text="Invalid option, please try again" --center --width=400 --height=100 ;;
        esac
    done
}

connect_db() {
    db_list=$(ls -1 "$DB_DIR")
    if [ -z "$db_list" ]; then
        yad --info --text="No databases found" --center --width=400 --height=100 --button="OK"
        return
    fi

    db_name=$(echo "$db_list" | yad --list --title="Connect To Database" --column="Databases" --center --width=400 --height=200 --button="Connect:0" --button="Cancel:1" --print-column=1 --separator="")
    if [ $? -eq 1 ]; then
        yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi
    if [ -z "$db_name" ]; then
        yad --info --text="No database selected" --center --width=400 --height=100 --button="OK"
        return
    fi

    yad --info --text="Connected to database '$db_name'" --center --width=400 --height=100 --button="OK"
    db_loop "$db_name"
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
    yad --list --title="List Databases" --column="Databases" --center --width=400 --height=200 --button="ok" <<< "$db_list"
}

drop_db() {
    db_list=$(ls -1 "$DB_DIR")
    if [ -z "$db_list" ]; then
        yad --info --text="No databases found" --center --width=400 --height=100 --button="OK"
        return
    fi

    db_name=$(echo "$db_list" | yad --list --title="Drop Database" --column="Databases" --center --width=400 --height=200 --button="Drop:0" --button="Cancel:1" --print-column=1 --separator="")

    if [ $? -eq 1 ]; then
        yad --info --text="Operation cancelled" --center --width=400 --height=100 --button="OK"
        return
    fi

    if [ -z "$db_name" ]; then
        yad --info --text="No database selected" --center --width=400 --height=100 --button="OK"
        return
    fi

    rm -rf "$DB_DIR/$db_name"
    yad --info --text="Database '$db_name' dropped successfully" --center --width=400 --height=100 --button="OK"
}

dbms_loop() {
    while true; do
        choice=$(yad --list --title="Main Menu" --on-top --width=400 --height=300 --center --radiolist --column="Choice" --column="Action" \
            TRUE "Create Database" \
            FALSE "List Databases" \
            FALSE "Connect To Database" \
            FALSE "Drop Database" \
            FALSE "Exit")

        if [ $? -ne 0 ]; then
            yad --info --text="Exiting..." --center --width=400 --height=100 --timeout=1 --button="OK"
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
