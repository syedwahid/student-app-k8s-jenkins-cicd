pipeline {
    agent any
    
    environment {
        APP_NAME = "student-app"
        KUBE_NAMESPACE = "student-app"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ Source code checked out"
            }
        }
        
        stage('Setup KIND') {
            steps {
                script {
                    echo "☸️ Setting up KIND cluster"
                    sh """
                        # Check if KIND cluster exists
                        if ! kind get clusters | grep -q student-app; then
                            echo "Creating KIND cluster..."
                            # Create simple config
                            echo 'kind: Cluster' > /tmp/kind-config.yaml
                            echo 'apiVersion: kind.x-k8s.io/v1alpha4' >> /tmp/kind-config.yaml
                            echo 'nodes:' >> /tmp/kind-config.yaml
                            echo '- role: control-plane' >> /tmp/kind-config.yaml
                            echo '  extraPortMappings:' >> /tmp/kind-config.yaml
                            echo '  - containerPort: 30001' >> /tmp/kind-config.yaml
                            echo '    hostPort: 30001' >> /tmp/kind-config.yaml
                            echo '    protocol: tcp' >> /tmp/kind-config.yaml
                            echo '  - containerPort: 31349' >> /tmp/kind-config.yaml
                            echo '    hostPort: 31349' >> /tmp/kind-config.yaml
                            echo '    protocol: tcp' >> /tmp/kind-config.yaml
                            
                            kind create cluster --name student-app --config /tmp/kind-config.yaml
                        else
                            echo "✅ KIND cluster already exists"
                        fi
                        
                        kubectl get nodes
                    """
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo "🐳 Building Docker images"
                    sh """
                        echo "Building backend..."
                        cd app/backend
                        docker build -t student-backend:latest .
                        
                        echo "Building frontend..."
                        cd ../frontend
                        docker build -t student-frontend:latest .
                        
                        echo "✅ Images built"
                        docker images | grep student-
                    """
                }
            }
        }
        
        stage('Load to KIND') {
            steps {
                script {
                    echo "📦 Loading images to KIND"
                    sh """
                        kind load docker-image student-backend:latest --name student-app
                        kind load docker-image student-frontend:latest --name student-app
                        echo "✅ Images loaded to KIND"
                    """
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo "🚀 Deploying to Kubernetes"
                    sh """
                        # Update for KIND
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/backend/deployment.yaml
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/frontend/deployment.yaml
                        
                        # Deploy
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/secrets.yaml
                        kubectl apply -f k8s/configmap.yaml
                        kubectl apply -f k8s/backend/
                        kubectl apply -f k8s/frontend/
                        
                        echo "⏳ Waiting 30 seconds..."
                        sleep 30
                        
                        echo "📊 Deployment status:"
                        kubectl get all -n student-app
                    """
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    echo "🧪 Testing application"
                    sh """
                        echo "Testing backend..."
                        curl -s http://localhost:30001/api/health || echo "Backend not ready"
                        
                        echo ""
                        echo "Testing frontend..."
                        curl -s http://localhost:31349 | head -3 || echo "Frontend not ready"
                        
                        echo ""
                        echo "🌐 Access URLs:"
                        echo "Frontend: http://localhost:31349"
                        echo "Backend: http://localhost:30001/api/health"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
        always {
            echo "Build #${BUILD_NUMBER} - ${currentBuild.currentResult}"
        }
    }
}
