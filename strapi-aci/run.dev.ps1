# Powershell
docker run -d -p 8080:8080 -ti -v ${PWD}/tmp/:/opt/app/tmp <your_project_name>_strapi_v4_aci:latest

# Cmd
# docker run -d -p 8080:8080 -ti -v %cd%/tmp/:/opt/app/tmp <your_project_name>_strapi_v4_aci:latest

# Linux
# docker run -d -p 8080:8080 -ti -v $(pwd)/tmp/:/opt/app/tmp <your_project_name>_strapi_v4_aci:latest
