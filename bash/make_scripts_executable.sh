#!/bin/bash

# Перебор всех файлов в текущей директории
for file in *; do
    # Проверка, является ли файл bash скриптом
    if [[ -f "$file" && "$file" == *.sh ]]; then
        # Делаем файл исполняемым
        chmod +x "$file"
        echo "Скрипт $file сделан исполняемым"
    fi
done
