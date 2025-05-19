def AGENT_LABEL = 'dev'  // Set default

if (env.BRANCH_NAME == 'main') {
    AGENT_LABEL = 'frankfurt'
}
pipeline {
    agent {
        label "${AGENT_LABEL}"
    }
    options {
        ansiColor('xterm')
    }
    environment {
        REPO = sh(script: 'echo $GIT_URL | awk -F/ \'{print $NF}\' | sed -e "s/.git$//"', returnStdout: true).trim()
        GIT_ORG = sh(script: 'echo $GIT_URL | awk -F/ \'{print $4}\'', returnStdout: true).trim()
    }
    stages {
        stage('Docker') {
            steps {
                withFolderProperties {
                    sh "docker build --no-cache -t ghcr.io/werunplugged/${env.REPO}:${env.BRANCH_NAME}-${env.GIT_COMMIT} ."
                    withCredentials([usernamePassword(credentialsId: 'github_registry', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh "docker login ghcr.io -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
                        sh "docker push ghcr.io/werunplugged/${env.REPO}:${env.BRANCH_NAME}-${env.GIT_COMMIT}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script{
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: "aws_credentials", secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                        sh """
                            aws eks update-kubeconfig --kubeconfig ./kubeconfig --region eu-west-2 --name prod
                            kubectl apply --kubeconfig ./kubeconfig -f k8s/deployment.yaml
                            kubectl apply --kubeconfig ./kubeconfig -f k8s/service.yaml
                            kubectl apply --kubeconfig ./kubeconfig -f k8s/ingress.yaml
                         """
                    }
                }
            }
        }
    }
     post {
        always {
            sh "docker rmi ghcr.io/werunplugged/${env.REPO}:${env.BRANCH_NAME}-${env.GIT_COMMIT} || true"
            cleanWs()
        }
    }
}