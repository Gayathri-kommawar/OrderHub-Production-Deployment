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
                    def shortCommit = bat(
                        script: '@git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

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
                bat """
                    docker run -d --name orderhub-test-${BUILD_NUMBER} -p 18080:8080 ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    timeout /t 5 /nobreak
                    curl.exe -f http://localhost:18080/health
                """
            }
        }

        stage('Push Image') {
            steps {
                bat """
                    docker pus

