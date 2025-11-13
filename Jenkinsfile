pipeline {
    agent none

    environment {
        APP_REPO = "https://github.com/vijayvj3/projCert.git"
        TEST_NODE = "test-server"
        PROD_NODE = "prod-server"
        PROD_IP = "15.207.72.246"
        DOCKER_IMAGE = "projcert-app:latest"
    }

    stages {

        stage('Checkout App Code') {
            agent { label "${TEST_NODE}" }
            steps {
                sh '''
                    rm -rf projCert || true
                    git clone https://github.com/vijayvj3/projCert.git projCert
                '''
            }
        }

        stage('Install Docker on Test (Ansible)') {
            agent { label "${TEST_NODE}" }
            steps {
                sh '''
                    cd ansible
                    ansible-playbook install_docker.yml -i inventory --limit test
                '''
            }
        }

        stage('Build Docker Image on Test') {
            agent { label "${TEST_NODE}" }
            steps {
                sh '''
                    rm -f projCert/Dockerfile || true
                    cp Dockerfile projCert/
                    cd projCert
                    docker build -t projcert-app:latest .
                '''
            }
        }

        stage('Deploy to Test Server') {
            agent { label "${TEST_NODE}" }
            steps {
                sh '''
                    docker rm -f projcert-app || true
                    docker run -d -p 80:80 --name projcert-app projcert-app:latest
                '''
            }
        }

        stage('Promote Image From Test → PROD') {
            agent { label "${TEST_NODE}" }
            steps {

                withCredentials([sshUserPrivateKey(credentialsId: 'prod-ssh-key',
                         keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {

                    sh '''
                        docker save projcert-app:latest -o projcert-app.tar
                        scp -o StrictHostKeyChecking=no -i $SSH_KEY projcert-app.tar $SSH_USER@15.207.72.246:/tmp/
                    '''
                }
            }
        }

        stage('Deploy on Production Server') {
            agent { label "${PROD_NODE}" }
            steps {
                sh '''
                    docker load -i /tmp/projcert-app.tar
                    docker rm -f projcert-app || true
                    docker run -d -p 80:80 --name projcert-app projcert-app:latest
                '''
            }
        }
    }

    post {
        success {
            echo "Deployment completed successfully!"
        }
        failure {
            node("${TEST_NODE}") {
                sh "docker rm -f projcert-app || true"
            }
        }
    }
}
