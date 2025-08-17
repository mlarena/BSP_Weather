#!/bin/bash

# Проверяем, запущен ли скрипт от root
if [ "$(id -u)" -ne 0 ]; then
    echo "Этот скрипт требует прав root. Используйте sudo."
    exit 1
fi

# Определяем дистрибутив Linux
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "Не удалось определить дистрибутив Linux."
    exit 1
fi

# Установка .NET 9.0 в зависимости от ОС
case $OS in
    ubuntu|debian)
        echo "Установка .NET 9.0 для Ubuntu/Debian..."
        # Добавляем репозиторий Microsoft
        wget https://packages.microsoft.com/config/$OS/$VERSION/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
        dpkg -i packages-microsoft-prod.deb
        rm packages-microsoft-prod.deb
        apt update
        # Устанавливаем компоненты .NET
        apt install -y aspnetcore-runtime-9.0 dotnet-runtime-9.0 dotnet-sdk-9.0
        ;;
    rhel|centos|fedora)
        echo "Установка .NET 9.0 для RHEL/CentOS/Fedora..."
        # Добавляем репозиторий Microsoft
        rpm -Uvh https://packages.microsoft.com/config/$OS/$VERSION/packages-microsoft-prod.rpm
        # Обновляем и устанавливаем .NET
        if [ "$OS" = "fedora" ]; then
            dnf install -y aspnetcore-runtime-9.0 dotnet-runtime-9.0 dotnet-sdk-9.0
        else
            yum install -y aspnetcore-runtime-9.0 dotnet-runtime-9.0 dotnet-sdk-9.0
        fi
        ;;
    *)
        echo "Дистрибутив $OS не поддерживается этим скриптом."
        exit 1
        ;;
esac

# Проверяем успешность установки
if command -v dotnet &> /dev/null; then
    echo ".NET успешно установлен!"
    dotnet --version
else
    echo "Ошибка: .NET не установлен."
    exit 1
fi