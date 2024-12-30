# Text-to-Speech Application with AWS

## Overview
This project implements a serverless text-to-speech application using AWS services. It integrates Amazon Polly for text-to-speech functionality and is deployed using Terraform. The application serves an API endpoint via API Gateway, which is connected to a Lambda function that processes text input and returns synthesized speech.

## Architecture
The application utilizes the following AWS services:
- **Amazon API Gateway**: To expose a REST API endpoint.
- **AWS Lambda**: For backend processing and integration with Amazon Polly.
- **Amazon Polly**: To synthesize text into speech.
- **Amazon S3**: To host the static frontend that interacts with the API Gateway.

## Features
- REST API for text-to-speech conversion.
- Fully serverless and scalable.
- Static website hosted on S3 with API Gateway integration.
- CORS enabled for cross-origin access.

## Prerequisites
- AWS CLI configured with appropriate credentials.
- Terraform (v1.5 or later).
- Python (for Lambda function development).

## File Structure
```
project-directory
├── lambda
│   ├── TextToSpeechLambda.py
├── static
│   └── index.html
├── terraform
│   └── main.tf
│   └── variables.tf
│   └── outputs.tf
├── .gitignore
└── README.md
```

## Setup Instructions

### 1. Clone the Repository
```bash
git clone <repository-url>
cd project-directory
```

### 2. Update Terraform Variables
Define necessary variables in `variables.tf` or pass them directly via the command line.

### 3. Deploy the Infrastructure
Initialize and apply the Terraform configuration:
```bash
terraform init
terraform plan
terraform apply
```

### 4. Access the Application
Visit the S3 bucket's website URL or use the provided API Gateway endpoint to interact with the application.

## Troubleshooting
### Common Errors
1. **CORS Issues**: Ensure that the CORS settings in API Gateway are correctly configured in Terraform.
2. **Lambda Deployment Issues**: Confirm the Lambda ZIP file includes all dependencies and is properly uploaded.
3. **Terraform Errors**: Check for resource name conflicts or invalid configurations in the `.tf` files.

### Debugging Tips
- Use `terraform plan` to review changes before applying.
- Check the AWS Console for detailed logs in CloudWatch.

## Git Commands
### Add and Commit Changes
```bash
git add .
git status
git commit -m "Initial commit for text-to-speech application"
```

### Push to Repository
```bash
git push origin main
```
