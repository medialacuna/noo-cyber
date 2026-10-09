#!/usr/bin/env bash
# RTD.MUAR — установка на домашний сервер (Ubuntu/Debian, нужен Docker + Compose v2)
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== 1. Проверка окружения =="
command -v docker >/dev/null || { echo "Docker не установлен: curl -fsSL https://get.docker.com | sh"; exit 1; }
docker compose version >/dev/null || { echo "Нет Compose v2"; exit 1; }

echo "== 2. Секрет =="
if [ ! -f .env ]; then
  echo "SECRET_KEY=$(openssl rand -hex 32)" > .env
  echo "создан .env с SECRET_KEY"
fi

echo "== 3. Сборка фронта (если нет node — пропустит, используй готовый dist из репо) =="
if command -v npm >/dev/null; then (cd frontend && npm ci && npm run build); else echo "npm нет — беру frontend/dist из git"; fi

echo "== 4. Импорт Комарово в контейнер (18 пьес) =="
cp -r data backend/data_build_tmp 2>/dev/null || true

echo "== 5. Запуск =="
docker compose up -d --build

echo "== 6. Инициализация БД + пьесы =="
docker compose exec -T backend python -m app.import_komarovo || true

echo ""
echo "Готово. Проверка: curl http://localhost/api/health"
echo "HTTPS: поставь Caddy перед контейнером или сертифицируй через acme.sh (см. DEPLOY.md)"
