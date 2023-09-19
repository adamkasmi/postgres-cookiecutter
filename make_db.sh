#!/bin/bash

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

# Check if database "carddb" exists
DB_EXISTS=$(sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -w carddb | wc -l)

if [ "$DB_EXISTS" -eq "0" ]; then
    echo "Database carddb does not exist. Creating..." | tee -a $LOGFILE
    
    # Create the database
    sudo -u postgres createdb carddb
else
    echo "Database carddb already exists." | tee -a $LOGFILE
fi

# Check if user "carduser" exists
USER_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='carduser'")

if [ -z "$USER_EXISTS" ]; then
    echo "User carduser does not exist. Creating..." | tee -a $LOGFILE
    
    # Create user and set password
    sudo -u postgres psql -c "CREATE USER carduser WITH PASSWORD 'password123';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE carddb TO carduser;"
else
    echo "User carduser already exists." | tee -a $LOGFILE
fi

echo "Setup details:" | tee -a $LOGFILE
echo "Database Name: carddb" | tee -a $LOGFILE
echo "Username: carduser" | tee -a $LOGFILE
echo "Password: password123" | tee -a $LOGFILE
echo "Connection String for Flask: postgresql://carduser:password123@localhost/carddb" | tee -a $LOGFILE

echo "Done." | tee -a $LOGFILE
