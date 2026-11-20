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

Образы `ghcr.io/freespott/freespot-backend` и `ghcr.io/freespott/freespot-frontend` остаются **приватными**. Chart использует `imagePullSecrets: [{name: freespot-registry}]`. Для Kubernetes нужен отдельный Personal access token (classic) с единственным scope `read:packages`, от аккаунта с доступом к обоим пакетам. Не используйте для постоянного imagePullSecret временный `GITHUB_TOKEN` workflow: он истекает после job, а Kubernetes может скачивать образы позже.

Для ручного деплоя с Mac создайте Secret один раз:

```bash
export GHCR_USERNAME=ARCshekin
python3 deploy/k8s/registry-secret.py
```

Скрипт безопасно запросит read token, проверит возможность скачивания обоих пакетов и создаст Kubernetes Secret. Он не читает токен GitHub CLI, не выполняет Docker login и не выводит credentials. В CI токен передаётся через окружение из GitHub Actions secret `GHCR_READ_TOKEN`; логин — из repository variable `GHCR_USERNAME`. Если задан `IMAGE_TAG`, перед обновлением Secret проверяется доступ к точному тегу обоих образов.

После публикации образов CI:

```bash
export IMAGE_TAG=sha-<полный-commit-sha>
deploy/k8s/deploy.sh
```

Для ручной сборки и публикации отдельно выполните Docker login в GHCR с токеном издателя, имеющим `write:packages` (через `docker login ghcr.io -u <логин> --password-stdin`). Токен издателя не сохраняйте в Kubernetes; `freespot-registry` использует только read token:

```bash
export IMAGE_TAG=sha-$(git rev-parse HEAD)
docker buildx build --platform linux/amd64 --push \
  -t "ghcr.io/freespott/freespot-backend:$IMAGE_TAG" backend
docker buildx build --platform linux/amd64 --push \
  --build-arg VITE_BASE_PATH=/team-3/ \
  -t "ghcr.io/freespott/freespot-frontend:$IMAGE_TAG" frontend
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

## CI и ручной Deploy

`ci-cd.yml` запускает backend pytest и проверку Helm на push/PR. На push в `master` или `devops/**` он также собирает amd64-образы, выполняет typecheck/frontend build и публикует в GHCR с тегом `sha-<commit>`. Этот workflow не выполняет деплой.

Отдельный workflow `.github/workflows/deploy.yml` называется **Deploy** и запускается только вручную:

1. После слияния PR в `master` откройте **Actions → Deploy → Run workflow**.
2. Выберите ветку, которую нужно развернуть, и нажмите **Run workflow**.
3. Workflow проверит и соберёт выбранный commit через тот же CI, опубликует приватные образы, проверит read token и обновит imagePullSecret, выполнит Helm-деплой и проверит сайт/API через Ingress.

Кнопка ручного запуска появится после добавления workflow в основную ветку. Запуск доступен участникам с правом записи. Запуск из терминала:

```bash
gh workflow run deploy.yml --repo FreeSpott/FreeSpot --ref master
```

Перед первым запуском:

- Администратор репозитория регистрирует runner `freespot-team-3` в Kubernetes. Манифест `deploy/runner/runner.yaml` запускает официальный GitHub runner без root, без service-account token и без Docker socket; состояние регистрации хранится на отдельном PVC 3 GiB. Он закреплён за узлом team-3 и имеет метки `self-hosted, linux, x64, team-3`. Образы приложения собираются на GitHub hosted runners. Для первоначальной регистрации из сети кластера:

```bash
export KUBECONFIG="$HOME/Downloads/team-3.kubeconfig"
python3 deploy/runner/bootstrap.py
```

Скрипт получает часовой registration token через GitHub API и передаёт его в Kubernetes Secret через stdin. Токен не выводится и не записывается в Git. После первой регистрации runner использует сохранённые на PVC credentials. При потере PVC повторите bootstrap перед запуском нового runner. Не запускайте PR из непроверенных веток на этом runner.
- Collaborator может добавить repository secret `KUBECONFIG`: полное содержимое `team-3.kubeconfig`, без base64-кодирования, через **Settings → Secrets and variables → Actions → New repository secret**. Либо с Mac:

```bash
gh secret set KUBECONFIG --repo FreeSpott/FreeSpot < "$HOME/Downloads/team-3.kubeconfig"
```

Для приватных образов добавьте repository secret `GHCR_READ_TOKEN` с отдельным PAT classic, scope только `read:packages`, и repository variable `GHCR_USERNAME` с логином владельца PAT (сейчас `ARCshekin`). Токен создаётся в личных **Settings → Developer settings → Personal access tokens → Tokens (classic)**, а не fine-grained tokens. Аккаунт должен иметь read-доступ к обоим пакетам. При обязательном SSO организации авторизуйте токен для неё.

```bash
gh secret set GHCR_READ_TOKEN --repo FreeSpott/FreeSpot
gh variable set GHCR_USERNAME --repo FreeSpott/FreeSpot --body ARCshekin
```

Первая команда интерактивно запросит токен; не указывайте его в аргументах команды или в Git. Перед истечением срока PAT замените GitHub secret и вручную запустите Deploy, чтобы обновился Kubernetes Secret. Обновление пароля в GitHub secret само по себе не меняет Secret в кластере. Сбой проверки credentials прерывает workflow до изменения Helm-релиза и Kubernetes pull-secret.

Переменная `DEPLOY_ENABLED` не используется. Деплой на push, merge или по расписанию не запускается. Обновления одного namespace сериализуются, Helm откатывает неудачный релиз (`--atomic` в Helm 3, `--rollback-on-failure` в Helm 4). Проверка Ingress выполняется после Helm; при её ошибке workflow завершится неуспешно, установленный релиз останется для диагностики.

Первый запуск допускает до 15 минут на скачивание образов по медленному каналу. GitHub hosted runner не имеет прямого маршрута в приватную сеть кластера.

## Обслуживание

```bash
kubectl -n team-3 get pods,pvc
kubectl -n team-3 logs deployment/freespot-backend --tail=100
helm -n team-3 history freespot
helm -n team-3 rollback freespot <REVISION> --wait --timeout 5m
```

Перед изменениями схемы делайте backup PostgreSQL. Откат Helm меняет конфигурацию приложения, но не откатывает данные БД. API-ключ для датчиков хранится в `freespot-secrets`, ключ `api-key`; не включайте его в frontend bundle.
