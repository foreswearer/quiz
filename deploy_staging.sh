#!/bin/bash
set -e

echo "=== Deploying Quiz Platform (STAGING) ==="

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
pip install -r requirements.txt --quiet

# Restart the staging service
sudo systemctl restart quiz-backend-staging.service

echo "=== Staging deployment complete ==="