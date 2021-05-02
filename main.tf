locals {
  webpage_root = "files/pages"
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "public-read"

  policy = templatefile(
    "${path.module}/files/bucket_policy.json.tmpl",
    { bucket_name = var.bucket_name }
  )

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_object" "pages" {
  for_each = fileset(path.module, "${local.webpage_root}/**")

  bucket = aws_s3_bucket.bucket.id
  key    = trimprefix(each.value, "${local.webpage_root}/")
  source = each.value
  etag   = filemd5(each.value)

  acl          = "public-read"
  content_type = "text/html"
}
