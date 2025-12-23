resource "aws_ssm_parameter" "minecraft_instance_id" {
  name  = "/minecraft/instance_id"
  type  = "String"
  value = var.minecraft_instance_id
}