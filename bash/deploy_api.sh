#!/bin/bash

# Параметры
PROJECT_SOLUTION_DIR="/temp_project/BSP_Weather"
PUBLISH_OUTPUT_DIR="/burstroy/BSP_Weather"
SERVICE_NAME="bsp_weather"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
NGINX_CONFIG_FILE="/etc/nginx/sites-available/${SERVICE_NAME}"
APP_DLL="BSP_Weather.dll"  # Убедитесь, что это правильное имя DLL
DOMAIN_OR_IP="localhost"   # Замените на ваш домен или IP

# 1. Публикация приложения
echo "Publishing .NET application..."
cd "$PROJECT_SOLUTION_DIR" || exit 1
dotnet publish -c Release -o "$PUBLISH_OUTPUT_DIR"

if [ $? -ne 0 ]; then
    echo "Error: dotnet publish failed"
    exit 1
fi

echo "Application published to $PUBLISH_OUTPUT_DIR"

# 2. Создание systemd службы
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

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 "$SERVICE_FILE"
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

echo "Service $SERVICE_NAME created and started"

# 3. Создание конфигурации Nginx (исправленная версия)
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

# Активация конфигурации
sudo ln -sf "$NGINX_CONFIG_FILE" "/etc/nginx/sites-enabled/"
[ -f "/etc/nginx/sites-enabled/default" ] && sudo rm -f "/etc/nginx/sites-enabled/default"

# Проверка конфигурации
if ! sudo nginx -t; then
    echo "Error: Nginx configuration test failed"
    echo "Last 20 lines of Nginx error log:"
    sudo tail -n 20 /var/log/nginx/error.log
    exit 1
fi

sudo systemctl restart nginx
echo "Nginx configuration successfully activated"

# Проверка статусов
echo -e "\nService status:"
sudo systemctl status "$SERVICE_NAME" --no-pager

echo -e "\nNginx status:"
sudo systemctl status nginx --no-pager

echo -e "\nDeployment completed!"
echo "Application should be available at: http://${DOMAIN_OR_IP}"