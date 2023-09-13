module "random_pet" {
  source  = "gitlab.com/gitlab-org/random-pet/local"
  version = "0.0.1"
}

resource "local_file" "foo" {
  content  = "foo!"
  filename = "${path.module}/foo.bar"
}

variable "CI_PROJECT_NAME" {
  type    = string
  default = "default"
}

output "project_name" {
  value = var.CI_PROJECT_NAME
}
