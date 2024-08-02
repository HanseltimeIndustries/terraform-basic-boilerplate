fmt-hcl:
	terragrunt hclfmt

fmt-hcl-check:
	terragrunt hclfmt --terragrunt-check

tflint:
	tflint --chdir ./terraform --recursive

tflint-fix:
	tflint --chdir ./terraform --recursive

fmt-tf:
	cd ./terraform && terraform fmt -recursive

fmt-tf-check:
	cd ./terraform && terraform fmt -recursive -check