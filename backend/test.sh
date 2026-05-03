#!/bin/bash
# Test script for local development

echo "Running FindAny tests..."

# Install test dependencies if not already installed
pip install pytest pytest-cov flake8 black isort mypy

# Run linting
echo "Running flake8..."
flake8 app.py --count --select=E9,F63,F7,F82 --show-source --statistics || exit 1

# Run tests
echo "Running pytest..."
python -m pytest --cov=app --cov-report=term-missing -v || exit 1

echo "All tests passed!"