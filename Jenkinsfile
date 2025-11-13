pipeline {
    agent none

    environment {
        APP_REPO = "https://github.com/vijayvj3/projCert.git"
        TEST_NODE = "test-server"
        PROD_NODE = "Prod-server"
        DOCKER_IMAGE = "projcert-app:latest"
    }

    stages {

        stage('Checkout Application Code') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Cloning PHP app into projCert folder..."
                dir('projCert') {
                    git branch: 'master', url: "${APP_REPO}"
                }
            }
        }

        stage('Install Docker via Ansible (Test Server)') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Installing Docker on TEST via Ansible..."
                sh """
                    cd ansible
                    ansible-playbook install_docker.yml -i inventory --limit test
                """
            }
        }

        stage('Build Docker Image') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Building Docker image from projCert folder..."
                sh """
                    cd projCert
                    docker build -t ${DOCKER_IMAGE} .
                """
            }
        }

        stage('Deploy to Test Server') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Deploying application on TEST server..."
                sh """
                    docker rm -f projcert-app || true
                    docker run -d -p 80:80 --name projcert-app ${DOCKER_IMAGE}
                """
            }
        }

        stage('Smoke Test on Test Server') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Running smoke tests on TEST..."
                sh "curl -I http://localhost || true"
            }
        }

        stage('Deploy to Production Server') {
            when {
                expression { currentBuild.currentResult == 'SUCCESS' }
            }
            agent { label "${PROD_NODE}" }
            steps {
                echo "Deploying application to PROD server..."
                sh """
                    docker rm -f projcert-app || true
                    docker run -d -p 80:80 --name projcert-app ${DOCKER_IMAGE}
                """
            }
        }
    }

    post {
        success {
            echo "🎉 Production deployment successful!"
        }
        failure {
            echo "❌ Pipeline failed — cleaning up TEST environment..."
            node("${TEST_NODE}") {
                sh "docker rm -f projcert-app || true"
            }
        }
    }
}
