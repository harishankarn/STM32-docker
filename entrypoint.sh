#!/bin/bash

# ========= Executable made to run Docker image on Mac OS ============ #

# Changes the internal user ID (UID) to match 
# Mac user ID to grant file access
if [[ -n "$LOCAL_USER_ID" ]]; then
    echo "Updating UID to $LOCAL_USER_ID"
    sudo usermod -u $LOCAL_USER_ID $USER
    sudo groupmod -g $LOCAL_USER_ID $USER
    sudo chown -R $LOCAL_USER_ID:$LOCAL_USER_ID /home/$USER
fi

exec "$@"

# Auto cd into mounted projects folder if it exists
if [[ -d "/home/$USER/projects" ]]; then
    cd /home/$USER
fi

# ========= Executable made to run Docker image on Mac OS ============ #