# Kubernetes: team-3

Основа — [quiner1793/devops-templates](https://github.com/quiner1793/devops-templates), разделы `2_k8s_deploy` и `4_github_actions`. Шаблоны адаптированы под React/nginx, FastAPI и PostgreSQL. Chart не устанавливает общекластерные компоненты и не меняет существующие политики namespace.

## Что разворачивается

- PostgreSQL 16: StatefulSet, том `local-path` 5 GiB, только внутренний Service.
- Один backend: старт после готовности БД, автоматическая инициализация схемы, readiness `/ready`, liveness `/health`. Одна реплика предотвращает одновременный seed и запуск нескольких симуляторов.
- Frontend: nginx без root, сборка с base `/team-3/`, прокси к API.
- Traefik Ingress `/team-3`, strip-prefix Middleware и разрешение Traefik в NetworkPolicy.
- Все Pods закреплены за узлом `student-team=team-3`, с соответствующей toleration.

Постоянный том сохраняется при `helm uninstall`. `local-path` привязан к узлу и не является резервной копией. PostgreSQL в одной реплике; backend обновляется с короткой остановкой (`Recreate`).

Compose остаётся отдельным вариантом локального запуска со стеком наблюдаемости. Этот chart разворачивает приложение и БД; `/metrics` доступен внутри кластера на `freespot-backend:8000`.

## Первый запуск с Mac

Требуются Docker Buildx, kubectl, Helm 3.18+ или 4 и GitHub CLI. Кластер доступен из приватной сети.

```bash
export KUBECONFIG="$HOME/Downloads/team-3.kubeconfig"
```

Опубликованные CI образы публичны, авторизация для деплоя не нужна. Для приватных пакетов выполните `gh auth refresh -h github.com -s read:packages` и `python3 deploy/k8s/registry-secret.py`, затем передайте деплою `--set imagePullSecrets[0].name=freespot-registry`.

`registry-secret.py` читает токен из keychain через `gh`, создаёт `freespot-registry` и выполняет Docker login через stdin. Токен не выводится и не попадает в аргументы процессов. Аккаунт должен иметь доступ к пакетам `ghcr.io/brevolg/freespot-backend` и `ghcr.io/brevolg/freespot-frontend` (для ручной публикации — также право записи).

После публикации образов CI:

```bash
export IMAGE_TAG=sha-<полный-commit-sha>
deploy/k8s/deploy.sh
```

Для ручной сборки и публикации сначала выполните `gh auth refresh -h github.com -s read:packages,write:packages` и `python3 deploy/k8s/registry-secret.py`:

```bash
export IMAGE_TAG=sha-$(git rev-parse HEAD)
docker buildx build --platform linux/amd64 --push \
  -t "ghcr.io/brevolg/freespot-backend:$IMAGE_TAG" backend
docker buildx build --platform linux/amd64 --push \
  --build-arg VITE_BASE_PATH=/team-3/ \
  -t "ghcr.io/brevolg/freespot-frontend:$IMAGE_TAG" frontend
deploy/k8s/deploy.sh
```

Публикуйте тег только из чистого рабочего дерева и не перезаписывайте выпущенные теги.

`bootstrap-secrets.py` создаёт случайные пароль БД и API-ключ только при отсутствии Secret. Повторный деплой их не меняет. Не удаляйте Secret при сохранённом томе PostgreSQL: смена переменной `POSTGRES_PASSWORD` не меняет пароль внутри уже созданной БД.

## Адрес и проверка

```bash
kubectl -n team-3 get ingress freespot
# Используйте один из адресов ADDRESS:
curl -f http://<ADDRESS>/team-3/ready
curl -f http://<ADDRESS>/team-3/api/spots
python3 deploy/k8s/verify.py http://<ADDRESS>/team-3/
```

Приложение: `http://<ADDRESS>/team-3/` (со слешем в конце). Swagger: `http://<ADDRESS>/team-3/docs`. Адреса находятся в приватной сети; chart не выпускает TLS-сертификат.

Для локальной проверки без Ingress:

```bash
kubectl -n team-3 port-forward svc/freespot-frontend 18080:80
# Статика собрана с префиксом /team-3/, поэтому полную UI-проверку выполняйте через Ingress.
curl -f http://localhost:18080/ready
```

## CI/CD

`.github/workflows/ci-cd.yml`:

1. На push/PR — backend pytest и проверка Helm.
2. На push в `master` или `devops/**` — сборка amd64-образов, typecheck/frontend build и публикация в GHCR с тегом `sha-<commit>`.
3. На `master`, если repository variable `DEPLOY_ENABLED=true`, — деплой через runner с метками `self-hosted, linux, team-3`. Обновления одного namespace сериализуются, Helm откатывает неудачный релиз (`--atomic` в Helm 3, `--rollback-on-failure` в Helm 4).

Для включения автодеплоя администратору репозитория необходимо:

- Подключить Linux self-hosted runner с меткой `team-3` в сети с доступом к `10.93.26.212:6443`. Runner должен иметь Python 3, bash, curl, tar и доступ к GitHub; kubectl и Helm устанавливает workflow. Не запускайте PR из непроверенных веток на этом runner.
- Добавить repository secret `KUBECONFIG`: полное содержимое `team-3.kubeconfig`.
- Убедиться, что packages доступны workflow (наследование разрешений от `Brevolg/FreeSpot`); при приватных пакетах настройте `imagePullSecrets`.
- Добавить repository variable `DEPLOY_ENABLED=true` после подключения runner.

Для приватных пакетов начальная загрузка registry credentials выполняется локально один раз. Следите за сроком токена; после ротации повторите `registry-secret.py`. GitHub hosted runner не имеет прямого маршрута в приватную сеть кластера.

## Обслуживание

```bash
kubectl -n team-3 get pods,pvc
kubectl -n team-3 logs deployment/freespot-backend --tail=100
helm -n team-3 history freespot
helm -n team-3 rollback freespot <REVISION> --wait --timeout 5m
```

Перед изменениями схемы делайте backup PostgreSQL. Откат Helm меняет конфигурацию приложения, но не откатывает данные БД. API-ключ для датчиков хранится в `freespot-secrets`, ключ `api-key`; не включайте его в frontend bundle.
