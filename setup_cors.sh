#!/bin/bash

# ─── SkyFit Pro — Firebase Storage CORS Setup ─────────────────────────────────

BUCKET="gs://skyfit-pro.firebasestorage.app"
CORS_FILE="cors.json"

echo "📦 Creating $CORS_FILE..."

cat > $CORS_FILE << 'EOF'
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE", "HEAD"],
    "maxAgeSeconds": 3600,
    "responseHeader": [
      "Content-Type",
      "Authorization",
      "Content-Length",
      "User-Agent"
    ]
  }
]
EOF

echo "✅ $CORS_FILE created."
echo ""
echo "🚀 Applying CORS rules to $BUCKET..."
gsutil cors set $CORS_FILE $BUCKET

echo ""
echo "🔍 Verifying CORS rules..."
gsutil cors get $BUCKET

echo ""
echo "✅ Done! Firebase Storage CORS is configured for SkyFit Pro."
