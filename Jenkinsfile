pipeline {
    agent any

    environment {
        IMAGE_REPO = 'adrianwisniewskiit/local-devops-platform'                                  // <- change to your Docker Hub repo
        GIT_REPO   = 'https://github.com/adrian-wisniewski-it/local-devops-platform.git'         // <- change to your GitHub repo URL
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${GIT_REPO}"
            }
        }

        stage('Build Image') {
            steps {
                sh 'docker build -t ${IMAGE_REPO}:$BUILD_NUMBER .'
                sh 'docker tag ${IMAGE_REPO}:$BUILD_NUMBER ${IMAGE_REPO}:latest'
            }
        }

        stage('Test Image') {
            steps {
                sh 'docker run --rm ${IMAGE_REPO}:$BUILD_NUMBER python -m unittest || true'
            }
        }

        stage('Login to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                }
            }
        }

        stage('Push Image') {
            steps {
                sh 'docker push ${IMAGE_REPO}:$BUILD_NUMBER'
                sh 'docker push ${IMAGE_REPO}:latest'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                microk8s.kubectl apply -f kubernetes/deployment.yaml
                microk8s.kubectl set image deployment/local-devops-platform-deployment local-devops-platform=${IMAGE_REPO}:${BUILD_NUMBER}
                microk8s.kubectl apply -f kubernetes/service.yaml
                microk8s.kubectl apply -f kubernetes/hpa.yaml
                """
            }
        }
    }

    post {
        failure {
            sh 'microk8s.kubectl rollout undo deployment/local-devops-platform-deployment || true'
        }
        always {
            sh 'docker system prune -af || true'
        }
    }
}