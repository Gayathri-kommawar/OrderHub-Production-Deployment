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
        APP_VERSION = "1.0.0"
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
                    echo "Jenkins Build: ${env.BUILD_NUMBER}"
                    echo "Image Tag: ${env.IMAGE_TAG}"

                    bat """
                        docker build -t ${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG} .
                    """
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
                bat """
                    docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                """
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
                        docker run -d --name ${PROD_CONTAINER} ^
                        -e APP_VERSION=${APP_VERSION} ^
                        -e BUILD_NUMBER=${BUILD_NUMBER} ^
                        -e GIT_COMMIT=${GIT_COMMIT} ^
                        -p ${PROD_PORT}:8080 ^
                        ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
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

                    bat """
                        docker inspect --format="{{.State.Health.Status}}" ${PROD_CONTAINER}
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

        stage('Verify Artifact Traceability') {
            steps {
                script {

                    echo "========================================"
                    echo "Artifact Traceability"
                    echo "========================================"

                    echo "Git Commit:"
                    echo "${GIT_COMMIT}"

                    echo "Jenkins Build:"
                    echo "${BUILD_NUMBER}"

                    echo "Docker Image:"
                    echo "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

                    echo "Production Container:"
                    echo "${PROD_CONTAINER}"

                    bat """
                        docker inspect --format="{{.Config.Image}}" ${PROD_CONTAINER}
                    """

                    bat """
                        curl.exe -f http://localhost:${PROD_PORT}/version
                    """
                }
            }
        }
    }

    post {

        always {
            bat """
                docker rm -f orderhub-test-${BUILD_NUMBER} 2>NUL || exit /b 0
            """
        }

        success {
            echo "========================================"
            echo "OrderHub deployment completed successfully."
            echo "========================================"

            echo "Production image:"
            echo "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

            echo "Git commit:"
            echo "${GIT_COMMIT}"

            echo "Jenkins build:"
            echo "${BUILD_NUMBER}"
        }

        failure {
            echo "========================================"
            echo "OrderHub deployment failed."
            echo "========================================"
        }
    }
}