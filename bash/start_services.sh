#!/bin/bash

# Имена сервисов
services=("burstroy-api.service" "burstroy-data.service" "burstroy-web.service")

# Перебираем каждый сервис и запускаем его
for service in "${services[@]}"; do
  echo "Запуск сервиса: $service"
  sudo systemctl start "$service"
  if [ $? -eq 0 ]; then
    echo "Сервис $service успешно запущен"
  else
    echo "Ошибка при запуске сервиса $service"
  fi
done
