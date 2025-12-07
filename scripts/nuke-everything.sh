#!/bin/bash
echo "💥 NUKE EVERYTHING - Complete Cleanup"
echo "======================================"
echo "This will destroy ALL resources"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted."
    exit 1
fi

echo ""
echo "🚀 Starting complete destruction..."

# 1. Stop all port-forwards
echo "1. 🛑 Stopping all port-forward processes..."
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 2

# 2. Delete everything from Kubernetes
echo "2. 🗑️  Deleting all Kubernetes resources..."
kubectl delete --all all --all-namespaces 2>/dev/null || true
kubectl delete namespace student-app jenkins 2>/dev/null || true
kubectl delete pvc --all --all-namespaces 2>/dev/null || true
kubectl delete pv --all 2>/dev/null || true

# 3. Delete KIND cluster
echo "3. 🗑️  Deleting KIND cluster..."
kind delete cluster --name student-app 2>/dev/null || true
kind delete cluster --all 2>/dev/null || true

# 4. Remove Docker images
echo "4. 🗑️  Removing Docker images..."
docker rm -f $(docker ps -aq) 2>/dev/null || true
docker rmi -f $(docker images | grep "student-" | awk '{print $3}') 2>/dev/null || true
docker rmi -f student-backend:latest student-frontend:latest 2>/dev/null || true
docker system prune -a -f --volumes 2>/dev/null || true

# 5. Clean kubeconfig
echo "5. 🧹 Cleaning kubeconfig..."
rm -f ~/.kube/config
rm -rf /var/lib/jenkins/.kube 2>/dev/null || true

# 6. Wait
sleep 5

echo ""
echo "✅ COMPLETE DESTRUCTION FINISHED!"
echo ""
echo "📊 Verification:"
echo "KIND clusters: $(kind get clusters 2>/dev/null | wc -l || echo 0)"
echo "Docker student images: $(docker images | grep -c student- || echo 0)"
echo "Kubernetes pods: $(kubectl get pods --all-namespaces 2>/dev/null | wc -l || echo 0)"
echo ""
echo "✨ Everything is now clean!"
echo "Run your Jenkins pipeline to recreate everything automatically."