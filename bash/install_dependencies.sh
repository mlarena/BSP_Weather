#!/bin/bash

# Обновление списка пакетов
sudo apt-get update

# Установка зависимостей
sudo apt-get install -y \
    ca-certificates \
    libc6 \
    libgcc-s1 \
    libgssapi-krb5-2 \
    libicu70 \
    liblttng-ust1 \
    libssl3 \
    libstdc++6 \
    libunwind8 \
    zlib1g

# Проверка успешности установки
if [ $? -eq 0 ]; then
    echo "Все зависимости успешно установлены."
else
    echo "Ошибка при установке зависимостей."
fi