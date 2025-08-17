#!/bin/bash

# Получение версии операционной системы
echo "Версия операционной системы:"
lsb_release -a

# Получение информации о свободном и занимаемом пространстве памяти
echo -e "\nИнформация о памяти:"
free -h

# Получение информации о железе
echo -e "\nИнформация о железе:"
sudo lshw -short

# Получение информации о температуре процессора
echo -e "\nТемпература процессора:"
sensors

# Проверка наличия утилиты sensors
if ! command -v sensors &> /dev/null; then
    echo "Утилита lm-sensors не установлена. Установка..."
    sudo apt-get update
    sudo apt-get install lm-sensors
    sudo sensors-detect
fi

# Повторное получение информации о температуре процессора
echo -e "\nТемпература процессора:"
sensors