pipeline {
    agent any

    parameters {
        string(name: 'SERVER_IP', defaultValue: '45.144.52.219', description: 'IP целевого сервера')
        string(name: 'NODE_NAME', defaultValue: 'master', description: 'Имя ноды')
        string(name: 'SSH_USER', defaultValue: 'root', description: 'SSH-пользователь')
        password(name: 'SSH_PASSWORD', defaultValue: 'Fynjif1999', description: 'SSH-пароль')
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
                        playbook: 'k8s-ansible/playbooks/k8s-install.yml',
                        inventory: 'k8s-ansible/inventories/production/hosts',
                        credentialsId: 'k8s-ansible/your-ssh-credential-id',
                        extras: '-e "ANSIBLE_ROLES_PATH=k8s-ansible/roles"', // ID ваших SSH-ключей
                        extraVars: [
                            node_name: "${params.NODE_NAME}"
                        ]
                    )
                }
            }
        }
    }
}