#!/bin/bash
set -e

# Load aaPanel credentials from .env file
ENV_FILE="scripts/.env.aapanel"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Environment file not found: $ENV_FILE"
  exit 1
fi

source "$ENV_FILE"

echo "🔑 Using aaPanel credentials for $AAPANEL_USER@$AAPANEL_HOST"

# Write private key to temp file
TEMP_KEY="/tmp/deploy_key"
echo "$AAPANEL_KEY" | base64 --decode > "$TEMP_KEY"
chmod 600 "$TEMP_KEY"

# Test SSH connection
echo "🔍 Checking SSH access..."
if ssh -i "$TEMP_KEY" -o StrictHostKeyChecking=no "$AAPANEL_USER@$AAPANEL_HOST" "echo 'SSH OK'"; then
  echo "✅ SSH connection established."
else
  echo "❌ SSH connection failed. Check IP or firewall rules."
  exit 1
fi

# Deploy from GitHub
echo "📦 Pulling latest code..."
ssh -i "$TEMP_KEY" -o StrictHostKeyChecking=no "$AAPANEL_USER@$AAPANEL_HOST" <<'EOF'
  cd /www/wwwroot/wapp.4itec.site || exit 1
  git pull origin main || echo "⚠️ git pull failed, attempting fresh clone..."
  git clone https://github.com/R2124/WAPP-project.git temp_repo && \
  cp -r temp_repo/* . && rm -rf temp_repo
  echo "✅ Code updated."
  sudo systemctl restart nginx
  echo "🚀 Deployment complete."
EOF

rm -f "$TEMP_KEY"
echo "🧹 Temporary key removed. Done!"
