#!/bin/bash

set -e

echo "🚀 Installerer Time-Tracking Web App på Debian/Ubuntu..."

# Oppdater systemet og installer nødvendige pakker
echo "🔄 Oppdaterer pakker og installerer avhengigheter..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y nodejs npm postgresql postgresql-contrib nginx certbot python3-certbot-nginx git curl

# Sett opp PostgreSQL
echo "🐘 Konfigurerer PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -u postgres psql -c "CREATE DATABASE timetracking;"
sudo -u postgres psql -c "CREATE USER admin WITH ENCRYPTED PASSWORD 'adminpass';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE timetracking TO admin;"

# Klon prosjektet og installer avhengigheter
echo "📦 Kloner prosjektet og installerer Node.js avhengigheter..."
git clone https://github.com/rubspe/timetracking-webapp.git /var/www/timetracking
cd /var/www/timetracking
npm install

# Konfigurer miljøvariabler
echo "🔧 Konfigurerer miljøvariabler..."
cat <<EOT > .env
DB_USER=admin
DB_PASS=adminpass
DB_NAME=timetracking
DB_HOST=localhost
DB_PORT=5432
JWT_SECRET=$(openssl rand -hex 32)
EOT

# Kjør database-migrasjoner
echo "📂 Kjører database-migrasjoner..."
node migrate.js

# Sett opp systemd-tjeneste
echo "⚙️ Konfigurerer systemd-tjeneste..."
cat <<EOT | sudo tee /etc/systemd/system/timetracking.service
[Unit]
Description=Time-Tracking Web App
After=network.target

[Service]
User=www-data
WorkingDirectory=/var/www/timetracking
ExecStart=/usr/bin/node /var/www/timetracking/server.js
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload
sudo systemctl enable timetracking.service
sudo systemctl start timetracking.service

echo "✅ Installasjon fullført! Tilgjengelig på serverens IP-adresse.🚀""
