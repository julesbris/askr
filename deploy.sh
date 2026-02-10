#!/bin/bash

# Training System Deployment Script with Server-Side File Upload
# Run this on your server (79.108.224.58)

echo "🚀 Deploying Training System with Server-Side File Upload..."

# Navigate to project directory
cd /var/www/training-system

# Create uploads directory with proper permissions
echo "📁 Creating uploads directory..."
mkdir -p /var/www/training-system/uploads/certificates
chmod 755 /var/www/training-system/uploads/certificates
chown www-data:www-data /var/www/training-system/uploads/certificates

# Create API directory for PHP upload handler
echo "📝 Setting up API..."
mkdir -p /var/www/training-system/html/api
chmod 755 /var/www/training-system/html/api

# Copy upload.php to API directory (you'll need to upload this file first)
# cp /path/to/upload.php /var/www/training-system/html/api/upload.php
# chmod 644 /var/www/training-system/html/api/upload.php

echo "✅ Directories created!"
echo ""
echo "📋 Next steps:"
echo "1. Upload upload.php to /var/www/training-system/html/api/upload.php"
echo "2. Upload training_management_with_matrix.html to /var/www/training-system/html/index.html"
echo "3. Restart Docker: docker-compose restart web"
echo ""
echo "🌐 Files will be stored in: /var/www/training-system/uploads/certificates/"
echo "🔗 Accessible via: http://app.askr.com.au/uploads/certificates/filename"
