#!/usr/bin/env bash
set -euo pipefail

# Load DO_API_TOKEN from .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found at $ENV_FILE"
  exit 1
fi

DO_API_TOKEN=$(grep -E "^DO_API_TOKEN=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")

if [ -z "$DO_API_TOKEN" ]; then
  echo "Error: DO_API_TOKEN not found in .env file"
  echo "Add DO_API_TOKEN=your_token_here to $ENV_FILE"
  exit 1
fi

# Droplet configuration
DROPLET_NAME="${1:-paas}"
DROPLET_USER="${2:-paas_admin}"
REGION="fra1"
SIZE="s-1vcpu-1gb"
IMAGE="ubuntu-24-04-x64"
SSH_KEY_NAME="admin"

# Load and interpolate cloud-init script
CLOUD_INIT_FILE="$PROJECT_DIR/config/cloud-init.sh"

if [ ! -f "$CLOUD_INIT_FILE" ]; then
  echo "Error: cloud-init script not found at $CLOUD_INIT_FILE"
  exit 1
fi

USER_DATA=$(sed -e "s|\${USER}|$DROPLET_USER|g" -e "s|\${NAME}|$DROPLET_NAME|g" "$CLOUD_INIT_FILE")

# Look up SSH key ID by name
echo "Looking up SSH key \"$SSH_KEY_NAME\" on DigitalOcean..."
SSH_KEYS_RESPONSE=$(curl -s -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DO_API_TOKEN" \
  "https://api.digitalocean.com/v2/account/keys")

SSH_KEY_ID=$(echo "$SSH_KEYS_RESPONSE" | ruby -rjson -e "
  data = JSON.parse(STDIN.read) rescue nil
  key = data&.dig('ssh_keys')&.find { |k| k['name'] == ARGV[0] }
  if key
    puts key['id']
  else
    STDERR.puts \"Error: SSH key '#{ARGV[0]}' not found on your DigitalOcean account\"
    STDERR.puts \"Available keys: #{data&.dig('ssh_keys')&.map { |k| k['name'] }&.join(', ')}\"
    exit 1
  end
" "$SSH_KEY_NAME")

if [ -z "$SSH_KEY_ID" ]; then
  exit 1
fi

echo "Found SSH key \"$SSH_KEY_NAME\" (ID: $SSH_KEY_ID)"
echo ""

echo "Creating DigitalOcean droplet..."
echo "  Name:   $DROPLET_NAME"
echo "  User:   $DROPLET_USER"
echo "  Region: $REGION"
echo "  Size:   $SIZE"
echo "  Image:  $IMAGE"
echo "  SSH:    $SSH_KEY_NAME (ID: $SSH_KEY_ID)"
echo "  Init:   $CLOUD_INIT_FILE"
echo ""

# Build the JSON payload with cloud-init user_data and SSH key
JSON_PAYLOAD=$(ruby -rjson -e "
  puts JSON.generate({
    name: ARGV[0],
    region: ARGV[1],
    size: ARGV[2],
    image: ARGV[3],
    monitoring: true,
    ssh_keys: [ARGV[5].to_i],
    user_data: ARGV[4]
  })
" "$DROPLET_NAME" "$REGION" "$SIZE" "$IMAGE" "$USER_DATA" "$SSH_KEY_ID")

# Create the droplet
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DO_API_TOKEN" \
  -d "$JSON_PAYLOAD" \
  "https://api.digitalocean.com/v2/droplets")

# Check for errors in the response
if echo "$RESPONSE" | grep -q '"id"'; then
  DROPLET_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
  echo "Droplet created successfully! ID: $DROPLET_ID"
else
  echo "Error creating droplet:"
  echo "$RESPONSE"
  exit 1
fi

# Wait for the IP address to be assigned
echo ""
echo "Waiting for IP address assignment..."

MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ATTEMPT=$((ATTEMPT + 1))

  DROPLET_INFO=$(curl -s -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DO_API_TOKEN" \
    "https://api.digitalocean.com/v2/droplets/$DROPLET_ID")

  STATUS=$(echo "$DROPLET_INFO" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)

  # Try to extract the public IPv4 address
  # Look for the public v4 IP in the networks section
  IP=$(echo "$DROPLET_INFO" | ruby -rjson -e "
    data = JSON.parse(STDIN.read) rescue nil
    ip = data&.dig('droplet', 'networks', 'v4')&.find { |n| n['type'] == 'public' }&.dig('ip_address')
    puts ip if ip
  " 2>/dev/null || true)

  if [ -n "$IP" ]; then
    echo ""
    echo "========================================="
    echo "  Droplet is ready!"
    echo "  ID:     $DROPLET_ID"
    echo "  Name:   $DROPLET_NAME"
    echo "  IP:     $IP"
    echo "  Status: $STATUS"
    echo "========================================="
    # Update config/deploy.yml with the new IP address
    DEPLOY_FILE="$PROJECT_DIR/config/deploy.yml"
    if [ -f "$DEPLOY_FILE" ]; then
      sed -i '' "s/- 192\.168\.0\.1/- $IP/g" "$DEPLOY_FILE"
      sed -i '' "s/host: 192\.168\.0\.1/host: $IP/g" "$DEPLOY_FILE"
      echo ""
      echo "Updated config/deploy.yml with IP $IP"
    fi

    echo ""
    echo "Cloud-init is provisioning the server (this may take a few minutes)."
    echo "Once complete, SSH in with:"
    echo "  ssh $DROPLET_USER@$IP"
    exit 0
  fi

  printf "  Attempt %d/%d — status: %s, waiting...\r" "$ATTEMPT" "$MAX_ATTEMPTS" "$STATUS"
  sleep 5
done

echo ""
echo "Timed out waiting for IP address after $((MAX_ATTEMPTS * 5)) seconds."
echo "The droplet (ID: $DROPLET_ID) may still be provisioning."
echo "Check manually:"
echo "  curl -s -H 'Authorization: Bearer \$DO_API_TOKEN' https://api.digitalocean.com/v2/droplets/$DROPLET_ID | ruby -rjson -e 'puts JSON.pretty_generate(JSON.parse(STDIN.read))'"
exit 1
