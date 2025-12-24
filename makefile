.PHONY: init terraform localstack zip shutdown clean invoke

LS_API_GW_URL = http://localhost:4566/restapis
GATEWAY_ID_OUTPUT_NAME := api_gateway_id

localstack:
	@docker-compose up -d

build:
	@echo "Building Go Lambda function..."
	@cd src/lambda && CGO_ENABLED=0 GOARCH=amd64 GOOS=linux go build -o bootstrap main.go
	@echo "Creating zip file..."
	@cd src/lambda && zip ../../terraform/bootstrap.zip bootstrap
	@cd src/lambda && rm bootstrap
	@echo "Lambda zip file created at terraform/bootstrap.zip"

terraform:
	@tflocal -chdir=terraform init
	@tflocal -chdir=terraform apply --auto-approve

init: localstack build terraform
	@echo "Initialisation complete"
	@echo "Run 'make invoke' to trigger lambda"

invoke:
	@API_ID=$$(tflocal -chdir=terraform output -raw $(GATEWAY_ID_OUTPUT_NAME)) && \
	curl -X POST $(LS_API_GW_URL)/$$API_ID/v1/_user_request_/test

clean:
	@rm -rf terraform/.terraform
	@rm -rf terraform/builds
	@rm -f terraform/.terraform.lock.hcl
	@rm -f terraform/bootstrap.zip
	@rm -f terraform/terraform.tfstate
	@rm -f terraform/terraform.tfstate.backup
	@echo "Cleaned build artifacts"

shutdown: clean
	@echo "Shutting down localstack..."
	@docker-compose down
