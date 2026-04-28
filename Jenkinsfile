pipeline {
    agent { label 'kaniko' }

    // При запуску Jenkins запитає середовище
    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'prod'], description: 'Оберіть середовище для деплою (LocalStack або AWS)')
    }

    environment {
        IMAGE_TAG = "v-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout & Load Config') {
            steps {
                checkout scm
                script {
                    def configFile = "ci.${params.DEPLOY_ENV}.properties"
                    def props = readProperties file: configFile

                    env.GITHUB_REPO = props.GITHUB_REPO
                    env.REPO_NAME = props.REPO_NAME

                    // Якщо це AWS (prod), дістаємо Account ID динамічно!
                    if (params.DEPLOY_ENV == 'prod') {
                        container('aws-cli') { // <-- Викликаємо потрібний контейнер
                            def accountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                            env.ECR_REGISTRY = "${accountId}.dkr.ecr.${props.AWS_REGION}.amazonaws.com"
                        }
                    } else {
                        // Для LocalStack Pro просто залишаємо локальну адресу
                        env.ECR_REGISTRY = props.ECR_REGISTRY
                    }
                }
                echo "ECR Address: ${env.ECR_REGISTRY}"
            }
        }

        stage('Build & Push (Kaniko)') {
            steps {
                container('kaniko') {
                    // Збірка образу без Docker Daemon (Rootless)
                    sh '''
                    /kaniko/executor \
                      --context $(pwd) \
                      --dockerfile $(pwd)/Dockerfile \
                      --destination ${ECR_REGISTRY}/${REPO_NAME}:${IMAGE_TAG} \
                      --destination ${ECR_REGISTRY}/${REPO_NAME}:latest \
                      --cache=true
                    '''
                }
            }
        }

        stage('Update GitOps Repo (ArgoCD)') {
            steps {
                container('git') {
                    script {
                        // Оновлюємо тег образу в values.yaml
                        sh "sed -i 's/tag: .*/tag: \"${IMAGE_TAG}\"/' charts/django-app/values.yaml"

                        // Відправляємо зміни в GitHub (Потрібно додати Credentials в Jenkins)
                        withCredentials([usernamePassword(credentialsId: 'github-cred', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                            sh """
                            git config user.email "jenkins@enterprise.com"
                            git config user.name "Jenkins GitOps"
                            git add charts/django-app/values.yaml
                            git commit -m "ci(${params.DEPLOY_ENV}): Update image tag to ${IMAGE_TAG} [skip ci]"
                            git push https://${GIT_USERNAME}:${GIT_PASSWORD}@${GITHUB_REPO#https://} HEAD:main
                            """
                        }
                    }
                }
            }
        }
    }
}
