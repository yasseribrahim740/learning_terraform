# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
variable "cidr_blocks" {
    description = "cidr blocks of subnets and vpcs for dev env"
    type = list(object({
        cidr_block = string
        name = string
    }))
}

# Create a VPC
resource "aws_vpc" "dev-vpc" {
  cidr_block = var.cidr_blocks[0].cidr_block
  tags = {
    Name = var.cidr_blocks[0].name
  }
}

resource "aws_subnet" "dev-sub-1" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = var.cidr_blocks[1].cidr_block 
  availability_zone = "us-east-1b"
  tags = {
    Name = var.cidr_blocks[1].name
  }
}

