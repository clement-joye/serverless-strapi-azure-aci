# Introduction

Template for running Strapi v4 as serverless instance with Azure container Instances (ACI).  
The project is divived in three parts:  
- **Strapi v4** docker image wrapped in a **node.js** application
- Powershell Azure function starting/stopping the ACI (Http Trigger)
- Terraform script 

The principle is simple:
- When a users/editors needs to access **Strapi**, they send a request to an **Azure function**.  
- The Azure function does the work of **starting** an ACI running Strapi v4.  
- Once the ACI is ready and running, the Azure function returns a **redirect response** and the user is automatically redirected to the **ACI public url**.
- The instance stays up for as long as the user needs it, and only once Strapi remains idle for a specific amount of time (default value set to **10 min**), the node.js application running Strapi sends a request to an Azure function that takes care of **stopping** the ACI.

As Strapi does not handle ssl, a **reverse proxy** is deployed in front of Strapi (**Caddy** web server) as a sidecar container.


# Prerequisites

- Prior knowledge of Strapi, the Azure platform and Terraform are recommended.  
- Deployment without Terraform is possible as well, but not covered here.  

In order to start off, you will need to have the following:
- Terraform installed locally
- An Azure subscription with admin rights
- A container registry, preferably private (I use Azure Container Registry (ACR) in this template but any other should work as well)
- Node.js v12 or v14 (preferred for Strapi v4)  
- npm v6 or yarn
- Docker
- Powershell (including az cli)
- DB Browser (SQLite)

# Installation

- Clone git repository
- Open a command line:
```
cd strapi-aci
yarn install
yarn build
yarn develop
```
After that an SQLite file should be present in ```./strapi-aci/tmp/``` folder.
Open the file with **DB Browser (SQLite)** and run the pragma command:
> PRAGMA journal_mode=WAL;  

This step will run the SQLite instance in **WAL** mode (Write Ahead Logging) and is **necessary** in order to run SQLite on an Azure File Share with Strapi in ACI.

**NB**: Make sure that your strapi instance is working properly after that. If that works you should see that the ```tmp``` folder now contains 3 different files when Strapi performs read/write operations.

# Variable edits

First of all, edit the data in the following files so they relate to your context/environment:
- ```./terraform/terraform.tfvars```
- ```./strapi-aci/.env``` (set proper keys for ```APP_KEYS, API_TOKEN_SALT, ADMIN_JWT_SECRET``` and ```JWT_SECRET``` based on .env.example)
- ```./strapi-aci/build.prod.ps1```

# Docker image

Once this is done, and the prerequite above fulfilled, you can now build your docker image via the following PowerShell scripts:
- build.dev.ps1: for local development/testing
- build.prod.ps1: for storing in your container registry.

**NB**: The PowerShell scripts assume that you are using ACR as container registry, but this is easily adaptable to another provider.  

# Deployment

Once our image is built, you are now ready to deploy!

```powershell
cd ./terraform
az login # and select the appropriate subscription 
terraform init
terraform plan -out=serverlessstrapiv4
terraform apply serverlessstrapiv4
```

After a few minutes, if everything went well, you should now have a resource group created with the following resources:
- Container Instance
- App Service Plan
- Function App
- Storage Account

You can then connect to your Storage Account, and copy/paste your local SQLite file in the ```aci-strapi-db-prod``` file share (use Azure Storage Explorer, az cli or alternatively Azure ui).

That's it, you just deployed Strapi in a serverless way via ACI.

Before you can call your Azure Function to start up your ACI, there is one last thing you need to do:

- uncomment the following block in your ```main.tf```

``` terraform
# resource "azurerm_role_assignment" "role" {
#   scope                = "${data.azurerm_subscription.primary.id}/resourceGroups/${azurerm_resource_group.rg.name}"
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_function_app.fa.identity[0].principal_id
# }
```

This block has been commented out on purpose, because Terraform is not able presently to assign a role to an identity that does not exist. But now that we have run our script a first time, we can now uncomment that and rerun:

```
terraform plan -out=serverlessstrapiv4
terraform apply serverlessstrapiv4
```

Finally, last operation is to deploy our Azure Function code to the Function App located in ```./azure-function``` folder. You can do this with VS Code with the ```Azure Functions``` extension or via Azure Function Core Tools cli, that is up to you.

Once this is done, you can now call your Azure function to start up the ACI, and you should be redirected within a couple of minutes to your newly created Strapi instance. 

# Working locally

You have the possibility to test your Strapi installation in a few different ways:
- using ```yarn develop``` to start Strapi in the conventional way on your local host
- using ```npm run start-node``` to start ```index.js``` which in turn starts Strapi as well.
- using ```Docker``` and your latest image built with ```Dockerfile.dev```. See ```run.dev.ps1``` to start a container in your respective environment.  

**NB**: I did not create a Docker compose in this repo to reverse proxy our Strapi docker container.

# Going further

- Some efforts can be made to reduce the size of the Docker image, by removing unused libraries at post build (especially the ones related to the UI for example).
- In order to increase scalability: Modify the script so every request to the Azure Function creates and deploys a new Strapi instance via ACI. 
- At the moment, every request to the Azure function simply redirects to an existing ACI, and starts it if it is not already done.  
**NB**: If multiple ACI would be running, this would also imply the need of using an alternative database (MySQL or PostgreSQL or MariaDB). Currently SQLite set up would only support a single connection due to file lock.

# Issues / Suggestions

Please file issues or suggestions on the issues page on github, or even better, submit a pull request. Feedback is always welcome!

# References

Thanks to Johan Gyger for his very useful article on how to set up a **Caddy web server** reverse proxy with ACI via Terraform : https://itnext.io/automatic-https-with-azure-container-instances-aci-4c4c8b03e8c9  
Thanks to Simen Daehlin for his article regarding **Docker with Strapi V4**: https://blog.dehlin.dev/docker-with-strapi-v4

# License
Copyright © 2022-present Clément Joye

MIT
