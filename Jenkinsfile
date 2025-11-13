pipeline {
    agent none

    environment {
        APP_REPO = "https://github.com/vijayvj3/projCert.git"
        TEST_NODE = "test-server"
        PROD_NODE = "prod-server"
        PROD_IP = "15.207.72.246"        // <---- CHANGE THIS
        DOCKER_IMAGE = "projcert-app:latest"
    }

    stages {

        stage('Checkout App') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Cloning PHP app repo"
                sh """
                    rm -rf projCert || true
                    git clone ${APP_REPO} projCert
                """
            }
        }

        stage('Install Docker on Test (Ansible)') {
            agent { label "${TEST_NODE}" }
            steps {
                sh """
                    cd ansible
                    ansible-playbook install_docker.yml -i inventory --limit test
                """
            }
        }

        stage('Build Docker Image on Test') {
    agent { label "${TEST_NODE}" }
    steps {
        echo "Building Docker image"
        sh """
            rm -f projCert/Dockerfile || true
            cd projCert
            cp ../Dockerfile .
            docker build -t projcert-app:latest .
        """
    }
}


        stage('Deploy to Test') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Running container on Test server"
                sh """
                    docker rm -f projcert-app || true
                    docker run -d -p 80:80 --name projcert-app ${DOCKER_IMAGE}
                """
            }
        }

        stage('Promote Image TEST → PROD') {
            agent { label "${TEST_NODE}" }
            steps {
                echo "Saving Docker image on TEST"
                sh """
                    docker save ${DOCKER_IMAGE} -o projcert-app.tar
                    scp -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/id_rsa_pipeline projcert-app.tar ubuntu@${PROD_IP}:/tmp/


                """
            }
        }

        stage('Deploy on PROD') {
            agent { label "${PROD_NODE}" }
            steps {
                echo "Deploying container on PROD..."
                sh """
                    docker load -i /tmp/projcert-app.tar
                    docker rm -f projcert-app || true
                    docker run -d -p 80:80 --name projcert-app projcert-app:latest
                """
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed — removing container on TEST server"
            node("${TEST_NODE}") {
                sh "docker rm -f projcert-app || true"
            }
        }
        success {
            echo "Deployment to PROD successful!"
        }
    }
}
