az login
az acr login --name <your_acr_name>

docker build -t <your_project_name>_strapi_v4_aci:latest -f Dockerfile.prod .
docker tag <your_project_name>_strapi_v4_aci:latest <your_acr_name>.azurecr.io/<your_project_name>_strapi_v4_aci:latest
docker push <your_acr_name>.azurecr.io/<your_project_name>_strapi_v4_aci:latest
