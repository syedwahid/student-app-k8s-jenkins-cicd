pipeline {
    agent any
    
    environment {
        APP_NAME = "student-app"
        KUBE_NAMESPACE = "student-app"
    }
    
    stages {
        stage('Destroy Existing Resources') {
            steps {
                script {
                    echo '💥 Cleaning up existing resources...'
                    sh '''
                        echo "1. Stopping port-forwards..."
                        pkill -f "kubectl port-forward" 2>/dev/null || true
                        
                        echo "2. Deleting KIND cluster if exists..."
                        sudo kind delete cluster --name student-app 2>/dev/null || true
                        
                        echo "3. Removing old Docker images..."
                        sudo docker rmi -f student-backend:latest student-frontend:latest 2>/dev/null || true
                        
                        echo "✅ Cleanup complete"
                    '''
                }
            }
        }
        
        stage('Create KIND Cluster') {
            steps {
                script {
                    echo '☸️ Creating fresh KIND cluster...'
                    sh '''
                        echo "Creating KIND configuration in workspace..."
                        # Use workspace directory instead of /tmp
                        cat > ${WORKSPACE}/kind-config.yaml << 'EOF'
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
EOF
                        
                        echo "Creating KIND cluster..."
                        sudo kind create cluster --name student-app --config ${WORKSPACE}/kind-config.yaml
                        
                        echo "Setting up kubeconfig..."
                        sudo mkdir -p /var/lib/jenkins/.kube
                        sudo kind get kubeconfig --name student-app | \\
                            sudo tee /var/lib/jenkins/.kube/config
                        sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
                        sudo chmod 600 /var/lib/jenkins/.kube/config
                        
                        # Also set up local kubeconfig
                        kind get kubeconfig --name student-app > ~/.kube/config
                        
                        echo "✅ KIND cluster created"
                        kubectl get nodes
                    '''
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo '🐳 Building fresh Docker images...'
                    sh '''
                        echo "Building backend image..."
                        cd app/backend
                        sudo docker build -t student-backend:latest .
                        
                        echo "Building frontend image..."
                        cd ../frontend
                        sudo docker build -t student-frontend:latest .
                        
                        echo "✅ Docker images built:"
                        sudo docker images | grep student-
                    '''
                }
            }
        }
        
        stage('Load Images to KIND') {
            steps {
                script {
                    echo '📦 Loading images to KIND cluster...'
                    sh '''
                        echo "Loading backend image..."
                        sudo kind load docker-image student-backend:latest --name student-app
                        
                        echo "Loading frontend image..."
                        sudo kind load docker-image student-frontend:latest --name student-app
                        
                        echo "✅ Images loaded to KIND"
                    '''
                }
            }
        }
        
        stage('Prepare Kubernetes Manifests') {
            steps {
                script {
                    echo '🔄 Preparing manifests for KIND...'
                    sh '''
                        echo "1. Backing up original manifests..."
                        cp k8s/backend/deployment.yaml k8s/backend/deployment.yaml.backup
                        cp k8s/frontend/deployment.yaml k8s/frontend/deployment.yaml.backup
                        
                        echo "2. Setting imagePullPolicy to Never (required for KIND)..."
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/backend/deployment.yaml
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/frontend/deployment.yaml
                        
                        echo "3. Ensuring correct image names..."
                        sed -i 's|image:.*student-backend.*|image: student-backend:latest|g' k8s/backend/deployment.yaml
                        sed -i 's|image:.*student-frontend.*|image: student-frontend:latest|g' k8s/frontend/deployment.yaml
                        
                        echo "✅ Manifests prepared"
                    '''
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                script {
                    echo '🚀 Deploying Student Management App...'
                    sh '''
                        echo "1. Creating namespace..."
                        kubectl create namespace student-app --dry-run=client -o yaml | kubectl apply -f -
                        
                        echo "2. Applying base configurations..."
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/secrets.yaml
                        kubectl apply -f k8s/configmap.yaml
                        
                        echo "3. Deploying Backend..."
                        kubectl apply -f k8s/backend/
                        
                        echo "4. Deploying Frontend..."
                        kubectl apply -f k8s/frontend/
                        
                        echo "⏳ Waiting for pods to start (45 seconds)..."
                        sleep 45
                        
                        echo "📊 Deployment status:"
                        kubectl get all -n student-app
                    '''
                }
            }
        }
        
        stage('Test Application') {
            steps {
                script {
                    echo '🧪 Testing application...'
                    sh '''
                        echo "Testing backend API..."
                        BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:30001/api/health 2>/dev/null || echo "FAILED")
                        if [ "$BACKEND_STATUS" = "200" ]; then
                            echo "✅ Backend is working (HTTP $BACKEND_STATUS)"
                            curl -s http://localhost:30001/api/health | grep status || echo "No status in response"
                        else
                            echo "❌ Backend not responding (Status: $BACKEND_STATUS)"
                        fi
                        
                        echo ""
                        echo "Testing frontend..."
                        FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:31349 2>/dev/null || echo "FAILED")
                        if [ "$FRONTEND_STATUS" = "200" ]; then
                            echo "✅ Frontend is working (HTTP $FRONTEND_STATUS)"
                        else
                            echo "⚠️ Frontend status: $FRONTEND_STATUS"
                        fi
                        
                        echo ""
                        echo "🌐 Application URLs:"
                        echo "Frontend: http://localhost:31349"
                        echo "Backend: http://localhost:30001/api/health"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 AUTOMATED DEPLOYMENT COMPLETED SUCCESSFULLY!'
        }
        failure {
            echo '❌ DEPLOYMENT FAILED!'
        }
        always {
            echo "Build #${BUILD_NUMBER} completed"
        }
    }
}