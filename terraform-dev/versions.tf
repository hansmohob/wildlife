terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.10.0"
    }
  }

  backend "s3" {  
    bucket       = "aws102-ws-s3bucketwildlife-gzhxd8py4ork"
    key          = "terraform/statefile-dev.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}