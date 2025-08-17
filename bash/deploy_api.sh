#!/bin/bash

# Параметры
PROJECT_SOLUTION_DIR="/temp_project/BSP_Weather"
PUBLISH_OUTPUT_DIR="/burstroy/BSP_Weather"
SERVICE_NAME="bsp_weather"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
NGINX_CONFIG_FILE="/etc/nginx/sites-available/${SERVICE_NAME}"
APP_DLL="BSP_Weather.dll"  # Замените на имя вашего основного DLL файла
DOMAIN_OR_IP="localhost"   # Замените на ваш домен или IP

# 1. Публикация приложения
echo "Publishing .NET application..."
cd "$PROJECT_SOLUTION_DIR"
dotnet publish -c Release -o "$PUBLISH_OUTPUT_DIR"

if [ $? -ne 0 ]; then
    echo "Error: dotnet publish failed"
    exit 1
fi

echo "Application published to $PUBLISH_OUTPUT_DIR"

# 2. Создание systemd службы
echo "Creating systemd service..."
sudo bash -c "cat > $SERVICE_FILE <<'EOF'
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
EOF"

# Установка прав на файл службы
sudo chmod 644 $SERVICE_FILE

# Активация и запуск службы
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo "Service $SERVICE_NAME created and started"

# 3. Создание конфигурации Nginx
echo "Creating Nginx configuration..."
sudo bash -c "cat > $NGINX_CONFIG_FILE <<'EOF'
server {
    listen        80;
    server_name   $DOMAIN_OR_IP;

    location / {
        proxy_pass         http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection \"upgrade\";
        proxy_set_header   Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
    }
}
EOF"

# Активация конфигурации Nginx
sudo ln -sf "$NGINX_CONFIG_FILE" "/etc/nginx/sites-enabled/"
sudo rm -f /etc/nginx/sites-enabled/default

# Проверка и перезагрузка Nginx
if ! sudo nginx -t; then
    echo "Error: Nginx configuration test failed"
    echo "Showing Nginx error log for debugging:"
    sudo tail -n 20 /var/log/nginx/error.log
    exit 1
fi

sudo systemctl restart nginx

echo "Nginx configuration created and activated"

# 4. Проверка работы
echo "Checking service status..."
sudo systemctl status $SERVICE_NAME

echo "Checking Nginx status..."
sudo systemctl status nginx

echo "Deployment completed successfully!"
echo "Application should be available at: http://$DOMAIN_OR_IP"