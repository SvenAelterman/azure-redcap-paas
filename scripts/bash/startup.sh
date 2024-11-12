#!/bin/bash

echo "Custom container startup"

####################################################################################
#
# Install required packages in container
#
####################################################################################

apt-get update -qq && apt-get install cron sendmail -yqq

####################################################################################
#
# Configure REDCap cronjob to run every minute
#
####################################################################################

# Export the database connection environment variables to /etc/environment so cron can use them
# We do this in startup.sh so that each container instance will get this file (it's outside of /home so not persisted)
# and also because then updates to the environment variables will be picked up by cron
echo "DBHostName=$DBHostName" > /etc/environment # Overwrite the file with the first statement
echo "DBName=$DBName" >> /etc/environment # Append all the other lines
echo "DBUserName=$DBUserName" >> /etc/environment
echo "DBPassword=$DBPassword" >> /etc/environment
echo "DBSslCa=$DBSslCa" >> /etc/environment

sed -i "s|date.timezone=UTC|date.timezone=$WEBSITE_TIME_ZONE|" /usr/local/etc/php/conf.d/php.ini

service cron start
(crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/php /home/site/wwwroot/cron.php > /dev/null")|crontab
