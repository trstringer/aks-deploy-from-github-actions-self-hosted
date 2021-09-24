# Deploy to AKS from GitHub Actions

## AKS Setup

Create the AKS cluster:

```
$ az group create \
    --location $LOCATION \
    --name $RG

$ az aks create \
    --resource-group $RG \
    --name $CLUSTER
```

Create the container registry (ACR):

```
$ az acr create \
    --resource-group $RG \
    --name $ACR \
    --sku basic
```

Attach the container registry to the AKS cluster:

```
$ az aks update \
    --resource-group $RG \
    --name $CLUSTER \
    --attach-acr $ACR
```

## GitHub Actions runner setup

Create the managed identity for the runner:

```
$ az identity create --resource-group $RG --name $IDENTITY
```

Create the VM that will serve as the runner:

```
$ az vm create \
    --resource-group $RG \
    --name $RUNNER \
    --image "canonical:0001-com-ubuntu-server-focal:20_04-lts:latest" \
    --size Standard_DS1_v2 \
    --ssh-key-values $SSH_PUB_KEY \
    --admin-username $ADMIN_USERNAME \
    --authentication-type ssh \
    --public-ip-address-dns-name $DNS_NAME \
    --assign-identity $(az identity show \
        --resource-group $RG \
        --name $IDENTITY \
        --query id -o tsv)
```

Grant the managed identity the necessary permissions on the container registry:

```
$ az role assignment create \
    --role AcrPush \
    --assignee-principal-type ServicePrincipal \
    --assignee-object-id $(az identity show \
        --resource-group $RG \
        --name $IDENTITY \
        --query principalId -o tsv) \
    --scope $(az acr show \
        --name $ACR \
        --query id -o tsv)
```

Grant the managed identity the necessary permissions on the AKS cluster:

```
$ az role assignment create \
    --role "Azure Kubernetes Service Cluster User Role" \
    --assignee-principal-type ServicePrincipal \
    --assignee-object-id $(az identity show \
        --resource-group $RG \
        --name $IDENTITY \
        --query principalId -o tsv) \
    --scope $(az aks show \
        --resource-group $RG \
        --name $CLUSTER \
        --query id -o tsv)

$ az role assignment create \
    --role "Azure Kubernetes Service RBAC Writer" \
    --assignee-principal-type ServicePrincipal \
    --assignee-object-id $(az identity show \
        --resource-group $RG \
        --name $IDENTITY \
        --query principalId -o tsv) \
    --scope "$(az aks show \
        --resource-group $RG \
        --name $CLUSTER \
        --query id -o tsv)/namespaces/default"
```

In the GitHub repository, navigate to **Settings** -> **Actions** -> **Runners**. Select **New self-hosted runner**.

SSH into the runner VM. I recommend creating a system user for the runner process:

```
$ sudo adduser githubrunner1 --system --group
$ sudo usermod -aG sudo githubrunner1
```

Ensure that the `sudo` group includes `NOPASSWD` so that the runner isn't prompted for a password when running `sudo` (you can modify `/etc/sudoers` with `visudo`).

Follow the intructions on the **Create self-managed runner** page in the GitHub repository (mkdir, curl, tar, etc.). Ensure that you're running these commands in the home dir of the new system user (`/home/githubrunner1`) under the proper security context: `sudo -u githubrunner1 <github_instructions_command>`.

Once you have run the `config.sh` script to configure the runner, you will then execute the `run.sh` script and this runner should now be listening for jobs on this repository.
