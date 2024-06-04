# providers.tf
provider "kubernetes" {
  config_path = "C:/Users/Lenovo/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "C:/Users/Lenovo/.kube/config"
  }
}
