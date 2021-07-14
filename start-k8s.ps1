kubectl apply -f ./k8s/postgres-persistent-volume-claim.yml
kubectl apply -f ./k8s/app-1-persistent-volume-claim.yml
kubectl apply -f ./k8s/postgres-deployment.yml
kubectl apply -f ./k8s/postgres-service.yml
Start-Sleep 60
kubectl apply -f ./k8s/app-1-deployment.yml
kubectl apply -f ./k8s/app-1-service.yml
kubectl apply -f ./k8s/app-1-hpa.yml
kubectl apply -f ./k8s/app-2-deployment.yml
kubectl apply -f ./k8s/app-2-service.yml
Start-Sleep 20
kubectl apply -f ./k8s/app-1-nginx-deployment.yml
kubectl apply -f ./k8s/app-1-nginx-service.yml

# Use Below for Nginx Deployment and Service
#kubectl apply -f ./k8s/nginx-deployment.yml
#kubectl apply -f ./k8s/nginx-service.yml

# Use below for Nginx Ingress Controller
kubectl apply -f ./k8s/ingress-service.yml
