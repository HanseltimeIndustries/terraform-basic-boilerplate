tflint {
  required_version = ">= 0.52"
}

config {
  format     = "compact"
  plugin_dir = "./.tflint.d/plugins"

  call_module_type    = "local"
  force               = false
  disabled_by_default = false

  ignore_module = {}

  varfile   = []
  variables = []
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
