.PHONY: test fmt validate

test:
	terraform test

fmt:
	terraform fmt -recursive

validate:
	terraform init -backend=false && terraform validate
