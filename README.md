# minecraft-wake-web

This Terraform project is intended to create infrastructure for a cost-optimized Minecraft Java server on AWS EC2 that can be started via a public API Gateway endpoint and using AWS Systems Manager (SSM) to manage the EC2 instance.

A monitoring script is run on the EC2 launch to automatically stop the server after a period of inactivity to save costs.

## References

The following two AWS blog posts are used as direct references for creating the AWS EC2 minecraft server and using SSM to start and stop the server:

1. https://aws.amazon.com/blogs/gametech/setting-up-a-minecraft-java-server-on-amazon-ec2/
2. https://aws.amazon.com/blogs/gametech/cost-optimize-your-minecraft-java-ec2-server/
3. https://github.com/darrelldavis/terraform-aws-minecraft/

## Services

The following services are used in this project:
1. AWS EC2 - To host the Minecraft server.
    - This is configured for gravitron (ARM) architecture to reduce costs.
2. AWS Systems Manager (SSM) - To manage the EC2 instance and run commands to start/stop the server.
3. AWS API Gateway - To create a public API endpoint to trigger the start/stop commands.
4. AWS IAM - To create roles and policies for SSM and API Gateway access.
5. AWS S3 - To host a simple static website for the API documentation.
6. AWS CloudWatch - To log API Gateway requests and Lambda function logs.
7. AWS Lambda - To handle the EC2 start

## Warning
** Running AWS infrastructure may incur costs. Please ensure you understand the costs associated with the services used in this project before deploying. **

The default instances and settings are chosen to minimize costs, but are not free tier. 

## Instructions

1. Install Terraform and configure AWS CLI with appropriate credentials.
    - You can download Terraform from the [official website](https://developer.hashicorp.com/terraform/downloads)
    - Configure AWS CLI by running `aws configure` and providing your access key, secret key, region, and output format.
2. Clone this repository to your local machine.
3. Navigate to the project directory.
4. Review and modify the `variables.tf` file to set your desired configurations (e.g., instance type, bucket names, allowed CIDR ranges). Create a file called `terraform.tfvars` to override default variable values if needed.
5. Run `terraform init` to  initialize the Terraform project.
6. Run `terraform plan` to see the execution plan and verify the resources that will be created.
7. Run `terraform apply` to create the infrastructure. Type `yes` when prompted to confirm.
8. Wait for the resources to be provisioned, this can take a few minutes. You should then be able to connect to your minecraft server using the public IP of the EC2 instance (found in the AWS Management Console or output by Terraform).
9. Remember that the provisioned resources will incur costs over time.

## Inaccurate Architecture Diagram

Here is a terrible  and inaccurate architecture diagram created by Generative AI:

![Architecture Diagram](readme/image.png)