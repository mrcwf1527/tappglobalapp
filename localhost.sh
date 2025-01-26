#!/bin/bash

# Source the .env file
set -a
source .env
set +a

# Run Flutter web app with specific port and hostname
flutter run -d chrome --web-port 50000 --web-hostname localhost