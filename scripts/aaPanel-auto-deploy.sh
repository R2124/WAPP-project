#!/bin/bash
set -e

echo "🚀 Starting aaPanel auto-deploy..."

# Load environment variables
source ./scripts/.env.aapanel

# Decode the SSH key (passed from GitHub Secrets as base64)
echo "$AAPANEL_KEY" | base64 --decode > /tmp/aapanel_key.pem
chmod 600 /tmp/aapanel_key.pem

echo "🔑 SSH key prepared for $AAPANEL_USER@$AAPANEL_HOST"

# Run the remote update via SSH
ssh -i /tmp/aapanel_key.pem -o StrictHostKeyChecking=no ${AAPANEL_USER}@${AAPANEL_HOST} << 'EOF'
  echo "📦 Connecting to remote server..."
  cd /www/wwwroot/wapp.4itec.site || exit 1

  echo "🌀 Pulling latest code..."
  git pull origin main || {
    echo "⚠️ Git pull failed. Cloning fresh copy..."
    rm -rf /www/wwwroot/wapp.4itec.site/*
    git clone https://github.com/R2124/WAPP-project.git .
  }

  echo "🔧 Restarting nginx..."
  sudo systemctl reload nginx || sudo systemctl restart nginx || echo "⚠️ nginx restart failed, continuing..."
  echo "✅ Deployment complete on remote server!"
EOF

rm -f /tmp/aapanel_key.pem
echo "🧹 Temporary key removed. Deployment done!"
