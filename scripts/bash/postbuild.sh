#!/bin/bash

# Copyright (c) Microsoft Corporation
# All rights reserved.
#
# MIT License

echo "Hello from postbuild.sh"

####################################################################################
#
# Call the install.php file with the option to deploy the database schema.
# This runs synchronously and will take a few seconds to complete.
#
####################################################################################

curl -sS https://$WEBSITE_HOSTNAME/install.php?auto=1

echo -e "\nFinished running install.php"

####################################################################################
#
# Create the WebJobs to run the cron.php file every minute
# and to facilitate the database configuration.
#
####################################################################################

cp -r /home/site/repository/App_Data /home/site/wwwroot
