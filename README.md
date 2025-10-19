# MiniNetflix (Terraform + AWS Demo)

A small “Netflix-style” demo that originally ran on **AWS (S3 + CloudFront)** via Terraform, with an **HTML5 video player**.  
For portfolio purposes, a working player is hosted on **GitHub Pages** so it’s viewable without AWS costs.

**Live Demo (GitHub Pages):** https://tawanmaurice.github.io/mininetflix-pages/

---

## What this shows
- Infrastructure as Code (Terraform) to provision AWS:
  - S3 bucket (static site + media)
  - CloudFront distribution (global CDN)
  - IAM policies and OAC where applicable
- HTML5 video player page generated from a Terraform template
- Cost-free demo hosting on GitHub Pages (secondary video) for portfolios

---

## Project Structure
- `main.tf` — S3 bucket(s), CloudFront distribution, policies
- `variables.tf` — input variables (region, names)
- `outputs.tf` — outputs (CloudFront URL, S3 website URL)
- `provider.tf` — AWS provider config
- `versions.tf` — Terraform + provider version pins
- `templates/index.html.tftpl` — HTML5 player template used by Terraform

---

## Current Status
- The AWS stack shown in this repo was **destroyed** (as intended during testing).
- The demo remains available here: **https://tawanmaurice.github.io/mininetflix-pages/**
- Redeploying to AWS is one command away with Terraform (see below).

---

## Redeploy on AWS (optional)
Prereqs: Terraform v1.5+, AWS CLI configured (`aws configure`), an MP4 video file.

```bash
terraform init
terraform plan
terraform apply -auto-approve
terraform output -raw cloudfront_url
