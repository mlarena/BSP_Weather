#!/bin/bash

# Имена сервисов
services=("burstroy-api.service" "burstroy-data.service" "burstroy-web.service")

# Перебираем каждый сервис и останавливаем его
for service in "${services[@]}"; do
  echo "Остановка сервиса: $service"
  sudo systemctl stop "$service"
  if [ $? -eq 0 ]; then
    echo "Сервис $service успешно остановлен"
  else
    echo "Ошибка при остановке сервиса $service"
  fi
done
