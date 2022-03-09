# Designate a cloud provider, region, and credentials
provider "aws" {
    shared_credentials_files = ["$HOME/.aws/credentials"]
}

# IAM Role for lambda
## Policy
resource "aws_iam_role_policy" "greet_lambda_policy" {
  name        = "greet_lambda_policy"
  role        = "${aws_iam_role.greet_lambda_role.id}"

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
})
}

resource "aws_iam_policy" "greet_lambda_logging_policy" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      }
    ]
  })
}

# Role
resource "aws_iam_role" "greet_lambda_role" {
  name = "greet_lambda_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "greet_log_group" {
  name              = "/aws/lambda/greet_lambda_function"
  retention_in_days = 7
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.greet_lambda_role.name
  policy_arn = aws_iam_policy.greet_lambda_logging_policy.arn
}

# VPC
resource "aws_vpc" "udacity_vpc" {
  cidr_block = "10.5.0.0/16"
  tags = {
    Name = "Udacity-VPC"
  }
}

resource "aws_subnet" "udacity_subnet" {
  vpc_id     = aws_vpc.udacity_vpc.id
  cidr_block = "10.5.1.0/24"

  tags = {
    Name = "Udacity-Subnet"
  }
}

resource "aws_security_group" "udacity_security_group" {
  name        = "udacity_security_group"
  vpc_id      = aws_vpc.udacity_vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Udacity-Security-Group"
  }
}


# Deploy lambda
data "archive_file" "greet_lambda" {
  type = "zip"
  source_file = "${path.module}/greet_lambda.py"
  output_path = "${path.module}/source.zip"
}

resource "aws_lambda_function" "greet_lambda_function" {
  function_name = "greet_lambda_function"
  role          = aws_iam_role.greet_lambda_role.arn
  handler       = "greet_lambda.lambda_handler"
  runtime       = "python3.8"

  vpc_config {
    subnet_ids         = [aws_subnet.udacity_subnet.id]
    security_group_ids = [aws_security_group.udacity_security_group.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.greet_log_group,
  ]

  filename      = "source.zip"
  source_code_hash = data.archive_file.greet_lambda.output_base64sha256

  environment {
    variables = {
      greeting = "Hello Udacity"
    }
  }
}