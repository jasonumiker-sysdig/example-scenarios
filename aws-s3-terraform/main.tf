terraform {
  backend "s3" {
    bucket = "jumiker-terraform"
    key    = "lwihkiak"
    region = "ap-southeast-2"
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_s3_bucket" "lwihkiak" {
  bucket = "lwihkiak"
}

resource "aws_s3_bucket_ownership_controls" "lwihkiak" {
  bucket = aws_s3_bucket.lwihkiak.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "lwihkiak" {
  bucket = aws_s3_bucket.lwihkiak.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "lwihkiak" {
  depends_on = [
    aws_s3_bucket_ownership_controls.lwihkiak,
    aws_s3_bucket_public_access_block.lwihkiak,
  ]

  bucket = aws_s3_bucket.lwihkiak.id
  acl    = "public-read"
  } resource "aws_s3_bucket_public_access_block" "lwihkiak" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.lwihkiak.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}
