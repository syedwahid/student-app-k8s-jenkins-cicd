pipeline {
    agent any
    
    environment {
        APP_NAME = 'student-app'
        KUBE_NAMESPACE = 'student-app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo '✅ Source code checked out'
            }
        }
        
        stage('Setup KIND') {
            steps {
                script {
                    echo '☸️ Setting up KIND cluster...'
                    sh '''
                        # Create KIND cluster if not exists
                        if ! kind get clusters | grep -q student-app; then
                            echo "Creating KIND cluster..."
                            cat > /tmp/kind-config.yaml << 'KIND_CONFIG'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30001
    hostPort: 30001
    protocol: tcp
  - containerPort: 31349
    hostPort: 31349
    protocol: tcp
KIND_CONFIG
                            kind create cluster --name student-app --config /tmp/kind-config.yaml
                        fi
                        kubectl get nodes
                    '''
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo '🐳 Building Docker images...'
                    sh '''
                        echo "Building backend..."
                        cd app/backend
                        docker build -t student-backend:latest .
                        
                        echo "Building frontend..."
                        cd ../frontend
                        docker build -t student-frontend:latest .
                        
                        echo "✅ Images built"
                        docker images | grep student-
                    '''
                }
            }
        }
        
        stage('Load Images to KIND') {
            steps {
                script {
                    echo '📦 Loading images to KIND...'
                    sh '''
                        echo "Loading backend..."
                        kind load docker-image student-backend:latest --name student-app
                        
                        echo "Loading frontend..."
                        kind load docker-image student-frontend:latest --name student-app
                        
                        echo "✅ Images loaded to KIND"
                    '''
                }
            }
        }
        
        stage('Update Manifests') {
            steps {
                script {
                    echo '🔄 Updating manifests for KIND...'
                    sh '''
                        echo "Updating imagePullPolicy..."
                        sed -i "s/imagePullPolicy:.*/imagePullPolicy: Never/g" k8s/backend/deployment.yaml
                        sed -i "s/imagePullPolicy:.*/imagePullPolicy: Never/g" k8s/frontend/deployment.yaml
                        
                        echo "✅ Manifests updated"
                    '''
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo '🚀 Deploying to Kubernetes...'
                    sh '''
                        echo "Creating namespace..."
                        kubectl create namespace student-app --dry-run=client -o yaml | kubectl apply -f -
                        
                        echo "Applying configurations..."
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/secrets.yaml
                        kubectl apply -f k8s/configmap.yaml
                        
                        echo "Deploying backend..."
                        kubectl apply -f k8s/backend/
                        
                        echo "Deploying frontend..."
                        kubectl apply -f k8s/frontend/
                        
                        echo "⏳ Waiting for deployment (40 seconds)..."
                        sleep 40
                        
                        echo "📊 Deployment status:"
                        kubectl get all -n student-app
                    '''
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo '🔍 Verifying deployment...'
                    sh '''
                        echo "Checking pods..."
                        kubectl get pods -n student-app -o wide
                        
                        echo ""
                        echo "Checking services..."
                        kubectl get svc -n student-app
                        
                        echo ""
                        echo "🌐 Access URLs:"
                        echo "Frontend: http://localhost:31349"
                        echo "Backend API: http://localhost:30001/api/health"
                    '''
                }
            }
        }
        
        stage('Test Application') {
            steps {
                script {
                    echo '🧪 Testing application...'
                    sh '''
                        echo "Testing backend..."
                        curl -s http://localhost:30001/api/health || echo "Backend not responding"
                        
                        echo ""
                        echo "Testing frontend..."
                        curl -s http://localhost:31349 | head -5 || echo "Frontend not responding"
                        
                        echo ""
                        echo "✅ Application should be accessible"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 CI/CD Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            echo "Build #${BUILD_NUMBER} - ${currentBuild.currentResult}"
        }
    }
}