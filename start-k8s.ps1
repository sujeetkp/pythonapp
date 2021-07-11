kubectl apply -f ./k8s/app-persistent-volume-claim.yml
kubectl apply -f ./k8s/db-persistent-volume-claim.yml
kubectl apply -f ./k8s/postgres-deployment.yml
kubectl apply -f ./k8s/postgres-service.yml
Start-Sleep 60
kubectl apply -f ./k8s/app-deployment.yml
kubectl apply -f ./k8s/app-service.yml
Start-Sleep 20
kubectl apply -f ./k8s/nginx-deployment.yml
kubectl apply -f ./k8s/nginx-service.yml