resource "aws_api_gateway_rest_api" "api" {
  name        = "${local.environment}-go-lambda-api"
  description = "API Gateway for Go Lambda"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "v1" {
  depends_on = [
    aws_api_gateway_integration.lambda
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.v1.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "v1"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "bootstrap.zip"
  function_name = "go-lambda-api-gateway"
  role          = "arn:aws:iam::12345678910:role/some-role-name"
  handler       = "bootstrap" # binary must be named 'bootstrap' as per AWS lambda requirements
  architectures = ["x86_64"]
  runtime       = "provided.al2" # go requires an os-only runtime (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html)
  timeout       = 30
}
