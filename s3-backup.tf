// provision an S3 bucket for backing up Minecraft server data

resource "aws_s3_bucket" "mc_backup_bucket" {
  bucket = var.backup_bucket_name
}

resource "aws_s3_bucket_versioning" "mc_backup_bucket_versioning" {
  bucket = aws_s3_bucket.mc_backup_bucket.id
  versioning_configuration {
    status = var.backup_bucket_object_versioning ? "Enabled" : "Suspended"
  }
}
