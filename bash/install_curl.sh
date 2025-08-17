#!/bin/bash

# Обновление списка пакетов
sudo apt-get update

# Установка curl
sudo apt-get install -y curl

# Проверка успешной установки
if command -v curl &> /dev/null
then
    echo "curl успешно установлен"
else
    echo "Ошибка при установке curl"
    exit 1
fi
