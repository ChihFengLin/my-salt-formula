#!/bin/bash
#
# Automate mysql secure installation for Red Hat Enterprise Linux (RHEL) compatible distributions
# 
#  - Change a password for root accounts (CLI option)
#  - Remove root account access from hosts other than localhost. (default behavior)
#  - Remove anonymous-user accounts. (default behavior)
#  - Remove the test database and privileges that permit anyone to
#    access databases with names that start with test_. (default behavior)
#
# For details see documentation: http://dev.mysql.com/doc/refman/5.5/en/mysql-secure-installation.html


# Delete package EXPECT when script is done
# 0 - No; 
# 1 - Yes.
REMOVE_EXPECT_WHEN_DONE=0

#
# Check the bash shell script is being run by root
#
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#
# Check input params
#
if [ -n "${1}" -a -n "${2}" ]; then
    LOG_FILE_PATH="${1}"
    NEW_MYSQL_PASSWORD="${2}"
else
    echo "Usage:"
    echo "  Secure mysql while changing root password:"
    echo "      ${0} 'mysql_log_file_path' 'new_root_password'"
    exit 1
fi



# Check if EXPECT package installed
if [ $(yum list installed | grep -c expect) -eq 0 ]; then
    echo "EXPECT was not found. Installing from YUM repository..."
    yum -y install expect
fi

CURRENT_MYSQL_PASSWORD=`grep 'temporary password' $LOG_FILE_PATH | awk '{print $11}'`

SECURE_MYSQL=$(expect -c "

set timeout 10
spawn mysql_secure_installation

expect \"Enter password for user root:\"
send \"$CURRENT_MYSQL_PASSWORD\r\"

expect \"New password:\"
send \"$NEW_MYSQL_PASSWORD\r\"

expect \"Re-enter new password:\"
send \"$NEW_MYSQL_PASSWORD\r\"

expect \"Change the password for root ?:\"
send \"y\r\"

expect \"New password:\"
send \"$NEW_MYSQL_PASSWORD\r\"

expect \"Re-enter new password:\"
send \"$NEW_MYSQL_PASSWORD\r\"

expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect eof
")


# Execution mysql_secure_installation
echo "${SECURE_MYSQL}"

if [ "${REMOVE_EXPECT_WHEN_DONE}" -eq 1 ]; then
    # Uninstall EXPECT package
    yum -y remove expect
fi

exit 0