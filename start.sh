#!/usr/bin/env bash

#
# This file should be used to prepare and run your WebProxy after set up your .env file
# Source: https://github.com/evertramos/docker-compose-letsencrypt-nginx-proxy-companion
#

# 1. Check if .env file exists
if [ -e .env ]; then
    source .env
else
    echo "It seems you didn´t create your .env file, so we will create one for you."
    cp .env.sample .env
    # exit 1
fi

# 2. Create docker network
docker network create $NETWORK $NETWORK_OPTIONS

# 3. Verify if second network is configured
if [ ! -z ${SERVICE_NETWORK+X} ]; then
    docker network create $SERVICE_NETWORK $SERVICE_NETWORK_OPTIONS
fi

# 4. Download the latest version of nginx.tmpl
# FL note: We have made customizations nginx.tmpl so merge from upstream with care!
# curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl > nginx.tmpl

# 5. Update local images
docker compose pull

# 6. Add any special configuration if it's set in .env file

# Check if user set to use Special Conf Files
if [ ! -z ${USE_NGINX_CONF_FILES+X} ] && [ "$USE_NGINX_CONF_FILES" = true ]; then

    # Create the conf folder if it does not exists
    mkdir -p $NGINX_FILES_PATH/conf.d

    # Create the custom conf folder if it does not exists. For configuration not to be included globally.
    mkdir -p $NGINX_FILES_PATH/conf_custom.d

    # Copy the special configurations to the nginx conf folder
    cp -R ./conf.d/* $NGINX_FILES_PATH/conf.d
    cp -R ./conf_custom.d/* $NGINX_FILES_PATH/conf_custom.d

    # Check if there was an error and try with sudo
    if [ $? -ne 0 ]; then
        sudo cp -R ./conf.d/* $NGINX_FILES_PATH/conf.d
    fi

    # Whitlist IPs. Our custom server-level firewall
    # We maintain a master template to maintain idempotency.
    cp ./nginx.tmpl.master ./nginx.tmpl

    WHITELIST=./conf_custom.d/ip-whitelist.conf
    # Generate the ip whitelist conf file from the .env variables
    install -D /dev/null "$WHITELIST"
    echo "allow ${IP_DOCKER_NETWORK:-127.0.0.1};" >> "$WHITELIST"
    echo "allow ${IP_RM:-127.0.0.1};" >> "$WHITELIST"
    echo "allow ${IP_RM_2:-127.0.0.1};" >> "$WHITELIST"
    echo "allow ${IP_DEV_1:-127.0.0.1};" >> "$WHITELIST"
    echo "allow ${IP_DEV_2:-127.0.0.1};" >> "$WHITELIST"
    echo "allow ${IP_DEV_3:-127.0.0.1};" >> "$WHITELIST"
    echo "allow ${IP_DEV_4:-127.0.0.1};" >> "$WHITELIST"
    echo "allow ${IP_DEV_5:-127.0.0.1};" >> "$WHITELIST"
    echo "deny all;" >> "$WHITELIST"

    # Write the included hosts from .env file to the nginx.tmpl
    INCLUDED_HOSTS=$(cat .env | grep FIREWALL_PROTECTED_HOSTS | cut -d '=' -f2)

    # Replace a placeholder in nginx.tmpl with the actual value
    sed -i "s/{{INCLUDED_HOSTS}}/$INCLUDED_HOSTS/g" ./nginx.tmpl

    # Overwrite default conf files if we are on dev
    if [ -n "$(ls -A ./conf_dev.d 2>/dev/null)" ] && [ "$ENVIRONMENT" = "dev" ]; then
        # Copy the dev configurations to the nginx conf folder
        cp -R ./conf_dev.d/* $NGINX_FILES_PATH/conf.d
    fi

    # Overwrite default conf files if we are on staging
    if [ -n "$(ls -A ./conf_staging.d 2>/dev/null)" ] && [ "$ENVIRONMENT" = "staging" ]; then
        # Copy the staging configurations to the nginx conf folder
        cp -R ./conf_staging.d/* $NGINX_FILES_PATH/conf.d
    fi

    # If there was any errors inform the user
    if [ $? -ne 0 ]; then
        echo
        echo "#######################################################"
        echo
        echo "There was an error trying to copy the nginx conf files."
        echo "The proxy will still work with default options, but"
        echo "the custom settings your have made could not be loaded."
        echo
        echo "#######################################################"
    fi
fi

# 7. Start proxy

# Check if you have multiple network
if [ -z ${SERVICE_NETWORK+X} ]; then
    echo "Starting proxy..."
    docker compose up -d
else
    echo "Starting proxy with multiple networks..."
    docker compose -f docker-compose-multiple-networks.yml up -d
fi

exit 0
