variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket to host static files"
  default     = "text-to-speech-static-site"
}
