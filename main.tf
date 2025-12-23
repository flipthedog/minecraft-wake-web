terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"    
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-2" 
}

variable "bucket_name" {
  description = "Name of the S3 bucket for the Minecraft wake website"
  type        = string
}

variable "minecraft_instance_id" {
  description = "EC2 instance ID of the Minecraft server"
  type        = string
}