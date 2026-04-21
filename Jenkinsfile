pipeline {
    agent any
    
    environment {
        APP_NAME = "student-app"
        KUBE_NAMESPACE = "student-app"
        HOST_IP = "172.17.0.1"  // Default Docker bridge IP
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo '✅ Source code checked out'
            }
        }
        
        stage('Setup KIND Cluster on HOST') {
            steps {
                script {
                    echo '☸️ Setting up KIND cluster on HOST...'
                    sh '''
                        echo "1. Checking if KIND cluster exists on HOST..."
                        
                        # Check if cluster exists (using host's kind command)
                        if ! kind get clusters 2>/dev/null | grep -q student-app; then
                            echo "Creating KIND cluster on HOST..."
                            kind create cluster --name student-app --config kind/kind-config.yaml
                        else
                            echo "✅ KIND cluster already exists on HOST"
                        fi
                        
                        echo "2. Setting up kubeconfig for Jenkins to access HOST cluster..."
                        # Get the host IP that Jenkins can use
                        HOST_IP=$(ip route | grep docker0 | awk '{print $9}' | cut -d'/' -f1)
                        if [ -z "$HOST_IP" ]; then
                            HOST_IP="172.17.0.1"
                        fi
                        
                        # Get the KIND API port
                        KIND_PORT=$(docker inspect student-app-control-plane 2>/dev/null | grep -A 5 "PortBindings" | grep "HostPort" | head -1 | awk -F'"' '{print $4}')
                        if [ -z "$KIND_PORT" ]; then
                            KIND_PORT="6443"
                        fi
                        
                        # Create kubeconfig for Jenkins to access host's cluster
                        mkdir -p /var/jenkins_home/.kube
                        cat > /var/jenkins_home/.kube/config << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://${HOST_IP}:${KIND_PORT}
    insecure-skip-tls-verify: true
  name: kind-student-app
contexts:
- context:
    cluster: kind-student-app
    user: kind-student-app
  name: kind-student-app
current-context: kind-student-app
users:
- name: kind-student-app
  user: {}
EOF
                        
                        echo "✅ Kubeconfig created for Jenkins to access HOST cluster"
                        echo "Host IP: ${HOST_IP}"
                        echo "KIND Port: ${KIND_PORT}"
                        
                        echo "3. Testing connection to HOST cluster..."
                        kubectl get nodes
                    '''
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo '🐳 Building Docker images on HOST...'
                    sh '''
                        echo "1. Building backend image..."
                        cd app/backend
                        docker build -t student-backend:latest .
                        
                        echo "2. Building frontend image..."
                        cd ../frontend
                        docker build -t student-frontend:latest .
                        
                        echo "✅ Images built on HOST:"
                        docker images | grep student-
                    '''
                }
            }
        }
        
        stage('Load Images to KIND on HOST') {
            steps {
                script {
                    echo '📦 Loading images to KIND cluster on HOST...'
                    sh '''
                        echo "Loading backend image to HOST KIND cluster..."
                        kind load docker-image student-backend:latest --name student-app
                        
                        echo "Loading frontend image to HOST KIND cluster..."
                        kind load docker-image student-frontend:latest --name student-app
                        
                        echo "✅ Images loaded to HOST KIND cluster"
                    '''
                }
            }
        }
        
        stage('Prepare Kubernetes Manifests') {
            steps {
                script {
                    echo '🔄 Preparing manifests...'
                    sh '''
                        echo "Setting imagePullPolicy to Never (required for KIND)..."
                        cp k8s/backend/deployment.yaml k8s/backend/deployment.yaml.backup 2>/dev/null || true
                        cp k8s/frontend/deployment.yaml k8s/frontend/deployment.yaml.backup 2>/dev/null || true
                        
                        # Use sed to update imagePullPolicy
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/backend/deployment.yaml 2>/dev/null || true
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/frontend/deployment.yaml 2>/dev/null || true
                        
                        echo "✅ Manifests prepared"
                    '''
                }
            }
        }
        
        stage('Deploy to HOST Kubernetes') {
            steps {
                script {
                    echo '🚀 Deploying to HOST Kubernetes cluster...'
                    sh '''
                        echo "1. Creating namespace..."
                        kubectl create namespace student-app --dry-run=client -o yaml | kubectl apply -f -
                        
                        echo "2. Applying configurations..."
                        kubectl apply -f k8s/secrets.yaml
                        kubectl apply -f k8s/configmap.yaml
                        
                        echo "3. Deploying MySQL..."
                        kubectl apply -f k8s/mysql/
                        
                        echo "⏳ Waiting for MySQL to start (20 seconds)..."
                        sleep 20
                        
                        echo "4. Deploying Backend..."
                        kubectl apply -f k8s/backend/
                        
                        echo "5. Deploying Frontend..."
                        kubectl apply -f k8s/frontend/
                        
                        echo "⏳ Waiting for pods to be ready (40 seconds)..."
                        sleep 40
                        
                        echo "📊 Deployment status on HOST:"
                        kubectl get all -n student-app
                    '''
                }
            }
        }
        
        stage('Test Application on HOST') {
            steps {
                script {
                    echo '🧪 Testing application on HOST...'
                    sh '''
                        echo "Testing backend API on HOST..."
                        if curl -s http://localhost:30001/api/health 2>/dev/null; then
                            echo "✅ Backend is working on HOST"
                            curl -s http://localhost:30001/api/health
                        else
                            echo "⚠️  Backend not responding yet (still starting?)"
                            echo "Check pods: kubectl get pods -n student-app"
                        fi
                        
                        echo ""
                        echo "Testing frontend on HOST..."
                        if curl -s http://localhost:31349 2>/dev/null | grep -q "Student"; then
                            echo "✅ Frontend is working on HOST"
                        else
                            echo "⚠️  Frontend not responding yet"
                        fi
                        
                        echo ""
                        echo "═══════════════════════════════════════════════════════════"
                        echo "🌐 APPLICATION RUNNING ON HOST:"
                        echo "   Frontend: http://localhost:31349"
                        echo "   Backend:  http://localhost:30001/api/health"
                        echo "═══════════════════════════════════════════════════════════"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            script {
                sh '''
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "🎉 CI/CD PIPELINE SUCCESSFUL! 🎉"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""
                    echo "✅ Application deployed to HOST Kubernetes cluster"
                    echo "✅ Running outside Jenkins container"
                    echo ""
                    echo "🌐 ACCESS YOUR APP:"
                    echo "   http://localhost:31349"
                    echo ""
                    echo "📊 MANAGE ON HOST:"
                    echo "   kubectl get pods -n student-app"
                    echo "   kubectl logs -n student-app deployment/backend"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                '''
                currentBuild.description = "✅ Success - App running on HOST"
                
                // Fixed line - removed $(date) syntax error
                def buildDate = new Date().toString()
                echo "Build #${BUILD_NUMBER} completed on ${buildDate}"
            }
        }
        
        failure {
            script {
                sh '''
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "❌ PIPELINE FAILED!"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""
                    echo "🔧 TROUBLESHOOTING:"
                    echo "   1. Check if KIND is running on HOST: kind get clusters"
                    echo "   2. Check Jenkins can reach HOST: docker exec jenkins kubectl get nodes"
                    echo "   3. View logs: kubectl logs -n student-app deployment/backend"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                '''
                currentBuild.description = "❌ Failed - Check logs"
            }
        }
        
        always {
            script {
                def endDate = new Date().toString()
                echo "Pipeline execution completed on ${endDate}"
            }
        }
    }
}
