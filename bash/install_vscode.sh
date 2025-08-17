#!/bin/bash

# Обновление списка пакетов
sudo apt update

# Установка зависимостей
sudo apt install -y software-properties-common apt-transport-https wget

# Импорт ключа репозитория Microsoft GPG
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/

# Включение репозитория VS Code
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

# Обновление списка пакетов с новым репозиторием
sudo apt update

# Установка Visual Studio Code
sudo apt install -y code

# Удаление временных файлов
rm packages.microsoft.gpg

