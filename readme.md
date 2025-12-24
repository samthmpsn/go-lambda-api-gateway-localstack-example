# Go Lambda API Gateway with LocalStack

A simple demonstration project that triggers an AWS Lambda function written in Go via API Gateway proxy integration, using LocalStack for local development and testing.

## Overview

This project demonstrates:
- **Go Lambda Function**: A simple AWS Lambda handler that responds to API Gateway requests
- **API Gateway Integration**: AWS API Gateway configured with proxy integration to invoke the Lambda
- **LocalStack**: Complete local AWS environment for development and testing
- **Infrastructure as Code**: Terraform configuration for deploying all AWS resources
- **Automated Build**: Makefile with commands to build, deploy, and test the entire stack

## Architecture

```
API Gateway (REST API)
    └── /{proxy+} endpoint
        └── POST method
            └── AWS_PROXY integration
                └── Lambda Function (Go)
                    └── Returns "Hello from Lambda!"
```

## Prerequisites

- [Docker](https://www.docker.com/) and Docker Compose
- [Go](https://golang.org/) (1.x or later)
- [Terraform](https://www.terraform.io/)
- [tflocal](https://github.com/localstack/terraform-local) - Terraform wrapper for LocalStack
- [awslocal](https://github.com/localstack/awscli-local) - AWS CLI wrapper for LocalStack (optional)
- LocalStack Pro license (configured in `.env` file)

## Project Structure

```
.
├── src/
│   └── lambda/
│       ├── main.go           # Lambda function handler
│       ├── go.mod
│       └── go.sum
├── terraform/
│   ├── main.tf              # Main Terraform configuration
│   ├── api_gateway.tf       # API Gateway and Lambda resources
│   └── bootstrap.zip        # Built Lambda deployment package (generated)
├── docker-compose.yml       # LocalStack container configuration
├── makefile                 # Build and deployment automation
└── readme.md
```

## Quick Start

### 1. Set up LocalStack Pro

Create a `.env` file in the project root with your LocalStack Pro API key:

```
LOCALSTACK_API_KEY=your-api-key-here
```

### 2. Initialize and Deploy

Run the complete initialization process:

```bash
make init
```

This will:
1. Start LocalStack in a Docker container
2. Build the Go Lambda function and create a deployment package
3. Deploy the infrastructure using Terraform

### 3. Test the API

Invoke the API Gateway endpoint to trigger your Lambda:

```bash
make invoke
```

You should receive a response:
```
Hello from Lambda!
```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make init` | Complete setup: starts LocalStack, builds Lambda, deploys infrastructure |
| `make localstack` | Start LocalStack container |
| `make build` | Build Go Lambda function and create deployment zip |
| `make terraform` | Deploy infrastructure with Terraform |
| `make invoke` | Test the API Gateway endpoint |
| `make clean` | Remove build artifacts and Terraform state |
| `make shutdown` | Clean up and stop LocalStack container |

## Manual Testing

If you prefer to test manually, you can use curl directly:

```bash
# Get your API Gateway ID
API_ID=$(tflocal -chdir=terraform output -raw api_gateway_id)

# Invoke the endpoint
curl -X POST http://localhost:4566/restapis/$API_ID/v1/_user_request_/test
```

Or test with a payload:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello"}' \
  http://localhost:4566/restapis/$API_ID/v1/_user_request_/anything
```

## Lambda Function

The Lambda function (`src/lambda/main.go`) is a simple handler that:
- Accepts API Gateway proxy requests
- Returns a 200 status code
- Responds with "Hello from Lambda!"

```go
func handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
    response := events.APIGatewayProxyResponse{
        StatusCode: 200,
        Headers: map[string]string{
            "Content-Type": "text/plain",
        },
        Body: "Hello from Lambda!",
    }
    return response, nil
}
```

## Infrastructure

The Terraform configuration deploys:
- **API Gateway REST API** with a catch-all `{proxy+}` resource
- **Lambda Function** using Go custom runtime (`provided.al2`)
- **API Gateway Integration** configured for AWS_PROXY
- **Lambda Permissions** allowing API Gateway to invoke the function
- **API Gateway Stage** (v1) for accessing the API

## Development

### Modifying the Lambda

1. Edit `src/lambda/main.go`
2. Rebuild and redeploy:
   ```bash
   make build
   make terraform
   ```

### Viewing Terraform Outputs

```bash
tflocal -chdir=terraform output
```

### Debugging

Enable verbose output in the makefile by removing the `@` prefix from commands, or use curl with `-v` flag:

```bash
curl -v -X POST http://localhost:4566/restapis/$API_ID/v1/_user_request_/test
```

## Troubleshooting

### LocalStack not starting
- Check Docker is running
- Verify `.env` file contains valid `LOCALSTACK_API_KEY`
- Check logs: `docker-compose logs -f`

### Lambda not responding
- Verify the Lambda was deployed: `awslocal lambda list-functions`
- Check Lambda logs in LocalStack
- Ensure API Gateway has permission to invoke Lambda

### API Gateway returns 404
- Verify the API Gateway ID: `tflocal -chdir=terraform output api_gateway_id`
- Check the stage name is correct (v1)
- Use the `_user_request_` path segment for LocalStack

## Clean Up

Stop LocalStack and remove all artifacts:

```bash
make shutdown
```

This will:
- Clean all build artifacts
- Remove Terraform state
- Stop and remove the LocalStack container

## License

MIT

## References

- [Github user - wimspaargaren. This repo is a further simplification of his brilliant work (linked).](https://github.com/wimspaargaren/go-lambda-localstack-example)
- [AWS Lambda Go](https://github.com/aws/aws-lambda-go)
- [LocalStack Documentation](https://docs.localstack.cloud/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [API Gateway Proxy Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html)
