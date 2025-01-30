#!/bin/bash

set -e

echo "🚀 Installerer Time-Tracking Web App på Debian/Ubuntu..."

# Oppdater systemet og installer nødvendige pakker
echo "🔄 Sjekker og installerer nødvendige pakker..."
REQUIRED_PKGS=("nodejs" "npm" "postgresql" "postgresql-contrib" "nginx" "certbot" "python3-certbot-nginx" "git" "curl")
for pkg in "${REQUIRED_PKGS[@]}"; do
    if dpkg -l | grep -qw "$pkg"; then
        echo "✅ $pkg er allerede installert."
    else
        echo "📦 Installerer $pkg..."
        sudo apt install -y "$pkg"
    fi
done

# Start og aktiver PostgreSQL
echo "🐘 Sjekker PostgreSQL status..."
if systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL kjører allerede."
else
    echo "🚀 Starter PostgreSQL..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
fi

# Sjekk om databasen allerede finnes
echo "📂 Sjekker database..."
DB_EXIST=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='timetracking'")
if [ "$DB_EXIST" = "1" ]; then
    echo "✅ Database 'timetracking' finnes allerede."
else
    echo "🛠️ Oppretter database..."
    sudo -u postgres psql -c "CREATE DATABASE timetracking;"
    sudo -u postgres psql -c "CREATE USER admin WITH ENCRYPTED PASSWORD 'adminpass';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE timetracking TO admin;"
fi

# Klon prosjektet hvis det ikke finnes
echo "📦 Sjekker om prosjektet er klonet..."
if [ -d "/var/www/timetracking" ]; then
    echo "✅ Prosjektet er allerede klonet."
else
    echo "📥 Kloner prosjektet..."
    git clone https://github.com/rubspe/timetracking-webapp.git /var/www/timetracking
fi

cd /var/www/timetracking

# Installer avhengigheter hvis ikke installert
if [ -d "node_modules" ]; then
    echo "✅ Node.js avhengigheter er allerede installert."
else
    echo "📦 Installerer Node.js avhengigheter..."
    npm install
fi

# Konfigurer miljøvariabler hvis ikke satt
if [ -f ".env" ]; then
    echo "✅ .env-fil finnes allerede."
else
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

# Kjør database-migrasjoner hvis nødvendig
if sudo -u postgres psql timetracking -c "SELECT * FROM users LIMIT 1;" &> /dev/null; then
    echo "✅ Database-migrasjoner er allerede utført."
else
    echo "📂 Kjører database-migrasjoner..."
    node migrate.js
fi

# Sett opp systemd-tjeneste hvis ikke allerede satt opp
if [ -f "/etc/systemd/system/timetracking.service" ]; then
    echo "✅ Systemd-tjenesten er allerede konfigurert."
else
    echo "⚙️ Oppretter systemd-tjeneste..."
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
fi

echo "✅ Installasjon fullført! Tilgjengelig på serverens IP-adresse.🚀"
