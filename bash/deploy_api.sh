#!/bin/bash

# Parameters
PROJECT_SOLUTION_DIR="/temp_project/BSP_Weather"
PUBLISH_OUTPUT_DIR="/burstroy/BSP_Weather"
LOGS_DIR="$PUBLISH_OUTPUT_DIR/logs"
SERVICE_NAME="bsp_weather"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
NGINX_CONFIG_FILE="/etc/nginx/sites-available/${SERVICE_NAME}"
APP_DLL="BSP_Weather.dll"  # Ensure this matches the actual DLL name
DOMAIN_OR_IP="localhost"   # Replace with your domain or IP
PORT="5000"               # Default .NET Core port

# Exit on any error
set -e

# 1. Clean and publish the application
echo "Cleaning and publishing .NET application..."
if [ -d "$PUBLISH_OUTPUT_DIR" ]; then
    echo "Removing existing publish directory: $PUBLISH_OUTPUT_DIR"
    sudo rm -rf "$PUBLISH_OUTPUT_DIR"
fi
mkdir -p "$PUBLISH_OUTPUT_DIR"
mkdir -p "$LOGS_DIR"

cd "$PROJECT_SOLUTION_DIR" || { echo "Error: Cannot access $PROJECT_SOLUTION_DIR"; exit 1; }
dotnet publish -c Release -o "$PUBLISH_OUTPUT_DIR"

if [ $? -ne 0 ]; then
    echo "Error: dotnet publish failed"
    exit 1
fi

echo "Application published to $PUBLISH_OUTPUT_DIR"

# 2. Set permissions for the publish and logs directories
echo "Setting permissions for $PUBLISH_OUTPUT_DIR and $LOGS_DIR..."
sudo chown -R www-data:www-data "$PUBLISH_OUTPUT_DIR"
sudo chmod -R 755 "$PUBLISH_OUTPUT_DIR"
sudo chmod -R 775 "$LOGS_DIR"

# 3. Create systemd service
echo "Creating systemd service..."
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=BSP Weather .NET Web API Application
After=network.target

[Service]
WorkingDirectory=$PUBLISH_OUTPUT_DIR
ExecStart=/usr/bin/dotnet $PUBLISH_OUTPUT_DIR/$APP_DLL
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=dotnet-$SERVICE_NAME
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
Environment=ASPNETCORE_URLS=http://localhost:$PORT

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 "$SERVICE_FILE"
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

if [ $? -ne 0 ]; then
    echo "Error: Failed to start $SERVICE_NAME service"
    exit 1
fi

echo "Service $SERVICE_NAME created and started"

# 4. Create Nginx configuration
echo "Creating Nginx configuration..."
sudo tee "$NGINX_CONFIG_FILE" > /dev/null <<'NGINX_CONFIG'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /swagger {
        proxy_pass http://localhost:5000/swagger;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_CONFIG

# 5. Activate Nginx configuration
sudo ln -sf "$NGINX_CONFIG_FILE" "/etc/nginx/sites-enabled/"
[ -f "/etc/nginx/sites-enabled/default" ] && sudo rm -f "/etc/nginx/sites-enabled/default"

# Check Nginx configuration
if ! sudo nginx -t; then
    echo "Error: Nginx configuration test failed"
    echo "Last 20 lines of Nginx error log:"
    sudo tail -n 20 /var/log/nginx/error.log
    exit 1
fi

sudo systemctl restart nginx
if [ $? -ne 0 ]; then
    echo "Error: Failed to restart Nginx"
    exit 1
fi
echo "Nginx configuration successfully activated"

# 6. Verify services
echo -e "\nService status:"
sudo systemctl status "$SERVICE_NAME" --no-pager || true

echo -e "\nNginx status:"
sudo systemctl status nginx --no-pager || true

echo -e "\nDeployment completed!"
echo "Application should be available at: http://${DOMAIN_OR_IP}"
echo "Swagger UI should be available at: http://${DOMAIN_OR_IP}/swagger"