# MiniNetflix (Terraform + AWS Demo)

This project is a Mini Netflix clone built with Terraform on AWS.  
It uses Amazon S3 + CloudFront + an HTML5 player to stream video content globally.  

It’s a hands-on demo of how Infrastructure as Code (IaC) can be used to deploy real, working applications.

---

## Features
- Terraform-managed AWS stack:
  - S3 bucket for storing media files
  - CloudFront distribution for global CDN streaming
  - Public video player generated from a template
- HTML5 Video Player:
  - Auto-generated with Terraform template
  - Ready to play MP4 video hosted on S3
- Infrastructure as Code workflow:
  - Simple, reproducible deployment
  - Easy teardown with one command

---

## Project Structure
- `main.tf` → Creates S3 bucket + CloudFront distribution  
- `variables.tf` → Defines input variables (e.g., bucket name, region)  
- `outputs.tf` → Prints CloudFront streaming URL  
- `provider.tf` → AWS provider configuration  
- `versions.tf` → Required Terraform + provider versions  
- `templates/index.html.tftpl` → HTML5 video player template  

---

## Prerequisites
- Terraform installed (v1.5+ recommended)  
- AWS CLI installed and configured (`aws configure`)  
- IAM user with S3 + CloudFront permissions  
- A test MP4 video file to upload  

---

## How to Deploy

1. Initialize Terraform:
   ```bash
   terraform init
