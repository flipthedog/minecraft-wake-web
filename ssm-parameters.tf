// Store the Minecraft EC2 instance ID in SSM Parameter Store for retrieval by lambda
resource "aws_ssm_parameter" "minecraft_instance_id" {
  name  = "/minecraft/instance_id"
  type  = "String"
  value = module.ec2_minecraft.id
}

resource "aws_ssm_parameter" "minecraft_ram" {
  name  = "/mc/ram"
  type  = "String"
  value = tostring(var.minecraft_ram)
}

resource "aws_ssm_parameter" "shutdown_timer" {
  name  = "/mc/shutdown_timer"
  type  = "String"
  value = tostring(var.shutdown_timer)
}