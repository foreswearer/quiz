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

# Upgrade pip
pip install --upgrade pip --quiet

# Install uvicorn explicitly (in case it's missing from requirements)
pip install uvicorn --quiet

# Install/update dependencies
pip install -r requirements.txt --quiet

# Verify uvicorn exists
if [ ! -f "venv/bin/uvicorn" ]; then
    echo "ERROR: uvicorn not found after install!"
    exit 1
fi

# Restart the staging service
sudo systemctl restart quiz-backend-staging.service

echo "=== Staging deployment complete ==="