pipeline {

    agent any

    options {
        disableConcurrentBuilds()
    }

    environment {
        REGISTRY = "localhost:5000"
        IMAGE_NAME = "orderhub"
        PROD_CONTAINER = "orderhub-prod"
        PROD_PORT = "8080"
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

        stage('Deploy') {
            steps {
                script {

                    echo "Deploying exact immutable image:"
                    echo "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

                    bat """
                        docker pull ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """

                    bat """
                        docker rm -f ${PROD_CONTAINER} 2>NUL || exit /b 0
                    """

                    bat """
                        docker run -d --name ${PROD_CONTAINER} -p ${PROD_PORT}:8080 ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """

                    powershell '''
                        Start-Sleep -Seconds 10
                    '''

                    bat """
                        docker ps --filter "name=${PROD_CONTAINER}"
                    """

                    bat """
                        docker inspect --format="{{.Config.Image}}" ${PROD_CONTAINER}
                    """
                }
            }
        }

        stage('Smoke Test') {
            steps {

                bat """
                    curl.exe -f http://localhost:${PROD_PORT}/health
                """

                bat """
                    curl.exe -f http://localhost:${PROD_PORT}/
                """

                bat """
                    curl.exe -f http://localhost:${PROD_PORT}/orders
                """

                bat """
                    curl.exe -f http://localhost:${PROD_PORT}/version
                """
            }
        }
    }

    post {

        always {
            bat "docker rm -f orderhub-test-${BUILD_NUMBER} 2>NUL || exit /b 0"
        }

        success {
            echo "OrderHub deployment completed successfully."
            echo "Production image: ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        }

        failure {
            echo "OrderHub deployment failed."
        }
    }
}

