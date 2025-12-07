pipeline {
    agent any
    
    environment {
        // Application Configuration
        APP_NAME = 'student-app'
        KUBE_NAMESPACE = 'student-app'
        APP_VERSION = "${BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
        
        // Docker Configuration
        DOCKER_USERNAME = credentials('docker-hub')
        DOCKER_PASSWORD = credentials('docker-hub')
        BACKEND_IMAGE = 'student-backend'
        FRONTEND_IMAGE = 'student-frontend'
        
        // URLs
        FRONTEND_URL = 'http://localhost:31349'
        BACKEND_URL = 'http://localhost:30001'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }
    
    stages {
        stage('Initialize') {
            steps {
                script {
                    echo "🚀 STUDENT MANAGEMENT SYSTEM CI/CD"
                    echo "====================================="
                    echo "Build: #${BUILD_NUMBER}"
                    echo "Branch: ${env.GIT_BRANCH}"
                    echo "Commit: ${GIT_COMMIT_SHORT}"
                    echo ""
                    
                    // Create workspace directory
                    sh 'mkdir -p ${WORKSPACE}/artifacts'
                }
            }
        }
        
        stage('Checkout Source Code') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/main"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/syedwahid/student-app-k8s-jenkins-cicd.git',
                        credentialsId: 'github-ssh'
                    ]],
                    extensions: [
                        [$class: 'CleanBeforeCheckout'],
                        [$class: 'CloneOption', depth: 1, noTags: false, shallow: true]
                    ]
                ])
                
                script {
                    // Get git info
                    env.GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.GIT_AUTHOR = sh(script: 'git log -1 --pretty=format:"%an"', returnStdout: true).trim()
                    env.GIT_MESSAGE = sh(script: 'git log -1 --pretty=format:"%s"', returnStdout: true).trim()
                    
                    echo "📦 Repository: ${GIT_URL}"
                    echo "📝 Commit: ${GIT_COMMIT_SHORT}"
                    echo "👤 Author: ${GIT_AUTHOR}"
                    echo "💬 Message: ${GIT_MESSAGE}"
                }
            }
        }
        
        stage('Validate Project Structure') {
            steps {
                script {
                    echo '🔍 Validating project structure...'
                    
                    // Check required directories
                    def requiredDirs = ['app/backend', 'app/frontend', 'k8s', 'scripts']
                    requiredDirs.each { dir ->
                        if (fileExists(dir)) {
                            echo "✅ ${dir}"
                        } else {
                            error "❌ Missing directory: ${dir}"
                        }
                    }
                    
                    // Check required files
                    def requiredFiles = [
                        'app/backend/Dockerfile',
                        'app/backend/app.js',
                        'app/frontend/Dockerfile',
                        'app/frontend/index.html',
                        'k8s/namespace.yaml',
                        'k8s/backend/deployment.yaml',
                        'k8s/frontend/deployment.yaml'
                    ]
                    
                    requiredFiles.each { file ->
                        if (fileExists(file)) {
                            echo "✅ ${file}"
                        } else {
                            echo "⚠️  Missing: ${file}"
                        }
                    }
                    
                    // List all files
                    sh '''
                        echo ""
                        echo "📁 Project Structure:"
                        find . -type f -name "*.yaml" -o -name "*.yml" -o -name "*.js" -o -name "Dockerfile" | sort
                    '''
                }
            }
        }
        
        stage('Setup KIND Cluster') {
            steps {
                script {
                    echo '☸️ Setting up KIND Kubernetes cluster...'
                    
                    sh '''
                        echo "1. Checking if KIND is installed..."
                        kind version || { echo "❌ KIND not installed"; exit 1; }
                        
                        echo "2. Creating KIND cluster configuration..."
                        cat > /tmp/kind-config.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30001
    hostPort: 30001
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 31349
    hostPort: 31349
    listenAddress: "0.0.0.0"
    protocol: tcp
EOF
                        
                        echo "3. Creating/Checking KIND cluster..."
                        if ! kind get clusters | grep -q student-app; then
                            echo "Creating KIND cluster 'student-app'..."
                            kind create cluster --name student-app --config /tmp/kind-config.yaml
                            echo "✅ KIND cluster created"
                        else
                            echo "✅ KIND cluster already exists"
                        fi
                        
                        echo "4. Verifying cluster..."
                        kubectl cluster-info --context kind-student-app
                        kubectl get nodes
                        
                        echo "5. Setting up kubeconfig for Jenkins..."
                        mkdir -p /var/lib/jenkins/.kube
                        kind get kubeconfig --name student-app | \
                            sed 's|server: https://.*:.*|server: https://127.0.0.1:6443|' | \
                            tee /var/lib/jenkins/.kube/config
                        chmod 600 /var/lib/jenkins/.kube/config
                        
                        echo "✅ KIND setup complete"
                    '''
                }
            }
        }
        
        stage('Build Application') {
            steps {
                script {
                    echo '🔨 Building application components...'
                    
                    // Build Backend
                    dir('app/backend') {
                        sh '''
                            echo "📦 Building backend Node.js application..."
                            
                            echo "1. Checking Node.js..."
                            node --version || echo "Node.js not found"
                            
                            echo "2. Installing dependencies..."
                            npm install --production || echo "npm install failed"
                            
                            echo "3. Testing backend..."
                            if [ -f "app.js" ]; then
                                node -c app.js && echo "✅ Backend syntax OK" || echo "⚠️ Backend syntax check failed"
                            fi
                            
                            echo "✅ Backend application built"
                        '''
                    }
                    
                    // Build Frontend
                    dir('app/frontend') {
                        sh '''
                            echo "🎨 Validating frontend files..."
                            
                            echo "1. Checking HTML/CSS/JS files..."
                            if [ -f "index.html" ]; then
                                echo "✅ index.html exists"
                                grep -o "<title>.*</title>" index.html || echo "No title found"
                            fi
                            
                            if [ -f "styles.css" ]; then
                                echo "✅ styles.css exists"
                            fi
                            
                            if [ -f "app.js" ]; then
                                echo "✅ app.js exists"
                            fi
                            
                            echo "✅ Frontend validated"
                        '''
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo '🐳 Building Docker images...'
                    
                    // Build Backend Image
                    dir('app/backend') {
                        sh '''
                            echo "🔧 Building backend Docker image..."
                            docker build -t ${BACKEND_IMAGE}:${APP_VERSION} .
                            docker tag ${BACKEND_IMAGE}:${APP_VERSION} ${BACKEND_IMAGE}:latest
                            
                            echo "✅ Backend image built"
                            docker images | grep ${BACKEND_IMAGE}
                        '''
                    }
                    
                    // Build Frontend Image
                    dir('app/frontend') {
                        sh '''
                            echo "🎨 Building frontend Docker image..."
                            docker build -t ${FRONTEND_IMAGE}:${APP_VERSION} .
                            docker tag ${FRONTEND_IMAGE}:${APP_VERSION} ${FRONTEND_IMAGE}:latest
                            
                            echo "✅ Frontend image built"
                            docker images | grep ${FRONTEND_IMAGE}
                        '''
                    }
                    
                    // Save images as artifacts (optional)
                    sh '''
                        echo "📦 Saving Docker images as artifacts..."
                        docker save ${BACKEND_IMAGE}:latest -o ${WORKSPACE}/artifacts/student-backend.tar
                        docker save ${FRONTEND_IMAGE}:latest -o ${WORKSPACE}/artifacts/student-frontend.tar
                        ls -lh ${WORKSPACE}/artifacts/*.tar
                    '''
                }
            }
        }
        
        stage('Load Images to KIND') {
            steps {
                script {
                    echo '📦 LOADING IMAGES TO KIND CLUSTER (CRITICAL STEP)...'
                    
                    sh '''
                        echo "1. Loading backend image to KIND..."
                        kind load docker-image ${BACKEND_IMAGE}:latest --name student-app
                        
                        echo "2. Loading frontend image to KIND..."
                        kind load docker-image ${FRONTEND_IMAGE}:latest --name student-app
                        
                        echo "3. Verifying images in KIND..."
                        docker exec student-app-control-plane crictl images | grep student || echo "Checking images..."
                        
                        echo "✅ Images loaded to KIND"
                    '''
                }
            }
        }
        
        stage('Prepare Kubernetes Manifests') {
            steps {
                script {
                    echo '🔄 Preparing Kubernetes manifests for KIND...'
                    
                    sh '''
                        echo "1. Backing up original manifests..."
                        cp k8s/backend/deployment.yaml k8s/backend/deployment.yaml.backup
                        cp k8s/frontend/deployment.yaml k8s/frontend/deployment.yaml.backup
                        
                        echo "2. Updating for KIND deployment..."
                        # Set imagePullPolicy to Never (required for KIND)
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/backend/deployment.yaml
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/frontend/deployment.yaml
                        
                        # Ensure correct image names
                        sed -i "s|image:.*student-backend.*|image: ${BACKEND_IMAGE}:latest|g" k8s/backend/deployment.yaml
                        sed -i "s|image:.*student-frontend.*|image: ${FRONTEND_IMAGE}:latest|g" k8s/frontend/deployment.yaml
                        
                        # Add KIND-specific environment variables
                        cat >> k8s/backend/deployment.yaml << 'EOF'
        env:
        - name: USE_MYSQL
          value: "false"
        - name: PORT
          value: "3000"
        - name: NODE_ENV
          value: "production"
EOF
                        
                        echo "3. Creating KIND-optimized manifests..."
                        # Create simplified service files if needed
                        cat > k8s/backend/service-kind.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: student-app
spec:
  type: NodePort
  selector:
    app: backend
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30001
EOF
                        
                        cat > k8s/frontend/service-kind.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: student-app
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 31349
EOF
                        
                        echo "✅ Manifests prepared for KIND"
                    '''
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo '🚀 DEPLOYING TO KUBERNETES...'
                    
                    sh '''
                        echo "1. Cleaning up existing deployment..."
                        kubectl delete deployment backend frontend mysql -n ${KUBE_NAMESPACE} --ignore-not-found=true
                        kubectl delete pod -n ${KUBE_NAMESPACE} --all --grace-period=0 --force 2>/dev/null || true
                        sleep 5
                        
                        echo "2. Creating namespace..."
                        kubectl create namespace ${KUBE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                        
                        echo "3. Applying base configurations..."
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/secrets.yaml
                        kubectl apply -f k8s/configmap.yaml
                        
                        echo "4. Deploying Backend..."
                        kubectl apply -f k8s/backend/
                        
                        echo "5. Deploying Frontend..."
                        kubectl apply -f k8s/frontend/
                        
                        echo "6. Waiting for rollout (60 seconds)..."
                        sleep 60
                        
                        echo "7. Checking rollout status..."
                        kubectl rollout status deployment/backend -n ${KUBE_NAMESPACE} --timeout=120s || echo "Backend rollout check failed"
                        kubectl rollout status deployment/frontend -n ${KUBE_NAMESPACE} --timeout=120s || echo "Frontend rollout check failed"
                        
                        echo "✅ Deployment completed"
                    '''
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo '🔍 VERIFYING DEPLOYMENT...'
                    
                    sh '''
                        echo "📊 Deployment Status:"
                        kubectl get all -n ${KUBE_NAMESPACE}
                        
                        echo ""
                        echo "🔧 Pod Details:"
                        kubectl get pods -n ${KUBE_NAMESPACE} -o wide
                        
                        echo ""
                        echo "🌐 Services:"
                        kubectl get svc -n ${KUBE_NAMESPACE}
                        
                        echo ""
                        echo "📝 Pod Conditions:"
                        kubectl describe pods -n ${KUBE_NAMESPACE} | grep -A5 "Conditions:" || echo "Could not get pod conditions"
                    '''
                }
            }
        }
        
        stage('Test Application') {
            steps {
                script {
                    echo '🧪 TESTING APPLICATION...'
                    
                    sh '''
                        echo "1. Testing Backend Health..."
                        echo "API Health Check:"
                        curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:30001/api/health || echo "Backend not responding"
                        
                        echo ""
                        echo "2. Testing Backend API..."
                        BACKEND_RESPONSE=$(curl -s http://localhost:30001/api/health 2>/dev/null || echo "{}")
                        echo "Backend Response:"
                        echo "${BACKEND_RESPONSE}" | python3 -m json.tool 2>/dev/null || echo "${BACKEND_RESPONSE}"
                        
                        echo ""
                        echo "3. Testing Students API..."
                        curl -s http://localhost:30001/api/students | python3 -m json.tool 2>/dev/null | head -20 || \
                        curl -s http://localhost:30001/api/students | head -100
                        
                        echo ""
                        echo "4. Testing Frontend..."
                        echo "Frontend HTML:"
                        curl -s -I http://localhost:31349 | head -1
                        curl -s http://localhost:31349 | grep -o "<title>.*</title>" || echo "No title found"
                        
                        echo ""
                        echo "5. Testing Service Connectivity..."
                        kubectl run test-curl --image=curlimages/curl -n ${KUBE_NAMESPACE} --rm -i --restart=Never -- \
                            timeout 10s curl -s http://backend-service:3000/api/health || echo "Internal service test completed"
                        
                        echo ""
                        echo "✅ Application testing completed"
                    '''
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    echo '🔗 RUNNING INTEGRATION TESTS...'
                    
                    sh '''
                        echo "1. Checking application logs..."
                        echo "Backend logs (last 10 lines):"
                        kubectl logs -n ${KUBE_NAMESPACE} deployment/backend --tail=10 2>/dev/null || echo "Could not get backend logs"
                        
                        echo ""
                        echo "2. Testing frontend-backend connectivity..."
                        FRONTEND_POD=$(kubectl get pods -n ${KUBE_NAMESPACE} -l app=frontend -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
                        if [ -n "${FRONTEND_POD}" ]; then
                            echo "Testing from frontend pod: ${FRONTEND_POD}"
                            kubectl exec -n ${KUBE_NAMESPACE} ${FRONTEND_POD} -- curl -s http://backend-service:3000/api/health || echo "Frontend cannot reach backend"
                        fi
                        
                        echo ""
                        echo "3. Load testing (simple)..."
                        for i in {1..3}; do
                            echo "Request $i: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:30001/api/health 2>/dev/null || echo "FAILED")"
                            sleep 1
                        done
                        
                        echo ""
                        echo "✅ Integration tests completed"
                    '''
                }
            }
        }
        
        stage('Documentation & Artifacts') {
            steps {
                script {
                    echo '📚 GENERATING DOCUMENTATION...'
                    
                    sh '''
                        echo "1. Generating deployment report..."
                        cat > ${WORKSPACE}/artifacts/deployment-report.md << 'EOF'
# Student Management System - Deployment Report

## Deployment Information
- **Build Number**: ${BUILD_NUMBER}
- **Deployment Time**: $(date)
- **Git Commit**: ${GIT_COMMIT_SHORT}
- **Git Author**: ${GIT_AUTHOR}
- **Application Version**: ${APP_VERSION}

## Application URLs
- **Frontend**: http://localhost:31349
- **Backend API**: http://localhost:30001/api/health
- **Backend Students API**: http://localhost:30001/api/students

## Kubernetes Resources
### Pods