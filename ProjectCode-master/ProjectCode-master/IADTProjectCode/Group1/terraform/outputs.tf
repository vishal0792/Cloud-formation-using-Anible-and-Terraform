output "news_website_address" {
  value       = "http://${aws_instance.latest_news_website.public_dns}"
  description = "Website URL"
}
