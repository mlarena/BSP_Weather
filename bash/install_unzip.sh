#!/bin/bash

# Обновление списка пакетов
sudo apt update

# Установка unzip
sudo apt install -y unzip

# Проверка успешной установки
if command -v unzip &> /dev/null
then
    echo "unzip успешно установлен"
else
    echo "Ошибка при установке unzip"
    exit 1
fi
