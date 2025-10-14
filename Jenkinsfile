pipeline {
    agent any
    
    environment {
        IMAGE_REPO = 'adrianwisniewskiit/local-devops-platform'
        GIT_REPO   = 'https://github.com/adrian-wisniewski-it/local-devops-platform.git'
    }

    parameters {
        choice(
            name: 'ENV',
            choices: ['dev', 'prod'],
            description: 'Choose deployment environment'
        )
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

        stage('Deploy with Helm') {
            steps {
                echo "Deploying to ${params.ENV} environment using Helm..."
                withCredentials([
                    string(credentialsId: "DB_USER_${params.ENV}", variable: 'DB_USER'),
                    string(credentialsId: "DB_PASS_${params.ENV}", variable: 'DB_PASS')
                ]) {
                    sh """
                        RELEASE_NAME="localdevopsplatform-${params.ENV}"
                        
                        microk8s helm upgrade --install \${RELEASE_NAME} ./helm/local-devops-platform \
                            --set image.repository=${IMAGE_REPO} \
                            --set image.tag=${BUILD_NUMBER} \
                            --set environment=${params.ENV} \
                            --set secrets.DB_USER=\${DB_USER} \
                            --set secrets.DB_PASS=\${DB_PASS} \
                            --namespace default \
                            --wait \
                            --timeout 5m
                    """
                    echo "Application deployed successfully to ${params.ENV}."
                }
            }
        }
    }

    post {
        failure {
            echo "Deployment failed. Rolling back to previous version..."
            sh """
                microk8s helm rollback localdevopsplatform-${params.ENV} --namespace default || true
            """
            echo "Rollback completed."
        }
        always {
            echo "Cleaning up Docker resources..."
            sh 'docker system prune -af || true'
            sh 'docker logout || true'
            echo "Cleanup completed."
        }
    }
}