pipeline {
    agent any

    parameters {
        string(name: 'SERVER_IP', description: 'IP целевого сервера')
        string(name: 'SSH_USER', defaultValue: 'root', description: 'SSH-пользователь')
        password(name: 'SSH_PASSWORD', description: 'Пароль для SSH')
    }

    stages {
        stage('Checkout Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/your-username/k8s-autoinstall.git'
            }
        }

        stage('Install Kubernetes') {
            steps {
                script {
                    // Проверка наличия обязательных параметров
                    if (!params.SERVER_IP?.trim()) {
                        error("SERVER_IP не указан!")
                    }

                    // Запуск скрипта
                    sh """
                        chmod +x scripts/install-k8s.sh
                        ./scripts/install-k8s.sh \
                            "${params.SERVER_IP}" \
                            "${params.SSH_USER}" \
                            "${params.SSH_PASSWORD}"
                    """
                }
            }
        }

        stage('Post-Install Check') {
            steps {
                script {
                    // Проверка доступности ноды (пример)
                    sh """
                        sshpass -p "${params.SSH_PASSWORD}" ssh -o StrictHostKeyChecking=no ${params.SSH_USER}@${params.SERVER_IP} \
                            "kubectl get nodes | grep 'Ready'"
                    """
                }
            }
        }
    }

}