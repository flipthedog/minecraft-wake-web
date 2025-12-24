output "minecraft_eip" {
    value       = aws_eip.mc_eip.public_ip
    description = "Elastic IP address of the Minecraft EC2 instance"
}

output "instance_id" {
    value       = module.ec2_minecraft.id
    description = "ID of the Minecraft EC2 instance"
}

# Output the API URL
output "api_url" {
    value       = "https://${aws_api_gateway_rest_api.minecraft_api.id}.execute-api.${data.aws_region.current.id}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/start"
    description = "API Gateway endpoint URL"
}

output "api_key" {
    value       = aws_api_gateway_api_key.minecraft_key.value
    description = "API Gateway key for accessing the Minecraft start endpoint"
    sensitive   = true
}