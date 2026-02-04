#!/bin/bash

# Script per configurar l'enviament de correus electrònics en Debian GNU/Linux
# Utilitza msmtp com a MTA de només enviament.

set -e

# Colors per a la sortida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sense color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 1. Comprovar si s'executa com a root
if [ "$EUID" -ne 0 ]; then
    error "Aquest script s'ha d'executar com a root (sudo)."
fi

log "Iniciant la configuració de correu per a notificacions..."

# 2. Instal·lar paquets necessaris
log "Instal·lant msmtp i bsd-mailx..."
apt-get update -qq
apt-get install -y msmtp msmtp-mta bsd-mailx > /dev/null

# 3. Recollir informació del servidor SMTP
echo -e "${YELLOW}--- Configuració SMTP ---${NC}"
read -p "Servidor SMTP (ex: smtp.gmail.com): " SMTP_HOST
read -p "Port SMTP (ex: 587): " SMTP_PORT
read -p "Usuari SMTP (adreça de correu): " SMTP_USER
read -s -p "Contrasenya SMTP: " SMTP_PASS
echo ""
read -p "Adreça de correu de remetent (ex: alerts@$HOSTNAME): " FROM_EMAIL

# 4. Crear el fitxer de configuració /etc/msmtprc
log "Generant /etc/msmtprc..."

cat <<EOF > /etc/msmtprc
# Configuració global
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

# Compte per defecte
account default
host           $SMTP_HOST
port           $SMTP_PORT
from           $FROM_EMAIL
user           $SMTP_USER
password       $SMTP_PASS
EOF

# Establir permisos segurs
chmod 600 /etc/msmtprc
chown root:root /etc/msmtprc

# 5. Configurar els àlies de correu (per rebre correus del sistema)
log "Configurant àlies de correu a /etc/aliases..."

# Comprovar si l'àlies root ja existeix
if grep -q "^root:" /etc/aliases; then
    sed -i "s/^root:.*/root: $SMTP_USER/" /etc/aliases
else
    echo "root: $SMTP_USER" >> /etc/aliases
fi

# Configurar msmtp per utilitzar els àlies
if ! grep -q "aliases /etc/aliases" /etc/msmtprc; then
    sed -i "/defaults/a aliases /etc/aliases" /etc/msmtprc
fi

# 6. Prova d'enviament
log "Enviant correu de prova a $SMTP_USER..."
echo "Això és un correu de prova de configuració del servidor $HOSTNAME." | mail -s "Prova de correu: $HOSTNAME" "$SMTP_USER"

log "Configuració finalitzada amb èxit!"
warn "Si no has rebut el correu de prova, revisa els logs a /var/log/msmtp.log"
