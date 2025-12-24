variable "name" {
    description = "Name prefix for resources"
    type        = string
    default     = "minecraft-terraform"
}

variable "public_bucket_name" {
  description = "Name of the S3 bucket for the Minecraft wake website"
  type        = string
}

variable "minecraft_instance_id" {
  description = "EC2 instance ID of the Minecraft server"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type of the Minecraft server"
  type        = string
  default     = "t3.small"
}

variable "mc_port" {
  description = "Port number for the Minecraft server"
  type        = number
  default     = 25565
}

variable "allowed_cidrs" {
  description = "List of CIDR blocks allowed to access the Minecraft server"
  type        = list(string)
  default     = [""] // Replace with actual CIDR blocks to allow connection with SSH to the server
}

variable "mc_root_dir" {
  description = "Root directory for Minecraft server files"
  type        = string
  default     = "/opt/minecraft/server"
}

variable "tags" {
  description = "Any extra tags to assign to objects"
  type        = map
  default     = {}
}

variable "backup_bucket_object_versioning" {
  description = "Enable object versioning in backup bucket (default = true). Note this may incur more cost."
  type        = bool
  default     = true
}

variable "backup_bucket_name" {
  description = "Name of the S3 bucket for backing up Minecraft server data"
  type        = string
  default     = "minecraft-backup-bucket"
}

variable "vpc_id" {
  description = "VPC for security group"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "VPC subnet id to place the instance"
  type        = string
  default     = ""
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = true
}

variable "shutdown_timer" {
  description = "Shutdown timer in seconds, do not lower below 300"
  type        = number
  default     = 1000
}

variable "minecraft_ram" {
  description = "Amount of RAM (in MB) allocated to the Minecraft server, do not configure higher than your instance type allows"
  type        = number
  default     = 1300
}