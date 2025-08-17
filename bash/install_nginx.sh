#!/bin/bash

# Обновление списка пакетов
sudo apt update

# Установка Nginx
sudo apt install -y nginx

# Проверка успешной установки
if command -v nginx &> /dev/null
then
    echo "Nginx успешно установлен."

    # Получение версии Nginx
    nginx_version=$(nginx -v 2>&1 | grep -oE 'nginx/[0-9]+\.[0-9]+\.[0-9]+')
    echo "Версия Nginx: $nginx_version"

    # Запуск Nginx
    sudo systemctl start nginx

    # Включение Nginx в автозагрузку
    sudo systemctl enable nginx

    echo "Nginx запущен и добавлен в автозагрузку."
else
    echo "Ошибка установки Nginx."
fi