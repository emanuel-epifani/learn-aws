.PHONY: build clean install deploy plan dev

# Install Lambda dependencies
install:
	cd lambda && npm install

# Build Lambda functions
build:
	cd lambda && npm run build

# Clean build artifacts
clean:
	rm -rf lambda/dist lambda/node_modules

# Terraform plan
plan:
	cd terraform && terraform plan

# Terraform apply
deploy:
	cd terraform && terraform apply

# Development workflow: install, build, plan
dev: install build plan

# Production workflow: install, build, deploy
prod: install build deploy