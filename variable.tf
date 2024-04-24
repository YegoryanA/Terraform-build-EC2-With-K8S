variable "access_key" {
  description = "Access key to AWS console"
  default     = "********************"
}

variable "secret_key" {
  description = "Secret key to AWS console"
  default     = "*************************"
}

variable "ami_key_pair_name" {
  description = "SSH Key"
  default     = "NVirginia_Key_Pair"
}
variable "number_of_worker" {
  description = "number of worker instances to be join on cluster."
  default     = 1
}

variable "region" {
  description = "The region zone on AWS"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance types"
  default     = "t2.medium"
}

variable "image_tag_mutability" {
  description = "mutability type"
  default     = "MUTABLE"
}
