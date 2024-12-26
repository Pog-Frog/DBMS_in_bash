# Bash DBMS

This is a simple Database Management System (DBMS) implemented in Bash. It allows you to create, manage, and interact with databases and tables using a graphical user interface (GUI) provided by `yad`.

## Features

- Create and drop databases
- Create and drop tables
- Insert, update, delete, and select records in tables
- Display tables and records

## Prerequisites

- Bash
- `yad` (Yet Another Dialog)

## Setup

1. Clone the repository or copy the `dbms.sh` script to your local machine.
2. Ensure `yad` is installed on your system. You can install it using your package manager. For example, on Debian-based systems, you can use:

    ```sh
    sudo apt-get install yad
    ```

## Usage

1. Make the script executable:
    ```sh
    chmod +x dbms.sh
    ```

2. Run the script:
    ```sh
    ./dbms.sh
    ```

3. Follow the on-screen prompts to interact with the DBMS.

## Functions

### Main Menu

- **Create Database**: Create a new database.
- **List Databases**: List all existing databases.
- **Connect To Database**: Connect to an existing database to perform operations on it.
- **Drop Database**: Delete an existing database.
- **Exit**: Exit the DBMS.

### Database Menu

- **Show Tables**: Display all tables in the connected database.
- **Create Table**: Create a new table in the connected database.
- **Drop Table**: Delete a table from the connected database.
- **Insert into Table**: Insert a new record into a table.
- **Select from Table**: Select and display records from a table.
- **Delete from Table**: Delete records from a table.
- **Update Table**: Update records in a table.
- **BACK**: Return to the main menu.

## Notes

- The primary key must be unique for each record in a table.
- Column names must be alphanumeric and can include underscores.
- Supported data types for columns are `INT`, `VARCHARA`, and `DATE`.
- The script uses a simple file-based storage system to store databases and tables.
- The script uses `yad` for the GUI, so ensure it is installed and working properly.
