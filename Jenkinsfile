pipeline {
  agent none
  environment {
    // Docker Hub credentials stored in Jenkins (username/password or token)
    DOCKERHUB_CREDENTIALS = 'dockerhub-creds-id'
    DOCKERHUB_REPO = 'vijayvj3/genai'  // change
    REPO_URL = 'https://github.com/edureka-devops/projCert.git'
    TEST_HOST = '3.108.221.91'   // or IP
    PROD_HOST = '3.111.196.204'
    SSH_CREDENTIALS_ID = 'ssh-creds-id'     // private key for SSH to test & prod
    ANSIBLE_INVENTORY = 'ansible/inventory' // path in repo or generated
  }

  stages {
    stage('Checkout Jenkinsfile') {
      agent { label 'master' }
      steps {
        checkout scm
      }
    }

    stage('Job 1 - Install Puppet Agent on Test Server') {
      agent { label 'master' }
      steps {
        // Copy puppet install script to test server and execute via SSH
        sshagent (credentials: [env.SSH_CREDENTIALS_ID]) {
          sh """
            scp -o StrictHostKeyChecking=no scripts/install_puppet_agent.sh ubuntu@${TEST_HOST}:/tmp/install_puppet_agent.sh
            ssh -o StrictHostKeyChecking=no ubuntu@${TEST_HOST} 'sudo bash /tmp/install_puppet_agent.sh'
          """
        }
      }
    }

    stage('Job 2 - Install Docker using Ansible on Test Server') {
      agent { label 'master' }
      steps {
        // Ensure ansible is available on Jenkins master
        sh 'ansible --version || echo "Ansible not installed on Jenkins master - install it"'
        // Run playbook (assumes inventory points to TEST_HOST)
        sh "ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/install_docker.yml --limit test"
      }
    }

    stage('Job 3 - Build, Push & Deploy PHP Docker Container (on Test Server)') {
      agent { label 'master' }
      steps {
        // Build image on the test server so that test-server actually runs it (could also build on master and push)
        script {
          sshagent (credentials: [env.SSH_CREDENTIALS_ID]) {
            sh """
              ssh -o StrictHostKeyChecking=no ubuntu@${TEST_HOST} '
                set -e
                # clone repo (or pull)
                if [ -d /tmp/projCert ]; then cd /tmp/projCert && git checkout master && git pull; else git clone ${REPO_URL} /tmp/projCert; fi
                cd /tmp/projCert/docker
                # build docker image
                sudo docker build -t ${DOCKERHUB_REPO}:latest .
                # login & push (using ephemeral docker login via env)
                echo "Logging in to Docker Hub"
                sudo docker login -u ${DOCKERHUB_USER} -p ${DOCKERHUB_PASS}
                sudo docker push ${DOCKERHUB_REPO}:latest
                # run container (replace previous)
                sudo docker rm -f applebite_test || true
                sudo docker run -d --name applebite_test -p 80:80 ${DOCKERHUB_REPO}:latest
              '
            """
          }
        }
      }
      post {
        failure {
          // On failure, attempt cleanup of test container
          sshagent (credentials: [env.SSH_CREDENTIALS_ID]) {
            sh """
              ssh -o StrictHostKeyChecking=no ubuntu@${TEST_HOST} 'sudo docker rm -f applebite_test || true'
            """
          }
        }
        success {
          // On success, deploy to PROD via Ansible (pull & run)
          sh "ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/deploy_to_prod.yml --extra-vars \"image=${DOCKERHUB_REPO}:latest\" --limit prod"
        }
      }
    }
  }
}

