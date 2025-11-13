pipeline {
    agent none

    environment {
        APP_REPO = "https://github.com/vijayvj3/projCert.git"
        TEST_NODE = "test-server"
        PROD_NODE = "prod-server"
        PROD_IP = "15.207.72.246"    // <--- Your PROD public IP
        DOCKER_IMAGE = "projcert-app:latest"
    }

    stages {

        stage('Checkout App Code') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Cloning application repo..."
                sh """
                    rm -rf projCert || true
                    git clone ${APP_REPO} projCert
                """
            }
        }

        stage('Install Docker on Test (Ansible)') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Running Ansible on Test..."
                sh """
                    cd ansible
                    ansible-playbook install_docker.yml -i inventory --limit test
                """
            }
        }

        stage('Build Docker Image on Test') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Building Docker image..."
                sh """
                    rm -f projCert/Dockerfile || true
                    cp Dockerfile projCert/
                    cd projCert
                    docker build -t ${DOCKER_IMAGE} .
                """
            }
        }

        stage('Deploy to Test Server') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Starting container on Test server..."
                sh """
                    docker rm -f projcert-app || true
                    docker run -d -p 80:80 --name projcert-app ${DOCKER_IMAGE}
                """
            }
        }

        stage('Promote Image From Test → PROD') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Saving Docker image and copying to PROD..."

                // USE JENKINS CREDENTIALS
                withCredentials([sshUserPrivateKey(credentialsId: 'prod-ssh-key', 
                         keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh """
                        docker save ${DOCKER_IMAGE} -o projcert-app.tar
                        scp -o StrictHostKeyChecking=no -i $SSH_KEY projcert-app.tar ${SSH_USER}@${PROD_IP}:/tmp/
                    """
                }
            }
        }

        stage('Deploy on Production Server') {
            agent { label "${PROD_NODE}" }
            steps {
                echo "Deploying on PROD..."

                sh """
                    docker load -i /tmp/projcert-app.tar
                    docker rm -f projcert-app || true
                    docker run -d -p 80:80 --name projcert-app projcert-app:latest
                """
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment completed successfully!"
        }
        failure {
            echo "❌ Failure occurred. Cleaning up TEST environment..."
            node("${TEST_NODE}") {
                sh "docker rm -f projcert-app || true"
            }
        }
    }
}
