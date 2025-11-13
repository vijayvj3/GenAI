pipeline {
    agent none

    environment {
        APP_REPO = "https://github.com/vijayvj3/projCert.git"
        TEST_NODE = "test-server"
        PROD_NODE = "Prod-Server"
        DOCKER_IMAGE = "projcert-app:latest"
    }

    stages {

        stage('Checkout Application Code') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Cloning PHP app..."
                git branch: 'master', url: "${APP_REPO}"
            }
        }

        stage('Install Docker via Ansible (Test Server)') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Installing Docker on TEST..."
                sh """
                    cd ansible
                    ansible-playbook install_docker.yml -i inventory --limit test
                """
            }
        }

        stage('Build Docker Image') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Building Docker image for PHP app..."
                sh """
                    cd projCert   # go inside the application folder
                    docker build -t ${DOCKER_IMAGE} .
                """
    }
}



        stage('Deploy to Test Server') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Deploying container on TEST..."
                sh """
                    docker rm -f projcert-app || true
                    docker run -d -p 80:80 --name projcert-app ${DOCKER_IMAGE}
                """
            }
        }

        stage('Smoke Test on Test Server') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Testing TEST server..."
                sh 'curl -I http://localhost || true'
            }
        }

        stage('Deploy to Production') {
            when {
                expression { currentBuild.currentResult == 'SUCCESS' }
            }
            agent { label "${PROD_NODE}" }
            steps {
                echo "Deploying container on PROD..."
                sh """
                    docker rm -f projcert-app || true
                    docker run -d -p 80:80 --name projcert-app ${DOCKER_IMAGE}
                """
            }
        }
    }

    post {
        success {
            echo "🚀 Deployment successful on PROD"
        }
        failure {
            echo "❌ FAILED — cleaning up TEST..."
            node("${TEST_NODE}") {
                sh 'docker rm -f projcert-app || true'
            }
        }
    }
}
