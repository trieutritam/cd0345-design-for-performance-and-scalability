# Define the output variable for the lambda function.
output "greet_lambda_output" {
  description = "The ARN of the Lambda Function"
  value = aws_lambda_function.greet_lambda_function.arn
}