pipeline {
    agent any

    environment {
        IMAGE_NAME = 'iti-pro'
        IMAGE_TAG  = 'latest'
        HELM_RELEASE = 'iti-pro'
        CHART_PATH   = 'helm/iti-pro'
        KUBECONFIG_CRED = 'kubeconfig'
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
                    sh 'trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG} || true'
                    sh 'trivy fs --exit-code 0 --severity HIGH,CRITICAL .'
                }
            }
        }

        stage('Deploy with Helm') {
            steps {
                withKubeConfig([credentialsId: KUBECONFIG_CRED, contextName: 'minikube']) {
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
        }

        stage('Verify Deployment') {
            steps {
                withKubeConfig([credentialsId: KUBECONFIG_CRED, contextName: 'minikube']) {
                    sh '''
                        echo "=== Pods ==="
                        kubectl get pods -l app.kubernetes.io/name=iti-pro
                        echo "=== Service ==="
                        kubectl get svc iti-pro
                        echo "=== Rollout Status ==="
                        kubectl rollout status deployment/iti-pro --timeout=90s
                    '''
                }
            }
        }
    }

    post {
        success {
            echo ' Pipeline completed successfully'
        }
        failure {
            echo 'Pipeline failed'
        }
    }
}
