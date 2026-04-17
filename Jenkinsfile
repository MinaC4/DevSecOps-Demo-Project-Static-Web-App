pipeline {
    agent any

    environment {
        IMAGE_NAME = 'minac4/iti-pro'
        IMAGE_TAG  = 'latest'
        HELM_RELEASE = 'iti-pro'
        CHART_PATH   = 'helm/iti-pro'
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh '''
                        eval $(minikube docker-env)
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    '''
                }
            }
        }

        stage('Security Scan - Trivy') {
            steps {
                script {
                    sh 'trivy image --exit-code 1 --severity CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}'
                    sh 'trivy image --exit-code 0 --severity HIGH ${IMAGE_NAME}:${IMAGE_TAG} || true'
                    sh 'trivy fs --exit-code 0 --severity HIGH,CRITICAL .'
                }
            }
        }

        stage('Tests') {
            steps {
                echo 'Running tests...'
                sh 'echo "Placeholder for unit/integration tests"'
            }
        }

        stage('Deploy with Helm') {
            steps {
                sh '''
                    helm upgrade --install ${HELM_RELEASE} ${CHART_PATH} \
                        --namespace default \
                        --set image.repository=${IMAGE_NAME} \
                        --set image.tag=${IMAGE_TAG} \
                        --set image.pullPolicy=Never \
                        --wait \
                        --timeout 3m
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl get pods -l app.kubernetes.io/name=iti-pro
                    kubectl get svc iti-pro
                    kubectl rollout status deployment/iti-pro --timeout=90s
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully'
        }
        failure {
            echo 'Pipeline failed'
        }
    }
}
