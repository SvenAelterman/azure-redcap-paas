#!/bin/bash

# Copyright (c) Microsoft Corporation
# All rights reserved.
#
# MIT License

echo "Hello from postbuild.sh"

####################################################################################
#
# Configure mysqli extension
#
####################################################################################

if [[ "$APPSETTING_DO_DEPLOY_REDCAP" != "1" ]]; then
  echo "Skipping REDCap deployment (DO_DEPLOY_REDCAP = $APPSETTING_DO_DEPLOY_REDCAP)" >> /home/site/log-$stamp.txt
  exit 0
fi

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
# Update additional configuration settings including
# user file uploading settings to Azure Blob Storage
# 
####################################################################################

#bash /home/site/repository/scripts/bash/install.sh
