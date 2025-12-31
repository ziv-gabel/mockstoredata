pipeline {
    agent {
        kubernetes {
          label 'k8s-dev'
          defaultContainer 'agent'
        }
    }
    options {
        ansiColor('xterm')
    }
    environment {
        REPO = sh(script: 'echo $GIT_URL | awk -F/ \'{print $NF}\' | sed -e "s/.git$//"', returnStdout: true).trim()
        GIT_ORG = sh(script: 'echo $GIT_URL | awk -F/ \'{print $4}\'', returnStdout: true).trim()
        IMAGE_URL = "ghcr.io/werunplugged/${env.REPO}:${env.GIT_COMMIT}"
    }
    stages {
        stage('Docker') {
            steps {
                withFolderProperties {
                    sh "docker build --no-cache -t ${IMAGE_URL} ."
                    withCredentials([usernamePassword(credentialsId: 'github_registry', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh "docker login ghcr.io -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
                        sh "docker push ${IMAGE_URL}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script{
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: "aws_credentials", secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                        sh """
                            perl -i -pe 's@IMAGE@${IMAGE_URL}@g' k8s/deployment.yaml
                            aws eks update-kubeconfig --kubeconfig ./kubeconfig --region eu-central-1 --name Lab
                            kubectl apply --kubeconfig ./kubeconfig -f k8s/deployment.yaml
                            kubectl apply --kubeconfig ./kubeconfig -f k8s/service.yaml
                            aws eks update-kubeconfig --kubeconfig ./kubeconfig2 --region eu-west-2 --name prod
                            kubectl apply --kubeconfig ./kubeconfig2 -f k8s/deployment.yaml
                            kubectl apply --kubeconfig ./kubeconfig2 -f k8s/service.yaml
                         """
                    }
                }
            }
        }
    }
     post {
        always {
            sh "docker rmi ${IMAGE_URL} || true"
            cleanWs()
        }
    }
}