# Designate a cloud provider, region, and credentials
provider "aws" {
    shared_credentials_files = ["$HOME/.aws/credentials"]
}

# Provision 4 AWS t2.micro EC2 instances named Udacity T2

resource "aws_instance" "Udacity-T2" {
  count = "4"
  ami = "ami-0e1d30f2c40c4c701"
  instance_type = "t2.micro"
  subnet_id = "subnet-0d009035378d1a08a"
  tags = {
    Name = "Udacity T2"
  }
}


# provision 2 m4.large EC2 instances named Udacity M4
resource "aws_instance" "Udacity-M4" {
  count = "2"
  ami = "ami-0e1d30f2c40c4c701"
  instance_type = "m4.large"
  subnet_id = "subnet-0d009035378d1a08a"
  tags = {
    Name = "Udacity M4"
  }
}
