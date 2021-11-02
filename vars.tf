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

variable "website_redirects" {
  type = map(string)
  default = {
    "e3"  = "https://docs.google.com/document/d/1DsCoHkMcziwMQpYFRkZ3eG-Lw4AqzdpiYlM1GP2EW1o"
    "faq" = "https://www.google.com"
  }
}
