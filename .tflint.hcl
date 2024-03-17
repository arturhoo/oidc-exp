plugin "terraform" {
  enabled = true
  version = "0.6.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

plugin "google" {
  enabled = true
  version = "0.27.1"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}