#!/bin/bash

set -e

echo "🚀 Starter installasjon av Time-Tracking Web App på Debian/Ubuntu..."

sudo apt update && sudo apt install -y nodejs npm postgresql postgresql-contrib nginx certbot python3-certbot-nginx git curl

sudo systemctl start postgresql
sudo systemctl enable postgresql

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='timetracking'"; then
    echo "🛠️ Oppretter database..."
    sudo -u postgres psql -c "CREATE DATABASE timetracking;"
    sudo -u postgres psql -c "CREATE USER admin WITH ENCRYPTED PASSWORD 'adminpass';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE timetracking TO admin;"
fi

if [ ! -d "/var/www/timetracking" ]; then
    git clone https://github.com/rubspe/timetracking-webapp.git /var/www/timetracking
fi

cd /var/www/timetracking
npm install

if [ ! -f ".env" ]; then
    echo "🔧 Oppretter .env-fil..."
    cat <<EOT > .env
DB_USER=admin
DB_PASS=adminpass
DB_NAME=timetracking
DB_HOST=localhost
DB_PORT=5432
JWT_SECRET=$(openssl rand -hex 32)
EOT
fi

if ! sudo -u postgres psql timetracking -c "SELECT * FROM users LIMIT 1;" &> /dev/null; then
    echo "📂 Kjører database-migrasjoner..."
    node migrate.js
fi

echo "✅ Installasjon fullført! Tilgjengelig på serverens IP-adresse.🚀"
