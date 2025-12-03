pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo '✅ Source code checked out'
            }
        }
        
        stage('List Project') {
            steps {
                sh '''
                    echo "📁 Project Structure:"
                    ls -la
                    echo ""
                    echo "📦 App Directory:"
                    ls -la app/
                '''
            }
        }
        
        stage('Test Docker Builds') {
            steps {
                script {
                    echo '🏗️ Testing local Docker builds...'
                    
                    // Test backend build
                    if (fileExists('app/backend/Dockerfile')) {
                        dir('app/backend') {
                            sh '''
                                echo "🔧 Building backend image locally..."
                                docker build -t student-backend-local .
                                echo "✅ Backend built successfully"
                                docker images | grep student-backend
                            '''
                        }
                    } else {
                        echo '❌ Backend Dockerfile not found'
                    }
                    
                    // Test frontend build
                    if (fileExists('app/frontend/Dockerfile')) {
                        dir('app/frontend') {
                            sh '''
                                echo "🎨 Building frontend image locally..."
                                docker build -t student-frontend-local .
                                echo "✅ Frontend built successfully"
                                docker images | grep student-frontend
                            '''
                        }
                    } else {
                        echo '❌ Frontend Dockerfile not found'
                    }
                }
            }
        }
        
        stage('Test Kubernetes Files') {
            steps {
                script {
                    echo '📋 Checking Kubernetes manifests...'
                    
                    if (fileExists('k8s/namespace.yaml')) {
                        echo '✅ namespace.yaml exists'
                    }
                    
                    if (fileExists('k8s/backend/deployment.yaml')) {
                        echo '✅ backend/deployment.yaml exists'
                        sh 'head -10 k8s/backend/deployment.yaml'
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 Pipeline completed successfully!'
            script {
                currentBuild.description = "✅ Success - Build #${BUILD_NUMBER}"
            }
        }
        failure {
            echo '❌ Pipeline failed!'
            script {
                currentBuild.description = "❌ Failed - Build #${BUILD_NUMBER}"
            }
        }
        always {
            echo "📊 Build #${BUILD_NUMBER} completed"
            echo "Result: ${currentBuild.currentResult}"
            echo "Duration: ${currentBuild.durationString}"
        }
    }
}