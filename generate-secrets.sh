#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=".env"

if [[ -f "$ENV_FILE" ]]; then
  read -rp ".env already exists. Overwrite? [y/N] " confirm
  [[ "${confirm,,}" == "y" ]] || { echo "Aborted."; exit 0; }
fi

# Generate secrets
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)

cat > "$ENV_FILE" <<EOF
# PostgreSQL
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# n8n
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}

# Update these for production
N8N_HOST=localhost
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678

# Timezone
GENERIC_TIMEZONE=Europe/London
TZ=Europe/London
EOF

chmod 600 "$ENV_FILE"

echo ""
echo "✓ .env generated at $(pwd)/${ENV_FILE}"
echo "✓ Permissions set to 600 (owner read/write only)"
echo ""
echo "  POSTGRES_PASSWORD : ${POSTGRES_PASSWORD}"
echo "  N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY}"
echo ""
echo "  Keep N8N_ENCRYPTION_KEY backed up — losing it makes saved credentials unrecoverable."
echo ""
echo "  When ready: docker compose up -d"

# Enter Server Details

read -p "Would you like to enter host, protocol and webhook URL? (y/n): " answer

if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    echo "Great, let's enter the server details..."
    read -p "Enter N8N_HOST (default: localhost): " n8n_host
    n8n_host=${n8n_host:-localhost}
    read -p "Enter N8N_PROTOCOL (default: http): " n8n_protocol
    n8n_protocol=${n8n_protocol:-http}
    read -p "Enter WEBHOOK_URL (default: http://localhost:5678):
  " webhook_url
    webhook_url=${webhook_url:-http://localhost:5678}

    # Update .env with the new values
    sed -i "s|^N8N_HOST=.*|N8N_HOST=${n8n_host}|" "$ENV_FILE"
    sed -i "s|^N8N_PROTOCOL=.*|N8N_PROTOCOL=${n8n_protocol}|" "$ENV_FILE"
    sed -i "s|^WEBHOOK_URL=.*|WEBHOOK_URL=${webhook_url}|" "$ENV_FILE"

    echo ""
    echo "✓ Updated .env with server details:"
    echo "  N8N_HOST: ${n8n_host}"
    echo "  N8N_PROTOCOL: ${n8n_protocol}"
    echo "  WEBHOOK_URL: ${webhook_url}"
else
    echo "Skipping server setup."
fi