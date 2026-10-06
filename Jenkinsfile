pipeline {

    agent any

    environment {
        REGISTRY = "localhost:5000"
        IMAGE_NAME = "orderhub"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Unit Test') {
            steps {
                bat 'python -m pytest -v'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def shortCommit = env.GIT_COMMIT.take(7)

                    env.SHORT_COMMIT = shortCommit
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${shortCommit}"

                    echo "Git Commit: ${shortCommit}"
                    echo "Image Tag: ${env.IMAGE_TAG}"

                    bat "docker build -t ${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG} ."
                }
            }
        }

        stage('Test Docker Image') {
            steps {
                script {

                    def containerName = "orderhub-test-${env.BUILD_NUMBER}"

                    bat """
                        docker run -d --name ${containerName} -p 18080:8080 ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """

                    powershell '''
                        Start-Sleep -Seconds 10
                    '''

                    bat """
                        curl.exe -f http://localhost:18080/health
                    """
                }
            }
        }

        stage('Push Image') {
            steps {
                bat "docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Approval') {
            steps {
                script {
                    input(
                        message: "Approve deployment of ${IMAGE_NAME}:${IMAGE_TAG} to PRODUCTION?",
                        ok: "Deploy"
                    )
                }
            }
        }
    }

    post {
        always {
            bat "docker rm -f orderhub-test-${BUILD_NUMBER} 2>NUL || exit /b 0"
        }
    }
}

