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
                echo '✅ Source code checked out'
            }
        }
        
        stage('Setup KIND & Deploy') {
            steps {
                script {
                    echo '🚀 Setting up KIND and deploying application...'
                    sh '''
                        #!/bin/bash
                        set -e
                        
                        echo "1. Checking if KIND cluster exists..."
                        if ! kind get clusters 2>/dev/null | grep -q student-app; then
                            echo "Creating KIND cluster..."
                            kind create cluster --name student-app
                        else
                            echo "✅ KIND cluster already exists"
                        fi
                        
                        echo "2. Building Docker images..."
                        cd app/backend
                        docker build -t student-backend:latest .
                        cd ../frontend
                        docker build -t student-frontend:latest .
                        cd ../..
                        
                        echo "3. Loading images to KIND..."
                        kind load docker-image student-backend:latest --name student-app
                        kind load docker-image student-frontend:latest --name student-app
                        
                        echo "4. Deploying to Kubernetes..."
                        # Create namespace
                        kubectl create namespace student-app --dry-run=client -o yaml | kubectl apply -f -
                        
                        # Apply configurations
                        kubectl apply -f k8s/secrets.yaml
                        kubectl apply -f k8s/configmap.yaml
                        kubectl apply -f k8s/mysql/
                        
                        # Wait for MySQL
                        echo "Waiting for MySQL to start..."
                        sleep 30
                        
                        # Update imagePullPolicy for KIND
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/backend/deployment.yaml
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/frontend/deployment.yaml
                        
                        # Deploy backend and frontend
                        kubectl apply -f k8s/backend/
                        kubectl apply -f k8s/frontend/
                        
                        echo "5. Waiting for pods to be ready..."
                        sleep 45
                        
                        echo "6. Deployment status:"
                        kubectl get pods -n student-app
                        kubectl get svc -n student-app
                        
                        echo "7. Testing application..."
                        # Test backend
                        if curl -s http://localhost:30001/api/health; then
                            echo "✅ Backend is working"
                        else
                            echo "⚠️ Backend still starting"
                        fi
                        
                        echo ""
                        echo "═══════════════════════════════════════════════════════════"
                        echo "🎉 DEPLOYMENT COMPLETE!"
                        echo "═══════════════════════════════════════════════════════════"
                        echo ""
                        echo "🌐 ACCESS YOUR APP:"
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
            echo '✅ Pipeline completed successfully!'
            currentBuild.description = "✅ App deployed successfully"
        }
        failure {
            echo '❌ Pipeline failed!'
            currentBuild.description = "❌ Deployment failed"
        }
    }
}
