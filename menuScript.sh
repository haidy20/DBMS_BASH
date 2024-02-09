#!/bin/bash
#--------------------------- Function to validate Name--------------------------------------
validateByName() {
    if [ -z "$1" ]; then
        echo "Error: The name cannot be empty."
        return 1
    elif [[ "$1" =~ ^[0-9] ]]; then
        echo "Error: The name should not begin with a number."
        return 1
    elif [[ "$1" = *" "* ]]; then
        echo "Error: The name shouldn't have spaces."
        return 1
    elif [[ "$1" =~ [^a-zA-Z0-9_] ]]; then
        echo "Error: The name shouldn't have special characters."
        return 1
    fi
    return 0
}

#----------------------------Function to validate column datatype-----------------------------
#$1 -> Value
#$2 -> datatype
function validateDataType { 
    if [ -z "$1" ]
    then
        return 1
    fi

    if [[ "$1" =~ ^[1-9]+$ ]]
    then
        if [ "$2" == "integer" ]
        then
            return 0
        else
            return 1
        fi
    fi

    if [[ "$1" =~ ^[a-zA-Z0-9_]+$ ]];
    then
        if [ "$2" == "string" ]
        then
            return 0
        else
            return 1
        fi
    fi
}
#----------------------------Function to create a new database---------------------------
createDatabase() {
    read -p "Enter the Database name: " dbName
    validateByName "$dbName"
    if [ $? -eq 0 ]; then
        if [ -d "databases/$dbName" ]; then
            echo "Error: A database with the same name already exists."
        else
            mkdir "databases/$dbName"
            echo "Database '$dbName' created successfully."
        fi
    fi
}

#-----------------------------Function to list all databases-------------------------------
listDatabases() {
    echo "List of Databases:"
    if [ -z "$(ls -A databases)" ]; then
        echo "No databases found."
    else
        ls -1 databases
    fi
}

#----------------------------- Function to connect to a database----------------------------
connectToDatabase() {
    read -p "Enter the Database name to connect: " dbName
    validateByName "$dbName"
    if [ $? -eq 0 ]; then
    if [ -d "databases/$dbName" ]; then
        echo "You are connected to database: $dbName"
        cd "databases/$dbName"
        showTablesMenu
    else
        echo "Error: Database '$dbName' is not found."
    fi
 fi
}

#----------------------------- Function to drop a database-------------------------------
dropDatabase() {
    read -p "Enter the Database name to drop: " dbName
    validateByName "$dbName"
    if [ $? -eq 0 ]; then
    if [ -d "databases/$dbName" ]; then
        rm -r "databases/$dbName"
        echo "Database '$dbName' dropped successfully."
    else
        echo "Error: Database '$dbName' is not found."
    fi
 fi
}

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\Tables Functions here\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

#--------------------------------Function Create Table-------------------------------------
function createTable {
    local tableName cols num=0 nameRecord="" dataTypeRecord="" 
    read -p "Enter the table you want to create: " tableName

    validateByName "$tableName" || return 
    if [ -d "$tableName" ]; then
        echo "Table already exists."
        return
    fi
 
    touch "$PWD/${tableName}.txt" || { echo "Error: Failed to create data file."; return; }
    touch "$PWD/${tableName}-meta.txt" || { echo "Error: Failed to create meta file."; return; }
    
    while true; do
        read -p "Enter Number Of Columns: " cols
        if [[ ! $cols =~ ^[1-9][0-9]*$ ]]; then
            echo "Cols number must be a positive integer"
        else
            break
        fi
    done 

    while [ $num -lt $cols ]; do
        if [ $num -eq 0 ]; then
            read -p "Pls, Enter The PK Column: " colName

        else
            read -p "Pls, Enter column name: " colName

        fi
         if [[ ! "$colName" =~ ^[[:alpha:]]+$ ]]; then
            echo "Column name must contain only alphabetic characters."
            continue
        fi

        select colType in "string" "integer"; do
            case $colType in
                "integer" | "string" ) break ;;
                *) echo "This is invalid choice!" ;;
            esac
        done

        nameRecord+="$colName"
        dataTypeRecord+="$colType"
        
        if [ $num -lt $((cols-1)) ]; then
            nameRecord+=":"
            dataTypeRecord+=":"
        fi
        
        let num++
    done
    
    echo "$dataTypeRecord" >> "$PWD/${tableName}-meta.txt"
    echo "$nameRecord" >> "$PWD/${tableName}-meta.txt"
    echo "Table '$tableName' created successfully."
}
#-------------------------------Function List Tables Function---------------------------------
function listTables {
    local tables=$(ls "$PWD")
    if [ -z "$tables" ]; then
        echo "No tables to list here"
    else
        echo "$tables"
    fi
}
#---------------------------------Function Drop Tabel Function--------------------------------
function dropTable {
    local tableName
     if [ -z "$(ls)" ]
    then
        echo "No Tables to drop here"
    else
        while true
        do
            read -p "Enter the table you want to drop: " tableName
            validateByName $tableName
            if [ $? -eq 0 ]
            then
                break
            fi
        done

        if [ -f "$tableName".txt ]
        then
            rm "$tableName".txt
            rm "$tableName"-meta.txt
            echo "Table ${tableName} deleted successfully"
        else
            echo "Table ${tableName} doesn't exist!"
            return
        fi
    fi
}
#------------------------------------Function Insert table-----------------------------------------
function insertTable {
    local tableName

    if [ -z "$(ls)" ]; then 
        echo "No Tables To Insert here"
        return
    fi

    read -r -p "Enter the name of the table: " tableName
    validateByName "$tableName" || return

    # if [  -f "$tableName".txt ];then
    # echo "Table '$tableName '.txt doesn't exist."
    # return
    # fi

    file="$PWD/${tableName}-meta.txt"

    IFS=$'\n' read -d '' -r -a lines < "$file"
    IFS=: read -ra colTypes <<< "${lines[0]}"
    IFS=: read -ra colNames <<< "${lines[1]}"

    insertValue=""
    for ((i=0; i<${#colNames[@]}; i++)); do
        read -r -p "Enter the value of ${colNames[i]} ${colTypes[i]}: " colValue
        colName="${colNames[i]}"
        colType="${colTypes[i]}"

        if ! validateDataType "$colValue" "$colType"; then
            echo "Invalid data type for $colName: $colValue"
            exit
        fi
        if [ $i -eq 0 ] && grep -q "^${colValue}:" "$PWD/${tableName}.txt"; then
            echo "This PK already exists. Please try again."
            exit
        fi

        insertValue+="${colValue}:"
    done

    dir="$PWD/${tableName}.txt"
    echo "${insertValue%:}" >> "$dir"
    echo "The values are inserted successfully"

}
#----------------------------Function to delete from table-------------------------------------------
function deleteTable {
    local pk tableName choice

    if [ -z "$(ls)" ]; then
        echo "No Tables To Remove here"
        return
    fi

    while true; do
        read -p "Enter Table Name: " tableName
        validateByName "$tableName"
        if [ $? -eq 0 ]; then
            break
        fi
    done

    if [ -d "$tableName" ]; then
        echo "Table Doesn't Exist"
        return
    fi


    if [ -s "$tableName/${tableName}.txt" ]; then
        echo "The $tableName is empty."
        return
    fi

    read -p "Do you want to delete the whole table? [y/n]: " choice
    case $choice in
        [Yy]* )
            rm "$PWD/${tableName}.txt"
            rm "$PWD/${tableName}-meta.txt"
            echo "Table ${tableName} deleted successfully"
            return
            ;;
        [Nn]* )
            read -p "Enter the PK of the record to delete: " pk
            if [ -z "$(grep "^${pk}" "$PWD/${tableName}.txt")" ]; then
                echo "The PK doesn't exist."
                return
            else
                sed -i "/^${pk}/d" "$PWD/${tableName}.txt"
                echo "The record of PK = ${pk} has been deleted successfully."
                return
            fi
            ;;
        * )
            echo "Invalid input. Please enter 'y' or 'n'."
            ;;
    esac
}
#----------------------------Function to select all the table-------------------------------------------
function selectAllTable {
    local tableName pk

    if [ -z "$(ls)" ]; then
        echo "No Tables To Select here"
        return
    fi

    read -r -p "Enter the name of the table: " tableName
    validateByName "$tableName" || return

    if [ -d "$tableName" ]; then
        echo "Table Doesn't Exist"
        return
    fi

    if [ -s "${tableName}" ]; then
        echo "The $tableName is empty."
        return
    fi

    tail -1 "$PWD/${tableName}-meta.txt" 
    echo "Here Is Select all The Table"
    awk -F ':' '{print $0 }' "$PWD/${tableName}.txt"
    
}
#---------------------------Function update table------------------------------------------
function updateTable {

 if [ -z "$(ls)" ]; then 
        echo "No Tables To Update here"
        return
    fi
    read -r -p "Enter Table Name: " tableName
    validateByName "$tableName" || return

    # if [ -d "$PWD/${tableName}" ]; then
    #     echo "Table '$tableName' doesn't exist."
    #     return
    # fi

    if ! grep -q ":" "$PWD/${tableName}.txt"; then
        echo "There is no data to update in table '$tableName'."
        return
    fi

    read -r -p "Enter Primary Key (pk): " pk

    if ! grep -q "^${pk}:" "$PWD/${tableName}.txt"; then
        echo "The PK '$pk' doesn't exist."
        return
    fi

    read -r -p "Enter Previous Name: " colName

    if ! grep -q "$colName" "$PWD/${tableName}.txt"; then
        echo "The column '$colName' doesn't exist."
        return
    fi

    read -r -p "Enter New Value: " newValue
    colType=$(grep "$colName" "$PWD/${tableName}-meta.txt" | cut -d ':' -f2)

    validateDataType "$newValue" "$colType"

    sed -i "s/^${pk}:[^:]*/${pk}:${newValue}/" "$PWD/${tableName}.txt"
    echo "The table is updated successfully"

}
#------------------------------------Selection by id------------------------------------------
function selectById(){
    local tableName
    local pk

    if [ -z "$(ls)" ]; then
        echo "No Tables To Select"
        return
    fi

    read -r -p "Enter the name of the table: " tableName
    validateByName "$tableName" || return

    if [ -d "$tableName" ]; then
        echo "Table Doesn't Exist"
        return
    fi

    if [ -s "${tableName}" ]; then
        echo "The $tableName is empty."
        return
    fi
    read -r -p "Enter Primary Key (pk): " pk
    # Check if the primary key exists in the table
    if [ -z "$(grep "^${pk}:" "$PWD/${tableName}.txt")" ]; then
        echo "The record with primary key '${pk}' doesn't exist."
        return
    fi

    echo "Here Is Selection By Id"
    grep "^${pk}:" "$PWD/${tableName}.txt"
}
#------------------------------- Table Menu------------------------------------------------------
function showTablesMenu {
    echo "======================================================="
	echo "     Table Menu for Database Management System             "
	echo "======================================================="
	echo " "
        echo "Table Menu:"
        echo "1. Create Table"
        echo "2. List Tables"
        echo "3. Drop Table"
        echo "4. Insert Table"
        echo "5. select All Table"
        echo "6. Select Table By ID"
        echo "7. Delete Table"
        echo "8. Update Table"
        echo "9. Exit"

        read -r -p "Enter your choice From Table Menu: " choice2

        case $choice2 in
            1) createTable ;;
            2) listTables ;; 
            3) dropTable ;; 
            4) insertTable ;; 
            5) selectAllTable ;;
            6) selectById ;;  
            7) deleteTable ;; 
            8) updateTable ;; 
            9) echo "Exiting..!"; exit ;; 
            *) echo "Your choice is not valid"
        esac
showTablesMenu
}
#--------------------------------------------------Main Menu------------------------------------------------------
while true; do
    echo "============================================================"
	echo "     Bash Shell Script Menu for Database Management System             "
	echo "============================================================"
	echo " "
    echo "Main Menu:"
    echo "1. Create Database"
    echo "2. List Databases"
    echo "3. Connect To Database"
    echo "4. Drop Database"
    echo "5. Exit"

    read -r -p "Enter your choice: " choice
    case $choice in
        1) createDatabase ;;
        2) listDatabases ;;
        3) connectToDatabase ;;
        4) dropDatabase ;;
        5) echo "Exiting..."; exit ;;
        *) echo "Your choice is not valid !"
    esac
done
#-----------------------------------------------------THE END-----------------------------------------------------
