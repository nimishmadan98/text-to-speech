output "api_url" {
  value = aws_api_gateway_deployment.rest_api_deployment.invoke_url
}

# Output the website URL
output "website_url" {
  value = "http://${aws_s3_bucket.static_site.website_endpoint}"
  description = "The URL of the index.html file hosted on S3"
}

output "rendered_index_html" {
  value = data.template_file.dynamic_index.rendered
}