# Terraforming Azure [![build-status](https://infra.ci.cf-app.com/api/v1/teams/main/pipelines/terraforming-azure/jobs/deploy-pas/badge)](https://infra.ci.cf-app.com/teams/main/pipelines/terraforming-azure)

## How Does One Use This?

This has been cloned from https://github.com/pivotal-cf/terraforming-azure with some added scripts to make things a little easier.

If you want the latest: 
> Please note that the master branch is generally *unstable*. If you are looking for something "tested", please consume one of our [releases](https://github.com/pivotal-cf/terraforming-azure/releases).

## What Does This Do?

Will go from zero to having a deployed ops-manager. You'll get networking, a storage account, and
a booted ops-manager VM.

## Looking to setup a different IAAS

We have other terraform templates to help you!

- [aws](https://github.com/pivotal-cf/terraforming-aws)
- [gcp](https://github.com/pivotal-cf/terraforming-gcp)

## Prerequisites

- [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
- [azure cli](https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/)
- [Docker](https://docs.docker.com/docker-for-mac/install/)

```bash
brew update
brew install az
brew install jq
```

## Creating A Service Principal

You need a [service principal account](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest#create-a-service-principal)
to deploy anything on top of Azure.

1. Login.
    ```bash
    $ az login
    $ az account show | jq -r '.id, .tenantId'
    the-subscription-id
    the-tenant-id
    ```

1. Create the service principal where the name is a valid URI.
    ```bash
    $ az ad sp create-for-rbac --name http://<service-principal-name> | jq -r '.appId, .password'
    the-app-id
    the-password
    ```

1. Export the credentials as environment variables
    ```hcl
    export ARM_SUBSCRIPTION_ID = "the-subscription-id"
    export ARM_TENANT_ID       = "the-tenant-id"
    export ARM_CLIENT_ID       = "the-app-id"
    export ARM_CLIENT_SECRET   = "the-password"
    ```

## Deploying Infrastructure

### Generate environment directory

Use the `./scripts/config-new-foundation.sh` script to generate a new environment directory.

```bash
$ ./scripts/config-new-foundation.sh <new-foundation-name>
```

A new directory named `new-foundation-name` will be created in your current directory. Certificates and a vars file will be created.



#### Var File

The *terraform.tfvars* default vars file will resemble what is shown below. These values will be used when terraform creates the environment.

If you want to change any of *env_name*, *ops_manager_image_uri*, *location*, *dns_suffix* or  *dns_subdomain* in terraform.tfvars, now is the time. There are defaults set that my not match your needs.

```hcl
subscription_id = "the-subscription-id"
tenant_id       = "the-tenant-id"
client_id       = "the-app-id"
client_secret   = "the-password"

env_name              = "banana"
ops_manager_image_uri = "url-to-opsman-image"
location              = "West US"
dns_suffix            = "domain.com"

# optional. if left blank, will default to the pattern `env_name.dns_suffix`.
dns_subdomain         = ""
```

#### Variables

- env_name: **(required)** An arbitrary unique name for namespacing resources
- subscription_id: **(required)** Azure account subscription id
- tenant_id: **(required)** Azure account tenant id
- client_id: **(required)** Azure automation account client id
- client_secret: **(required)** Azure automation account client secret
- ops_manager_image_uri: **(optional)** URL for an OpsMan image hosted on Azure (if not provided you get no Ops Manager)
- location: **(required)** Azure location to stand up environment in
- dns_suffix: **(required)** Domain to add environment subdomain to

### Optional

When deploying the isolation segments tile you can optionally route traffic through
a separate domain and load balancer by specifying:

- isolation_segment: **(default false)** Creates a DNS record and load balancer for
isolation segment network traffic when set to true.

## Running

Note: please make sure you have created/edited the `terraform.tfvars` file above as mentioned.

The next step should be run from within the environment directory created with `scripts/config-new-foundation.sh`

### Standing up environment

Run `scripts/tf-new-director.sh` from within the environment directory created with `scripts/config-new-foundation.sh`

```bash
cd <new-foundation-name>
../scripts/tf-new-director.sh
```

At the end you should see something like:

```bash
...
ssl_cert = <sensitive>
ssl_private_key = <sensitive>
subscription_id = <sensitive>
sys_domain = sys.csb-azure-pas5.envs.cfplatformeng.com
tcp_domain = tcp.csb-azure-pas5.envs.cfplatformeng.com
tcp_lb_name = csb-azure-pas5-tcp-lb
tenant_id = <sensitive>
web_lb_name = csb-azure-pas5-web-lb
Add these nameservers for environment
ns2-03.azure-dns.net.,
ns3-03.azure-dns.org.,
ns1-03.azure-dns.com.,
ns4-03.azure-dns.info.
```

#### DNS Records

You'll need to add those name servers to the DNS system hosting your domain name. 

### Configuring the Director

Use `scripts/configure-director` to finish configuration of the director

```bash
../scripts/configure-director <om-password>
```

*om-password* will be the admin password Ops Man.

### Tearing down environment

**Note:** This will only destroy resources deployed by Terraform. You will need to clean up anything deployed on top of that infrastructure yourself (e.g. by running `om delete-installation`)

```bash
terraform destroy
```

# Notes:

https://docs.pivotal.io/platform/ops-manager/2-8/azure/prepare-env-terraform.html