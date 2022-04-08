locals {
  webpage_root = "files/pages"
  index_content = templatefile(
    "files/index.html.tmpl",
    { timestamp = formatdate("EEEE, DD-MMM-YY hh:mm:ss ZZZ", timestamp()) }
  )
}

resource "aws_route53_zone" "zone" {
  name = var.bucket_name
}

#
# PAGES
#

resource "aws_s3_bucket" "domain" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_acl" "domain" {
  bucket = aws_s3_bucket.domain.bucket
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "domain" {
  bucket = aws_s3_bucket.domain.bucket
  policy = templatefile(
    "${path.module}/files/bucket_policy.json.tmpl",
    { bucket_name = var.bucket_name }
  )
}

resource "aws_s3_bucket_website_configuration" "domain" {
  bucket = aws_s3_bucket.domain.bucket

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "index" {
  bucket  = aws_s3_bucket.domain.id
  key     = "index.html"
  content = local.index_content
  etag    = md5(local.index_content)

  acl          = "public-read"
  content_type = "text/html"
}

resource "aws_s3_object" "pages" {
  for_each = fileset(path.module, "${local.webpage_root}/**")

  bucket = aws_s3_bucket.domain.id
  key    = trimprefix(each.value, "${local.webpage_root}/")
  source = each.value
  etag   = filemd5(each.value)

  acl          = "public-read"
  content_type = "text/html"
}

resource "aws_route53_record" "domain" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = aws_route53_zone.zone.name
  type    = "A"

  alias {
    name                   = aws_s3_bucket.domain.website_domain
    zone_id                = aws_s3_bucket.domain.hosted_zone_id
    evaluate_target_health = false
  }
}

#
# REDIRECTS
#

resource "aws_s3_bucket" "redirects" {
  for_each = var.website_redirects

  bucket        = "${each.key}.${aws_route53_zone.zone.name}"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_acl" "redirects" {
  for_each = aws_s3_bucket.redirects

  bucket = each.value.bucket
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "redirects" {
  for_each = aws_s3_bucket.redirects

  bucket = each.value.bucket
  policy = templatefile(
    "${path.module}/files/bucket_policy.json.tmpl",
    { bucket_name = "${each.key}.${aws_route53_zone.zone.name}" }
  )
}

resource "aws_s3_bucket_website_configuration" "redirects" {
  for_each = aws_s3_bucket.redirects

  bucket = each.value.bucket

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "redirects" {
  for_each = var.website_redirects

  bucket           = aws_s3_bucket.redirects[each.key].id
  key              = "index.html"
  website_redirect = each.value

  acl          = "public-read"
  content_type = "text/html"
}

resource "aws_route53_record" "redirects" {
  for_each = aws_s3_bucket.redirects

  zone_id = aws_route53_zone.zone.zone_id
  name    = each.value.bucket
  type    = "A"

  alias {
    name                   = each.value.website_domain
    zone_id                = each.value.hosted_zone_id
    evaluate_target_health = false
  }
}
