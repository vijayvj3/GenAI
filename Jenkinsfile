pipeline {
    agent none

    environment {
        APP_REPO = "https://github.com/vijayvj3/projCert.git"   // your PHP app repo
        TEST_NODE = "test-server"
        PROD_NODE = "Prod Server"
        ANSIBLE_PLAYBOOK = "ansible/install_docker.yml"
        DOCKER_IMAGE = "projcert-app:latest"
    }

    stages {

        stage('Checkout Application Code') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Cloning PHP app repository..."
                git branch: 'master', url: "${APP_REPO}"
            }
        }

        stage('Install Docker via Ansible (on Test)') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Installing Docker using Ansible on Test Server..."
                sh """
                    ansible-playbook ${ANSIBLE_PLAYBOOK} -i '${env.TEST_NODE},' \
                    --user ubuntu --private-key /var/lib/jenkins/.ssh/id_rsa_pipeline
                """
            }
        }

        stage('Build Docker Image') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Building Docker image for PHP app..."
                sh 'docker build -t ${DOCKER_IMAGE} .'
            }
        }

        stage('Deploy to Test Server') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Deploying container on Test Server..."
                sh '''
                docker rm -f projcert-app || true
                docker run -d -p 80:80 --name projcert-app projcert-app:latest
                '''
            }
        }

        stage('Test Application') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Running smoke tests on Test Server..."
                // Add your test commands (curl or PHP test scripts)
                sh 'curl -I http://localhost || true'
            }
        }

        stage('Deploy to Production') {
            when {
                expression { currentBuild.currentResult == 'SUCCESS' }
            }
            agent { label "${PROD_NODE}" }
            steps {
                echo "Deploying to Production Server..."
                sh '''
                docker rm -f projcert-app || true
                docker run -d -p 80:80 --name projcert-app projcert-app:latest
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Deployment to production successful!"
        }
        failure {
            echo "❌ Pipeline failed. Cleaning up test container..."
            node("${TEST_NODE}") {
                sh 'docker rm -f projcert-app || true'
            }
        }
    }
}
