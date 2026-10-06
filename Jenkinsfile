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
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.SHORT_COMMIT = shortCommit

                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${shortCommit}"

                    bat """
                        docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .
                    """
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
                    docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        always {
            bat """
                docker rm -f orderhub-test-${BUILD_NUMBER} 2>NUL || exit /b 0
            """
        }
    }
}