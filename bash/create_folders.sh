#!/bin/bash

# 1. Создать папку burstroy в корне (требует прав sudo)
sudo mkdir -p /burstroy

# 2. Создать папку BSP_Weather внутри burstroy
sudo mkdir -p /burstroy/BSP_Weather

# 3. Установить правильные права (опционально)
sudo chmod 755 /burstroy
sudo chmod 755 /burstroy/BSP_Weather

# Проверить результат
echo "Проверка созданных папок:"
ls -ld /burstroy
ls -ld /burstroy/BSP_Weather