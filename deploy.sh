#!/bin/bash

# Source the .env file
set -a
source .env
set +a

# Build with explicit variable passing
flutter build web \
  --dart-define=FIREBASE_API_KEY_WEB=$FIREBASE_API_KEY_WEB \
  --dart-define=AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  --dart-define=AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  --dart-define=AWS_REGION=$AWS_REGION \
  --dart-define=AWS_BUCKET=$AWS_BUCKET \
  --dart-define=AWS_DOMAIN=$AWS_DOMAIN

# Set CORS configuration for Firebase Storage
echo "Setting CORS configuration for Firebase Storage..."
gsutil cors set cors.json gs://tappglobal-app.firebasestorage.app

# Deploy
echo "Deploying to Firebase..."
firebase deploy

echo "Deployment complete!"