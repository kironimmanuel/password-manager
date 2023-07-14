#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
ORANGE='\033[38;5;208m'
INVERTED='\x1b[7m'

NC='\033[0m'

PASSWORD_FILE=".passwords"
MASTER_KEY=".masterkey"

# Encrypt the string using a simple transformation (Caesar cipher)
encrypt() {
    local input="$1"
    local encrypted=$(echo "$input" | tr 'A-Za-z' 'N-ZA-Mn-za-m')
    echo "$encrypted"
}

# Decrypt the string using the reverse transformation
decrypt() {
    local input="$1"
    local decrypted=$(echo "$input" | tr 'N-ZA-Mn-za-m' 'A-Za-z')
    echo "$decrypted"
}

set_master_password() {
    if [ -f "$MASTER_KEY" ]; then
        echo "Master password already defined."
        return
    fi

    echo -e "${YELLOW}Setting up the master password.${NC}"
    read -sp "Enter the master password: " master_password

    encrypted_master_password=$(encrypt "$master_password")

    echo "$encrypted_master_password" >"$MASTER_KEY"
    echo "Master password set successfully."
    sleep 1
}

if [ ! -f "$MASTER_KEY" ]; then
    set_master_password
fi

add_password() {

    echo "Enter the website or service name:"
    read website
    echo "Enter the username or email:"
    read username
    echo "Enter the password:"
    read -s password
    clear

    encrypted_password=$(echo "$password" | tr 'A-Za-z' 'N-ZA-Mn-za-m')

    echo "$website:$username:$encrypted_password" >>"$PASSWORD_FILE"

    echo "Password added successfully!"
}

get_password() {
    echo -e "${YELLOW}Enter the website or service name:${NC}"
    read website

    # Search for the entry in the password file
    password_entry=$(grep -i "^$website:" "$PASSWORD_FILE" | head -n 1)

    if [ -n "$password_entry" ]; then
        echo -e "${YELLOW}Enter the master password:${NC}"
        read -s master_password
        clear

        encrypted_master_password=$(cat "$MASTER_KEY")
        decrypted_master_password=$(decrypt "$encrypted_master_password")

        if [ "$master_password" == "$decrypted_master_password" ]; then
            encrypted_password=$(echo "$password_entry" | cut -d ':' -f 3)
            password=$(decrypt "$encrypted_password")

            echo "Website: $website"
            echo "Password: $password"
        else
            echo "Incorrect master password."
        fi
    else
        echo "Password not found for the given website."
    fi
}

get_all_passwords() {
    echo -e "${YELLOW}Enter the master password:${NC}"
    read -s master_password
    clear

    encrypted_master_password=$(cat "$MASTER_KEY")

    decrypted_master_password=$(decrypt "$encrypted_master_password")

    if [ "$master_password" == "$decrypted_master_password" ]; then
        if [ -f "$PASSWORD_FILE" ] && [ -s "$PASSWORD_FILE" ]; then
            echo -e "${YELLOW}All Passwords:${NC}"
            while IFS=':' read -r website username encrypted_password; do
                password=$(decrypt "$encrypted_password")
                echo "Website: $website"
                echo "Username: $username"
                echo "Password: $password"
                echo "------------------------"
            done <"$PASSWORD_FILE"
        else
            echo "No passwords found."
        fi
    else
        echo "Incorrect master password."
    fi
}

delete_password() {
    echo -e "${YELLOW}Enter the website or service name:${NC}"
    read website

    # Search for the entry in the password file
    password_entry=$(grep -i "^$website:" "$PASSWORD_FILE" | head -n 1)

    if [ -n "$password_entry" ]; then
        echo -e "${YELLOW}Enter the master password:${NC}"
        read -s master_password
        clear

        encrypted_master_password=$(cat "$MASTER_KEY")
        decrypted_master_password=$(decrypt "$encrypted_master_password")

        if [ "$master_password" == "$decrypted_master_password" ]; then
            encrypted_password=$(echo "$password_entry" | cut -d ':' -f 3)
            password=$(decrypt "$encrypted_password")

            echo "Website: $website"
            echo "Password: $password"

            # Delete the password entry from the file
            sed -i "/^$website:/I d" "$PASSWORD_FILE"
            echo -e "${YELLOW}Password deleted successfully.${NC}"
        else
            echo "Incorrect master password."
        fi
    else
        echo "Password not found for the given website."
    fi
}

while true; do
    echo -e "${YELLOW}${INVERTED} Password Manager ${NC}"
    echo "[1]. Add a password"
    echo "[2]. Get a password"
    echo "[3]. List all passwords"
    echo "[4]. Delete a password"
    echo "[5]. Exit"
    read -p "Enter your choice: " choice

    case $choice in
    1)
        add_password
        ;;
    2)
        get_password
        ;;
    3)
        get_all_passwords
        ;;
    4)
        delete_password
        ;;
    5)
        echo "Exiting Password Manager"
        sleep 0.1
        clear
        exit 0
        ;;
    *)
        echo "Invalid choice. Please try again."
        sleep 1
        clear
        ;;
    esac

    echo
done
