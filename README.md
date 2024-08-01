# Replicated Embedded Cluster AMI Generator

This project automates the creation of Amazon Machine Images (AMIs) for
Replicated Embedded Cluster applications. It simplifies the process of
packaging and distributing Replicated applications through AWS, enabling
seamless deployment of air-gapped installations. 

The main purpose of this project is to product AMIs you can use to submit your
product to the AWS Marketplace. I use the resulting AMIs in my [Replicated
Cluster CloudFormation
Demo](https://github.com/crdant/replicated-cluster-cloudformation), which I
developed to submit [Slackernews](https://slackernews.io) to the AWS
Marketplace as an AMI with CloudFormation Stack product. 

## Overview

The AMI generator uses Packer to build customized AMIs that include:

- A specific Replicated application and channel
- The Embedded Cluster components
- Cloud-init configuration for initial setup

This allows customers to easily launch instances with your Replicated
application pre-installed and ready to run in an air-gapped environment.

## Usage

### Prerequisites

1. AWS account with appropriate permissions
2. Replicated vendor account and API token
3. Application configured in the Replicated vendor portal
4. `make`, `packer`, `jq`, `sops`, `yq`, and AWS CLI tools installed locally

### Preparing Parameters

1. Copy `secrets/REDACTED-params.yaml` to `secrets/params.yaml`
2. Update `params.yaml` with your AWS and Replicated credentials:

```yaml
aws:
  access_key_id: YOUR_AWS_ACCESS_KEY
  secret_access_key: YOUR_AWS_SECRET_KEY
  regions: 
    - us-east-1
    - us-west-2

replicated:
  api_token: YOUR_REPLICATED_API_TOKEN

instance_type: t3.large
volume_size: 100
source_ami: ami-12345678
```

3. Encrypt the params file:

```
make encrypt
```

### Generating an AMI

The Makefile dynamically generates targets based on your Replicated Vendor
Portal applications and channels. To build an AMI for a specific application
and channel:

```
make ami:APP_SLUG/CHANNEL_SLUG
```

For example:

```
make ami:my-app/stable
```

To see all available targets:

```
make -qp | grep -E '^ami:'
```

This will list all the dynamically generated `ami:APP_SLUG/CHANNEL_SLUG`
targets based on your current Replicated Vendor Portal configuration.

## Components

- **Makefile**: Orchestrates the entire process, dynamically generating
  targets based on your Replicated applications and channels
- **Packer**: Defines the AMI configuration and build process
- **Cloud-init**: Configures the instance on first boot, including Replicated
  application setup
- **Replicated Vendor Portal**: Provides application metadata and release
  artifacts
- **AWS**: Hosts the resulting AMI and allows for multi-region distribution

## How It Works

1. The Makefile queries the Replicated Vendor Portal to get all applications
   and channels
2. It dynamically generates make targets for each application/channel
   combination
3. When a target is invoked, it generates a Packer variables file with the
   necessary configuration
4. Packer uses this configuration to launch an EC2 instance and customize it
5. Cloud-init scripts run on first boot to set up the Replicated application
6. Packer creates an AMI from the configured instance
7. The AMI is shared to specified AWS regions and accounts

## Key Makefile Features

- **Dynamic Target Generation**: Automatically creates targets for all your
  Replicated applications and channels
- **Parameter Management**: Handles the creation and encryption of parameter
  files
- **Packer Integration**: Prepares variables for and executes Packer builds

## Resulting AMI

The generated AMI is specifically tailored for running your Replicated
application in an air-gapped environment. Key features of the AMI include:

- **Base OS**: Ubuntu 22.04 LTS
- **Pre-installed Components**:
  - Replicated Embedded Cluster
  - Your specific application (based on the chosen channel)
  - All necessary dependencies
- **Configuration**:
  - Cloud-init scripts for first-boot setup
  - Customized user data for Replicated application initialization
  - SSH hardening (custom sshd_config)
- **Default User**: A user named after your application slug
- **Volume**: Customized volume size (as specified in params.yaml)
- **Security**:
  - Root login disabled
  - SSH password authentication disabled
- **Multi-region**: The AMI is replicated to all specified AWS regions

This AMI allows your customers to quickly deploy your application in an
air-gapped environment with minimal additional configuration required. It's
designed to be secure, efficient, and ready for production use.

## Disclaimer

This project is provided as an example and is not officially supported by
Replicated. Use at your own risk and adapt as needed for your specific
requirements.
