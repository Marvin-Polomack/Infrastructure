resource "aws_s3_bucket" "kubeconfig_bucket" {
  bucket        = "kubeconfig-bucket-freelance"
  acl           = "private"  # Adjust permissions as needed (e.g., "private" for security)

  # Enable server-side encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # Enable versioning for data recovery
  versioning {
    enabled = true
  }

  # Add bucket policy to restrict access (optional)
  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion
  }

  tags = {
    Name        = "KubeconfigBucket"
    Environment = "Production"
  }
}