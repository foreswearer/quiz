#!/bin/bash
set -e

echo "=== Deploying Quiz Platform (STAGING) ==="

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
pip install -r requirements.txt --quiet

# Restart the staging service
sudo systemctl restart quiz-backend-staging.service

echo "=== Staging deployment complete ==="