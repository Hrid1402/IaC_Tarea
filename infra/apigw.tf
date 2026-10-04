resource "aws_apigatewayv2_api" "http_api" {
    name          = "image-processor-api"
    protocol_type = "HTTP"
    cors_configuration {
        allow_origins = ["*"]
        max_age       = 300
        allow_methods = ["POST", "OPTIONS"]
        allow_headers = ["content-type", "authorization"]
    }
}

resource "aws_apigatewayv2_stage" "http_api" {
    api_id = aws_apigatewayv2_api.http_api.id
    name   = "$default"
    auto_deploy = true
    default_route_settings {
        throttling_burst_limit = 10000
        throttling_rate_limit  = 10000
    }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
    api_id           = aws_apigatewayv2_api.http_api.id
    integration_type = "AWS_PROXY"
    integration_method = "POST"
    integration_uri    = aws_lambda_function.upload_lambda.invoke_arn
    payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "upload_route" {
    api_id    = aws_apigatewayv2_api.http_api.id
    route_key = "POST /upload"
    target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gw" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.upload_lambda.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

#Verificar con el output de terraform apply que la URL del API Gateway es correcta y accesible
output "api_url" {
    description = "URL base de la API Gateway HTTP API"
    value       = aws_apigatewayv2_api.http_api.api_endpoint
}