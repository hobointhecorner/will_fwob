variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "bucket_name" {
  type    = string
  default = "willfwob.co"
}

variable "force_destroy" {
  type    = bool
  default = false
}
