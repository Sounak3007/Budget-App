![](https://img.shields.io/badge/Microverse-blueviolet)

# Budget-App deployment using Docker, Kubernetes, Terraform and Helm charts.  

## Description

> The Ruby on Rails capstone project ([remember what they are?](https://github.com/microverseinc/curriculum-html-css/blob/main/articles/capstone_intro.md)) is about building a mobile web application where you can manage your budget: you have a list of transactions associated with a category, so that you can see how much money you spent and on what.

- I created a Ruby on Rails application that allows the user to:

  - register and log in, so that the data is private to them.
  - introduce new transactions associated with a category.
  - see the money spent on each category.
  - Deploy as containers using Dockerfile and Docker compose
  - Deploy backend database using Helm charts
  - Deploy Monitoring tools grafana and prometheus using Terraform. 

### Screenshots 📸

    Categories
![](./app/assets/images/img1.png) 


    Category-Details 
![](./app/assets/images/img5.png) 

## Built With 🛠️

This project is build with:

-  ![Ruby](https://img.shields.io/badge/-Ruby-000000?style=flat&logo=ruby&logoColor=red)
-  ![Ruby on Rails](https://img.shields.io/badge/-Ruby_on_Rails-000000?style=flat&logo=ruby-on-rails&logoColor=blue)
-  Docker
-  Kuberbetes deployments
-  Helm Chart deployments
-  Terraform
-  Monitoring tools - grafana, prometheus

# Docker deployment 

## Step 1 : 

- Write a dockerfile for the application 

### Dockerfile:
```
FROM ruby:3.1.2
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
WORKDIR /app
RUN gem install bundler -v 2.3.6
COPY Gemfile Gemfile.lock ./
RUN bundle install 
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn
COPY config/database.yml /app/config/database.yml
COPY . .
COPY /db/migrate /app/db/migrate
COPY entrypoint.sh /usr/bin/entrypoint.sh
EXPOSE 3000 3001
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
```
## Step 2 :

- Build the docker image 
```
  command to build the docker image - docker build -t sounak3007/budgetapp:5 .
  command to push the docker image to docker hub - docker push sounak3007/budgetapp:5 
```
## Step 3 : 

- Deploy the containers using docker-compose file

Docker compose file for deploying the backend database and the application containers under the same docker network. Services with image postgres:latest and the previously build application image and pushed to docker hub image: docker.io/sounak3007/budgetapp:5 is used for deploying the sevices.  
```
command - docker-compose up 
```
### Docker-Compose file:
```
version: "4.5"

services:
  database_budjet-app:
    image: postgres:latest
    container_name: database_budjet-app
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: Budgy
      POSTGRES_PASSWORD: password
      POSTGRES_DB: Budgy_development
      POSTGRES_HOST_AUTH_METHOD: trust
    ports:
      - "5432:5432"

  web:
    image: docker.io/sounak3007/budgetapp:5
    container_name: webapp
    restart: always
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    depends_on:
      - database_budjet-app

volumes:
  db_data: 
```
## Step 4 :

- Verify if the app is running by visiting http://localhost:3000

# kubernetes-cluster-setup

## Step 1 :

- Using helm charts to deploy the postgres sql database pod to the kubernetes cluster 

  helm command :
```
helm install pgsql bitnami/postgresql   --set auth.username=Budgy   --set auth.database=Budgy_development  --set auth.enablePostgresUser=true   --set global.auth.database=Budgy_development   --set auth.password=password   --set global.auth.username=Budgy   --set primary.persistence.size=1Gi   --set image.tag=16.0.0-debian-11-r15
```
## Step 2 :

Write a deployment yaml file for the application to be deployed in the kubernetes cluster.

file path - ./kubedeploy/k8-deploy.yaml

### Deploymemt file :
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: budgetapp-deployment
  labels:
    app: budgetapp
  annotations: 
    sidecar.speedscale.com/cpu-request: 200m
    sidecar.speedscale.com/cpu-limit: 500m
spec:
  replicas: 1
  selector:
    matchLabels:
      app: budgetapp
  template:
    metadata:
      labels:
        app: budgetapp
    spec:
      containers:
        - name: budgetapp
          image: docker.io/sounak3007/budgetapp:5
          imagePullPolicy: Always
          ports:
            - name: http
              containerPort: 3000
              protocol: TCP
          resources:
            limits:
              cpu: "1"
              memory: "1000Mi"
```
- Kubernetes service type Load Balancer deployment yaml :
```
  apiVersion: v1
  kind: Service
  metadata:
    name: budgetapp-svc
    labels:
      app: budgetapp    
  spec:
    type: LoadBalancer
    ports:
      - port: 3000
        targetPort: http
        protocol: TCP
        name: http
    selector:
      app: budgetapp
```
## Step 3 :

- Configure yaml file for Horizontal Pod autoscaler.
  
  Values file path for deployment - ./kubedeploy/HPA.yaml

  yaml file config :
```
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: budgetapp-deployment
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 20
   ``` 
- Deploy the pod to kubernetes using the following command :
```
  kubectl apply -f ./kubedeploy/k8-deploy.yaml
  kubectl apply -f ./kubedeploy/HPA.yaml
```  
- test autoscaling
```
kubectl exec -it budgetapp-deployment-7549b6fddb-xvb5v -- bash -c " while sleep 0.01s; do wget http://localhost:3000; done"
```
- verify the deployments by using the following commands :
  ```
  kubectl get pods
  kubectl get svc
  helm list 
  ```
  visit http://localhost:3000/ to verify if the application is running. 

## CI/CD GitOps using ArgoCD 

- Installing ArgoCD
    ```
  1. kubectl create namespace argocd
  
  2. kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```
- Expose Argo CD with load balaner
  ```
  kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
  ```
- Get Argo CD password -
  ```
  kubectl get secret argocd-initial-admin-secret -o jsonpath={".data.password"} -n argocd | base64 --decode
  ```
- Visit the url - https://localhost:80

- Screenshot 

<img width="900" alt="image" src="https://github.com/Sounak3007/Budget-App/assets/118169528/9d5129bd-0d01-4793-9254-e123641637d6">

## Monitoring tool deployment using Terraform 

- Install terraform using the following link - https://developer.hashicorp.com/terraform/install#windows

- Write the following terrafrom files for prometheus and Grafana deployment to your kubernetes cluster

- grafana.tf
```
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"

  set {
    name  = "adminPassword"
    value = "admin"  # Set the Grafana admin password
  }

  set {
    name  = "service.type"
    value = "NodePort"  # Use NodePort or LoadBalancer based on your cluster setup
  }

  set {
    name  = "persistence.enabled"
    value = "false"  # Enable or disable persistent storage
  }
}
```
- prometheus.tf
```
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "15.8.0"

  set {
    name  = "server.persistentVolume.enabled"
    value = "false"
  }

  set {
    name  = "alertmanager.persistentVolume.enabled"
    value = "false"
  }

  set {
    name  = "pushgateway.persistentVolume.enabled"
    value = "false"
  }
  set {
    name  = "service.type"
    value = "NodePort"  # Use NodePort or LoadBalancer based on your cluster setup
  }
  # You can provide a map of value using yamlencode. Don't forget to escape the last element after point in the name
  set {
    name = "server\\.resources"
    value = yamlencode({
      limits = {
        cpu    = "200m"
        memory = "50Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "30Mi"
      }
    })
  }
}
```
- providers.tf
```
provider "kubernetes" {
  config_path = "C:/Users/Lenovo/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "C:/Users/Lenovo/.kube/config"
  }
}
```
- variables.tf
```
  variable "kube_config" {
  type    = string
  default = "C:/Users/Lenovo/.kube/config"
}

variable "namespace" {
  type    = string
  default = "monitoring"
}
```
## Terraform commands to deploy the monitoring tools - grafana and prometheus 

cd /Terraform
```
- terraform init
- terraform plan
- terraform apply 
```
- Expose the prometheus server using Kubectl :
  ```
  kubectl expose svc prometheus-server --type=NodePort --target-port=9090 --name=prometheus-server-nodeport
  ```
