# goit-devops-hw-08-09

***Технiчний опис завдань***

# **Завдання 8-9: Вивчення Jenkins CI + ArgoCD + CD**

## **Опис завдання:**

Ваша мета — реалізувати повний **CI/CD-процес** із використанням `Jenkins` + `Helm` + `Terraform` + `Argo CD`, який:

1. **Автоматично збирає Docker-образ** для Django-застосунку
2. **Публікує образ в Amazon ECR**
3. **Оновлює Helm chart** у репозиторії з правильним тегом
4. **Синхронізує застосунок у кластері через Argo CD**, який підхоплює зміни з Git

## **Кроки виконання завдання:**

1. **Jenkins + Helm + Terraform:**
   - Встановіть `Jenkins` через `Helm`, автоматизувавши встановлення через `Terraform`
   - Забезпечте роботу `Jenkins` через `Kubernetes Agent` (`Kaniko` + `Git`)
   - Реалізуйте pipeline (через `Jenkinsfile`), який:
       - Збирає образ із `Dockerfile`
       - Пушить його до `ECR`
       - Оновлює тег у `values.yaml` іншого репозиторію
       - Пушить зміни в `main`

2. **Argo CD + Helm + Terraform:**
   - Встановіть Argo CD через Helm із використанням Terraform
   - Налаштуйте Argo CD Application, який стежить за оновленням Helm-чарта
   - Argo CD має автоматично синхронізувати зміни у кластері після оновлення Git

**Структура проекту:**

```md
goit-devops-hw-08-09/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB
├── outputs.tf               # Загальні виводи ресурсів
│
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакета
│   │   ├── dynamodb.tf      # Створення DynamoDB
│   │   ├── variables.tf     # Змінні для S3
│   │   └── outputs.tf       # Виведення інформації про S3 та DynamoDB
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf        # Налаштування маршрутизації
│   │   ├── variables.tf     # Змінні для VPC
│   │   └── outputs.tf
│   ├── ecr/                 # Модуль для ECR
│   │   ├── ecr.tf           # Створення ECR репозиторію
│   │   ├── variables.tf     # Змінні для ECR
│   │   └── outputs.tf       # Виведення URL репозиторію
│   │
│   ├── eks/                      # Модуль для Kubernetes кластера
│   │   ├── eks.tf                # Створення кластера
│   │   ├── aws_ebs_csi_driver.tf # Встановлення плагіну csi drive
│   │   ├── variables.tf     # Змінні для EKS
│   │   └── outputs.tf       # Виведення інформації про кластер
│   │
│   ├── jenkins/             # Модуль для Helm-установки Jenkins
│   │   ├── jenkins.tf       # Helm release для Jenkins
│   │   ├── variables.tf     # Змінні (ресурси, креденшели, values)
│   │   ├── providers.tf     # Оголошення провайдерів
│   │   ├── values.yaml      # Конфігурація jenkins
│   │   └── outputs.tf       # Виводи (URL, пароль адміністратора)
│   │
│   └── argo_cd/             # ✅ Новий модуль для Helm-установки Argo CD
│       ├── jenkins.tf       # Helm release для Jenkins
│       ├── variables.tf     # Змінні (версія чарта, namespace, repo URL тощо)
│       ├── providers.tf     # Kubernetes+Helm.  переносимо з модуля jenkins
│       ├── values.yaml      # Кастомна конфігурація Argo CD
│       ├── outputs.tf       # Виводи (hostname, initial admin password)
│		    └──charts/                  # Helm-чарт для створення app'ів
│ 	 	    ├── Chart.yaml
│	  	    ├── values.yaml          # Список applications, repositories
│			    └── templates/
│		        ├── application.yaml
│		        └── repository.yaml
├── charts/
│   └── django-app/
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   └── hpa.yaml
│       ├── Chart.yaml
│       └── values.yaml     # ConfigMap зі змінними середовища
```

**Критерії прийняття завдання::**

1. Посилання на GitHub-репозиторій із гілкою `lesson-8-9`
2. Архів проєкту `lesson-8-9_<ПІБ>.zip`, прикріплений до LMS
3. `README.md` з описом:
   - Як застосувати `Terraform`
   - Як перевірити `Jenkins job`
   - Як побачити результат в `Argo CD`

>❗️ УВАГА! ⚠️ При роботі з хмарними провайдерами завжди пам'ятайте: невикористані ресурси можуть призвести до значних витрат. Щоб уникнути непередбачуваних рахунків, після перевірки вашого коду обов'язково видаляйте створені ресурси. Використовуйте команду terraform destroy.

>❗️ УВАГА! ⚠️ Пам'ятайте порядок запуску інфраструктури після видалення! При видаленні всієї інфраструктури за допомогою terraform destroy ви також видаляєте S3-бакет і DynamoDB-таблицю, які використовуються для збереження Terraform стейту.

---

## 🚀 Інструкція з тестування CI/CD (Jenkins + ArgoCD + GitOps)

Цей проєкт реалізовано в режимі **Enterprise God Mode**, що дозволяє відтворити повний цикл автоматизації як локально (через LocalStack Pro), так і в реальному середовищі AWS.

---

### 💻 ЕТАП 1: Локальне тестування (LocalStack Pro)

Ідеально для перевірки логіки Terraform, Helm-чартів та Jenkins Pipeline без витрат у хмарі.

#### 1. Запуск інфраструктури

Переконайтеся, що у вашому `.env` додано `LOCALSTACK_AUTH_TOKEN`.

```bash
# Розгортання ізольованого середовища для теми 8-9
make deploy-local dev
```

*Terraform створить VPC, ECR, EKS (k3d), Jenkins та ArgoCD з префіксами `-89`.*

#### 2. Доступ до Jenkins

Слід виконати команду:

```bash
make open-jenkins
```

або

Jenkins налаштований через **JCasC** (Configuration as Code) і вже має готовий шаблон для Kaniko-агента.

```bash
# Прокидаємо порт (в окремому терміналі)
kubectl port-forward svc/jenkins-89 -n jenkins-89 8080:8080
```

* **URL:** `http://localhost:8080`
* **Login:** `admin`
* **Password:** `admin_password_123` (задано в values.yaml)

**Налаштування GitHub:**

1. Перейдіть у **Manage Jenkins** -> **Credentials** -> **Global** -> **Add Credentials**.
2. Type: `Username with password`.
3. ID: `github-cred` (ОБОВ'ЯЗКОВО саме такий ID).
4. Username: Ваш логін GitHub.
5. Password: Ваш GitHub Personal Access Token (PAT).

#### 3. Доступ до ArgoCD

Слід виконати команду:

```bash
make open-argocd
```

або

ArgoCD автоматично стежить за вашим репозиторієм завдяки патерну **App-of-Apps**.

```bash
# Отримання пароля адміністратора
kubectl -n argocd-89 get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Прокидаємо порт (в окремому терміналі)
kubectl port-forward svc/argocd-server-89 -n argocd-89 8081:80
```

- **URL:** `http://localhost:8081`
- **Login:** `admin`

---

### ☁️ ЕТАП 2: Бойове тестування (Real AWS)

Використовується для фінального деплою з реальною безпекою та EBS-дисками.

#### 1. Деплой у хмару

```bash
# Створення продуктової інфраструктури з EBS CSI драйвером та логуванням
make deploy-aws prod
```

#### 2. Налаштування Pipeline у Jenkins

1. Створіть **New Item** -> **Pipeline** -> назва `django-enterprise-ci`.
2. У налаштуваннях: `Pipeline script from SCM`.
3. SCM: `Git` -> URL вашого репозиторію.
4. Гілка: `*/main`.
5. Script Path: `Jenkinsfile`.

---

### ⚙️ ЕТАП 3: Перевірка циклу (E2E Test)

Щоб побачити магію автоматизації в дії, виконайте наступні кроки:

1. **Зміна коду:** Внесіть будь-яку зміну в код Django (наприклад, коментар у `core/settings.py`).
2. **Git Push:** `git commit -am "feat: god mode testing" && git push`.
3. **Jenkins:** Запустіть пайплайн.
    - Jenkins підніме **Kaniko-агент** у кластері.
    - Kaniko збирає образ БЕЗ docker-сокета (Rootless) і пушить в **ECR**.
    - Jenkins автоматично оновить тег образу в `charts/django-app/values.yaml` і зробить комміт у ваш GitHub.
4. **ArgoCD:** Поверніться в інтерфейс ArgoCD. За 30-60 секунд (або після натискання `Sync`) він побачить оновлення в Git і автоматично оновить ваш застосунок у кластері (Rolling Update).

---

### 🧹 Очищення ресурсів

Щоб не витрачати гроші (AWS) або ресурси ПК (LocalStack):

```bash
# Для хмари (AWS)
make destroy-aws prod

# Для локального середовища
make destroy-local dev

# Повне видалення кешів та Docker-образів
make deep-clean
```
