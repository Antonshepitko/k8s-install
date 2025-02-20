pipeline {
    agent any

    parameters {
        string(name: 'SERVER_IP', description: 'IP целевого сервера')
        string(name: 'NODE_NAME', defaultValue: 'master', description: 'Имя ноды')
        string(name: 'SSH_USER', defaultValue: 'root', description: 'SSH-пользователь')
        password(name: 'SSH_PASSWORD', description: 'SSH-пароль')
    }

    stages {
        stage('Checkout Repository') {
            steps {
                git branch: 'master', 
                url: 'https://github.com/Antonshepitko/k8s-install.git'
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                script {
                    // Генерация динамического инвентори
                    writeFile file: 'inventories/production/hosts', text: """
                    [control_plane]
                    ${params.NODE_NAME} ansible_host=${params.SERVER_IP} ansible_user=${params.SSH_USER}
                    """

                    // Запуск Ansible с параметрами
                    ansiblePlaybook(
                        playbook: 'playbooks/k8s-install.yml',
                        inventory: 'inventories/production/hosts',
                        credentialsId: 'your-ssh-credential-id', // ID ваших SSH-ключей
                        extraVars: [
                            node_name: "${params.NODE_NAME}"
                        ]
                    )
                }
            }
        }
    }
}