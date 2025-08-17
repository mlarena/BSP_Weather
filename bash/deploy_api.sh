#!/bin/bash

# Parameters
PROJECT_SOLUTION_DIR="/temp_project/BSP_Weather"
PROJECT_FILE="$PROJECT_SOLUTION_DIR/BSP_Weather.csproj"
PUBLISH_OUTPUT_DIR="/burstroy/BSP_Weather"
LOGS_DIR="$PUBLISH_OUTPUT_DIR/logs"
SERVICE_NAME="bsp_weather"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
NGINX_CONFIG_FILE="/etc/nginx/sites-available/${SERVICE_NAME}"
APP_DLL="BSP_Weather.dll"
APPSETTINGS_FILE="appsettings.json"
DOMAIN_OR_IP="localhost"
PORT="5000"

# Exit on any error
set -e

# 1. Check dependencies
echo "Checking for required dependencies..."
if ! command -v dotnet >/dev/null 2>&1; then
    echo "Error: .NET SDK is not installed. Please install it."
    exit 1
fi
if ! dpkg -l | grep -q aspnetcore-runtime; then
    echo "Error: ASP.NET Core runtime is not installed. Install it with: sudo apt-get install -y aspnetcore-runtime-9.0"
    exit 1
fi

# 2. Clean and publish the application
echo "Cleaning and publishing .NET application..."
if [ -d "$PUBLISH_OUTPUT_DIR" ]; then
    echo "Removing existing publish directory: $PUBLISH_OUTPUT_DIR"
    sudo rm -rf "$PUBLISH_OUTPUT_DIR"
fi
mkdir -p "$PUBLISH_OUTPUT_DIR"
mkdir -p "$LOGS_DIR"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Project file $PROJECT_FILE not found"
    exit 1
fi

cd "$PROJECT_SOLUTION_DIR" || { echo "Error: Cannot access $PROJECT_SOLUTION_DIR"; exit 1; }
dotnet publish "$PROJECT_FILE" -c Release -o "$PUBLISH_OUTPUT_DIR"

if [ $? -ne 0 ]; then
    echo "Error: dotnet publish failed"
    exit 1
fi

# Verify DLL exists
if [ ! -f "$PUBLISH_OUTPUT_DIR/$APP_DLL" ]; then
    echo "Error: $APP_DLL not found in $PUBLISH_OUTPUT_DIR"
    exit 1
fi

# Verify appsettings.json exists
if [ ! -f "$PUBLISH_OUTPUT_DIR/$APPSETTINGS_FILE" ]; then
    echo "Error: $APPSETTINGS_FILE not found in $PUBLISH_OUTPUT_DIR"
    if [ -f "$PROJECT_SOLUTION_DIR/$APPSETTINGS_FILE" ]; then
        echo "Copying $APPSETTINGS_FILE to $PUBLISH_OUTPUT_DIR"
        cp "$PROJECT_SOLUTION_DIR/$APPSETTINGS_FILE" "$PUBLISH_OUTPUT_DIR/$APPSETTINGS_FILE"
    else
        echo "Error: $APPSETTINGS_FILE not found in $PROJECT_SOLUTION_DIR"
        exit 1
    fi
fi

# 3. Set permissions
echo "Setting permissions for $PUBLISH_OUTPUT_DIR, $LOGS_DIR, and $APPSETTINGS_FILE..."
sudo chown -R www-data:www-data "$PUBLISH_OUTPUT_DIR"
sudo chmod -R 755 "$PUBLISH_OUTPUT_DIR"
sudo chmod -R 775 "$LOGS_DIR"
sudo chmod 644 "$PUBLISH_OUTPUT_DIR/$APPSETTINGS_FILE"

# Verify permissions
echo "Verifying permissions for $LOGS_DIR..."
ls -ld "$LOGS_DIR"
echo "Verifying permissions for $APPSETTINGS_FILE..."
ls -l "$PUBLISH_OUTPUT_DIR/$APPSETTINGS_FILE"

# 4. Create systemd service
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
sudo systemctl restart "$SERVICE_NAME"

if [ $? -ne 0 ]; then
    echo "Error: Failed to start $SERVICE_NAME service"
    sudo journalctl -u "$SERVICE_NAME" -n 50
    exit 1
fi

# Wait briefly to allow the service to start
sleep 5

# 5. Verify application is running
echo "Checking if application is responding on port $PORT..."
if curl -s http://localhost:$PORT/swagger/v1/swagger.json >/dev/null; then
    echo "Application is responding at http://localhost:$PORT/swagger/v1/swagger.json"
else
    echo "Error: Application is not responding at http://localhost:$PORT/swagger/v1/swagger.json"
    sudo journalctl -u "$SERVICE_NAME" -n 50
    exit 1
fi

# 6. Create Nginx configuration
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
}
NGINX_CONFIG

# 7. Activate Nginx configuration
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
    sudo tail -n 50 /var/log/nginx/error.log
    exit 1
fi
echo "Nginx configuration successfully activated"

# 8. Verify Nginx is serving the application
echo "Checking if Swagger UI is accessible via Nginx..."
if curl -s http://$DOMAIN_OR_IP/swagger >/dev/null; then
    echo "Swagger UI is accessible at http://$DOMAIN_OR_IP/swagger"
else
    echo "Error: Swagger UI is not accessible at http://$DOMAIN_OR_IP/swagger"
    sudo tail -n 50 /var/log/nginx/error.log
    sudo journalctl -u "$SERVICE_NAME" -n 50
    exit 1
fi

# 9. Verify logs directory
echo "Checking logs directory: $LOGS_DIR"
if [ -z "$(ls -A $LOGS_DIR)" ]; then
    echo "Warning: Logs directory is empty. Check application logs in journalctl:"
    sudo journalctl -u "$SERVICE_NAME" -n 50
    echo "Attempting to test log file creation..."
    sudo -u www-data touch "$LOGS_DIR/test.log"
    if [ $? -eq 0 ]; then
        echo "Test log file created successfully by www-data"
        rm "$LOGS_DIR/test.log"
    else
        echo "Error: www-data cannot write to $LOGS_DIR"
        exit 1
    fi
else
    echo "Logs found in $LOGS_DIR:"
    ls -l "$LOGS_DIR"
fi

# 10. Display service statuses
echo -e "\nService status:"
sudo systemctl status "$SERVICE_NAME" --no-pager || true

echo -e "\nNginx status:"
sudo systemctl status nginx --no-pager || true

echo -e "\nDeployment completed!"
echo "Application should be available at: http://${DOMAIN_OR_IP}"
echo "Swagger UI should be available at: http://${DOMAIN_OR_IP}/swagger"