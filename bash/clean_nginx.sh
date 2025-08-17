#!/bin/bash

# Останавливаем службу Nginx
echo "Останавливаем службу Nginx..."
sudo systemctl stop nginx

# Удаляем все символические ссылки в sites-enabled
echo "Удаляем все символические ссылки в /etc/nginx/sites-enabled..."
sudo rm -f /etc/nginx/sites-enabled/*

# Удаляем все конфигурационные файлы в sites-available
echo "Удаляем все конфигурационные файлы в /etc/nginx/sites-available..."
sudo rm -f /etc/nginx/sites-available/*

# Удаляем стандартный конфигурационный файл
echo "Удаляем стандартный конфигурационный файл /etc/nginx/nginx.conf..."
sudo rm -f /etc/nginx/nginx.conf

# Удаляем другие конфигурационные файлы в /etc/nginx/conf.d/
echo "Удаляем конфигурационные файлы в /etc/nginx/conf.d/..."
sudo rm -f /etc/nginx/conf.d/*

# Удаляем кэш Nginx (если есть)
echo "Удаляем кэш Nginx (если есть)..."
sudo rm -rf /var/cache/nginx/*

# Удаляем логи Nginx (если есть)
echo "Удаляем логи Nginx (если есть)..."
sudo rm -rf /var/log/nginx/*

echo "Очистка Nginx завершена."
