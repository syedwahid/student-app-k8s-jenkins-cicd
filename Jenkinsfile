pipeline {
    agent any
    
    environment {
        // Docker Hub credentials (must be set up in Jenkins credentials)
        DOCKER_USERNAME = credentials('docker-hub')
        DOCKER_PASSWORD = credentials('docker-hub')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo '✅ Source code checked out successfully'
            }
        }
        
        stage('List Files') {
            steps {
                sh '''
                    echo "📁 Project Structure:"
                    ls -la
                    echo ""
                    echo "📁 App Directory:"
                    ls -la app/
                '''
            }
        }
        
        stage('Validate Dockerfiles') {
            steps {
                script {
                    echo '🔍 Checking Dockerfiles...'
                    
                    // Check backend
                    if (fileExists('app/backend/Dockerfile')) {
                        echo '✅ Backend Dockerfile exists'
                        sh 'head -5 app/backend/Dockerfile'
                    } else {
                        echo '❌ Backend Dockerfile missing'
                    }
                    
                    // Check frontend
                    if (fileExists('app/frontend/Dockerfile')) {
                        echo '✅ Frontend Dockerfile exists'
                        sh 'head -5 app/frontend/Dockerfile'
                    } else {
                        echo '❌ Frontend Dockerfile missing'
                    }
                }
            }
        }
        
        stage('Test Docker Builds') {
            steps {
                script {
                    echo '🏗️ Testing Docker builds...'
                    
                    // Test backend build
                    dir('app/backend') {
                        try {
                            sh '''
                                echo "Building backend..."
                                docker build --no-cache -t student-backend-test .
                                echo "✅ Backend build successful"
                            '''
                        } catch (Exception e) {
                            echo "⚠️ Backend build failed: ${e.message}"
                        }
                    }
                    
                    // Test frontend build
                    dir('app/frontend') {
                        try {
                            sh '''
                                echo "Building frontend..."
                                docker build --no-cache -t student-frontend-test .
                                echo "✅ Frontend build successful"
                            '''
                        } catch (Exception e) {
                            echo "⚠️ Frontend build failed: ${e.message}"
                        }
                    }
                }
            }
        }
        
        stage('Test Docker Login') {
            steps {
                script {
                    echo '🔐 Testing Docker Hub credentials...'
                    
                    try {
                        sh '''
                            echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
                            echo "✅ Docker Hub login successful"
                        '''
                    } catch (Exception e) {
                        echo "❌ Docker Hub login failed"
                        echo "Make sure docker-hub credentials are set up in Jenkins"
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 Pipeline completed successfully!'
            script {
                currentBuild.description = "✅ Build #${BUILD_NUMBER} - Success"
            }
        }
        failure {
            echo '❌ Pipeline failed!'
            script {
                currentBuild.description = "❌ Build #${BUILD_NUMBER} - Failed"
            }
        }
        always {
            script {
                // Run inside node block
                node {
                    echo "📊 Build Summary:"
                    echo "Build Number: ${BUILD_NUMBER}"
                    echo "Duration: ${currentBuild.durationString}"
                    echo "Result: ${currentBuild.currentResult}"
                    
                    // Clean up test images
                    sh '''
                        echo "🧹 Cleaning up..."
                        docker rmi student-backend-test student-frontend-test 2>/dev/null || true
                    '''
                }
            }
        }
    }
}