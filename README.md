# VPCs Hands-On with Terraform

This repository contains a Terraform configuration to set up two VPCs (`VPC-A` and `VPC-B`), each with its own subnets and EC2 instances, connected via a VPC peering connection. This setup is designed to demonstrate creating and managing AWS infrastructure using Terraform.

## Prerequisites

Before you begin, ensure you have the following:

1.  **Terraform**: Install Terraform via Homebrew.

    - You can install it by running: `brew install terraform`.

2.  **AWS Access Keys**: Set up your AWS Access Key ID and Secret Access Key.

    - These credentials are needed to authenticate Terraform with your AWS account.

3.  **AWS CLI**: Install the AWS CLI and configure it with your AWS Access Key ID and Secret Access Key.

    - This is necessary for managing AWS resources from the command line.

## Steps to Deploy

1.  **Clone the Repository**:

    `git clone https://github.com/askarnku/vpcs_handson_terraform.git`

2.  **Change Directory**:

    `cd vpcs_handson_terraform`

3.  **Initialize Terraform**:

    `terraform init`

    This will download and install the necessary provider plugins.

4.  **Plan the Infrastructure**:

    `terraform plan`

    This step will show you the infrastructure changes that will be made.

5.  **Apply the Configuration**:

    `terraform apply`

    Confirm the action when prompted. This will create the infrastructure as defined in the Terraform configuration.

## Post-Deployment

Once the infrastructure is up, you can SSH into the EC2 instances to verify that everything is working as expected.

- **SSH into EC2 Instances**: Use the SSH key you specified during the configuration to connect to your instances.

  `ssh -i /path/to/your-key.pem ec2-user@<ec2_instance_public_or_private_ip> -A`

  (`-A` option forwards or chains private key from instance to instance)

## Cleanup

After verifying the setup, you can destroy the infrastructure to avoid incurring charges:

`terraform destroy`

This command will remove all the resources that were created.
