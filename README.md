# nestjs-mysql-aks

## Configuration

- kind create cluster --name "kluster"
- Build nestjs app

```bash
cd app
docker build -t nestjs-app .
docker run -p 3000:3000 nestjs-app #Just to validate if the app is running
```

- kind load docker-image nestjs-app --name "kluster"
- kubectl apply -f kubernetes/bases/app
- `kubectl port-forward services/backend 3000:80` to test locally
- access the localhost:3000
- Terraform

```bash
cd terraform-live/
terraform init
terraform plan -var-file="dev.tfvars" -out="dev.plan"
terraform apply "dev.plan"
```

- ACR

```bash
az acr login -n <ACR>
docker tag nestjs-app <ACR>.azurecr.io/nestjs-app:latest
docker push <ACR>.azurecr.io/nestjs-app
```

- Configure the managed identity from AKS to have role of ACRPull in the ACR

- AKS

```bash
az aks get-credentials --resource-group <RG> --name <AKS>
az aks update -n <AKS> -g <RG> --attach-acr <ACR>
kubectl get nodes
kubectl apply -f .\app\

```
