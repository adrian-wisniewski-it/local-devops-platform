pipeline {
    agent any
    
    environment {
        IMAGE_REPO = 'adrianwisniewskiit/local-devops-platform'                                // <- change to your Docker Hub repository
        GIT_REPO   = 'https://github.com/adrian-wisniewski-it/local-devops-platform.git'       // <- change to your Git repository
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out code from ${GIT_REPO}..."
                git branch: 'main', url: "${GIT_REPO}"
                echo "Code checked out successfully."
            }
        }

        stage('Build Image') {
            steps {
                echo "Building Docker image..."
                sh 'docker build -t ${IMAGE_REPO}:${BUILD_NUMBER} .'
                sh 'docker tag ${IMAGE_REPO}:${BUILD_NUMBER} ${IMAGE_REPO}:latest'
                echo "Docker image built and tagged successfully."
            }
        }

        stage('Lint') {
            steps {
                echo "Linting Python code..."
                sh 'docker run --rm --workdir /usr/src/app ${IMAGE_REPO}:${BUILD_NUMBER} python -m py_compile app.py'
                echo "Linting completed successfully."
            }
        }

        stage('Login to DockerHub') {
            steps {
                echo "Logging in to DockerHub..."
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                    echo "Logged in to DockerHub successfully."
                }
            }
        }

        stage('Push Image') {
            steps {
                echo "Pushing Docker image to DockerHub..."
                sh 'docker push ${IMAGE_REPO}:${BUILD_NUMBER}'
                sh 'docker push ${IMAGE_REPO}:latest'
                echo "Docker image pushed to DockerHub successfully."
            }
        }

        stage('Notify ArgoCD') {
            steps {
                echo "Notifying ArgoCD about new deployment..."
                sh """
                    microk8s kubectl patch application local-devops-platform \
                        -n argocd \
                        --type merge \
                        -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' || true
                """
                echo "ArgoCD notified successfully."
            }
        }
    }

    post {
        always {
            echo "Cleaning up Docker resources..."
            sh 'docker system prune -af || true'
            sh 'docker logout || true'
            echo "Cleanup completed."
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed. Please check the logs for details."
        }
    }
}