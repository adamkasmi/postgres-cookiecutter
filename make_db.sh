#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <username> <password> <dbname>"
    exit 1
fi

USERNAME=$1
PASSWORD=$2
DBNAME=$3
LOGFILE="$(pwd)/postgres_setup.log"

echo "Logging details to $LOGFILE..."

# Check if postgresql is installed
if ! command -v psql > /dev/null; then
    echo "PostgreSQL is not installed. Installing..." | tee -a $LOGFILE
    
    # Update and install PostgreSQL and its contrib package
    sudo apt update
    sudo apt install -y postgresql postgresql-contrib

    # Start the PostgreSQL service
    sudo systemctl start postgresql
    sudo systemctl enable postgresql

else
    echo "PostgreSQL is already installed." | tee -a $LOGFILE
fi

# Check if database exists
DB_EXISTS=$(sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -w $DBNAME | wc -l)

if [ "$DB_EXISTS" -eq "0" ]; then
    echo "Database $DBNAME does not exist. Creating..." | tee -a $LOGFILE
    
    # Create the database
    sudo -u postgres createdb $DBNAME
else
    echo "Database $DBNAME already exists." | tee -a $LOGFILE
fi

# Check if user exists
USER_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$USERNAME'")

if [ -z "$USER_EXISTS" ]; then
    echo "User $USERNAME does not exist. Creating..." | tee -a $LOGFILE
    
    # Create user and set password
    sudo -u postgres psql -c "CREATE USER $USERNAME WITH PASSWORD '$PASSWORD';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DBNAME TO $USERNAME;"
else
    echo "User $USERNAME already exists." | tee -a $LOGFILE
fi

echo "Setup details:" | tee -a $LOGFILE
echo "Database Name: $DBNAME" | tee -a $LOGFILE
echo "Username: $USERNAME" | tee -a $LOGFILE
echo "Password: $PASSWORD" | tee -a $LOGFILE
echo "Connection String for Flask: postgresql://$USERNAME:$PASSWORD@localhost/$DBNAME" | tee -a $LOGFILE

echo "Done." | tee -a $LOGFILE
