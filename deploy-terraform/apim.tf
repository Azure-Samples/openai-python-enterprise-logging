resource "azurerm_api_management" "apim" {
  name                 = "apim-${local.name}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  publisher_name       = "openai-python-enterprise-logging"
  publisher_email      = "something@nothing.com"
  virtual_network_type = "External"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.api.id
  }
  policy = [
    {
      xml_content = <<-EOT
    <policies>
      <inbound>
        <cors allow-credentials="true">
          <allowed-origins>
            <origin>https://apim-${local.name}.developer.azure-api.net</origin>
          </allowed-origins>
          <allowed-methods preflight-result-max-age="300">
          	<method>*</method>
          </allowed-methods>
          <allowed-headers>
          	<header>*</header>
          </allowed-headers>
          <expose-headers>
          	<header>*</header>
          </expose-headers>
        </cors>
      </inbound>
      <backend>
        <forward-request />
      </backend>
      <outbound>
        <set-header name="X-OperationName" exists-action="override">
            <value>@( context.Operation.Name )</value>
        </set-header>
        <set-header name="X-OperationMethod" exists-action="override">
            <value>@( context.Operation.Method )</value>
        </set-header>
        <set-header name="X-OperationUrl" exists-action="override">
            <value>@( context.Operation.UrlTemplate )</value>
        </set-header>
        <set-header name="X-ApiName" exists-action="override">
            <value>@( context.Api.Name )</value>
        </set-header>
        <set-header name="X-ApiPath" exists-action="override">
            <value>@( context.Api.Path )</value>
        </set-header>
      </outbound>
      <on-error>
        <set-header name="X-OperationName" exists-action="override">
            <value>@( context.Operation.Name )</value>
        </set-header>
        <set-header name="X-OperationMethod" exists-action="override">
            <value>@( context.Operation.Method )</value>
        </set-header>
        <set-header name="X-OperationUrl" exists-action="override">
            <value>@( context.Operation.UrlTemplate )</value>
        </set-header>
        <set-header name="X-ApiName" exists-action="override">
            <value>@( context.Api.Name )</value>
        </set-header>
        <set-header name="X-ApiPath" exists-action="override">
            <value>@( context.Api.Path )</value>
        </set-header>
        <set-header name="X-LastErrorMessage" exists-action="override">
            <value>@( context.LastError.Message )</value>
        </set-header>
      </on-error>
    </policies>
EOT
      xml_link    = null
    },
  ]
  zones    = []
  sku_name = "Developer_1"
  tags     = local.tags
}

resource "azurerm_api_management_api" "this" {
  name                = "openai-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "OpenAI API"
  path                = "openai"
  protocols           = ["https"]

  import {
    content_format = "openapi+json-link"
    content_value  = "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2023-05-15/inference.json"
  }

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }
}

resource "azurerm_api_management_backend" "this" {
  name                = "${local.name}-backend"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  protocol            = "http"
  url                 = "${azurerm_cognitive_account.this.endpoint}/openai"
  credentials {
    header = {
      api-key = azurerm_cognitive_account.this.primary_access_key
    }
  }
}

resource "azurerm_api_management_api_policy" "this" {
  api_name            = azurerm_api_management_api.this.name
  api_management_name = azurerm_api_management_api.this.api_management_name
  resource_group_name = azurerm_api_management_api.this.resource_group_name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <log-to-eventhub logger-id="ehlogger" partition-id="0">@{
            var body = context.Request.Body?.As<string>(true);
            if (body != null && body.Length > 1024)
            {
                body = body.Substring(0, 1024);
            }

            var headers = context.Request.Headers
                                .Where(h => h.Key != "Authorization" && h.Key != "Ocp-Apim-Subscription-Key" && h.Key != "api-key")
                                .Select(h => string.Format("{0}: {1}", h.Key, String.Join(", ", h.Value)))
                                .ToArray<string>();
            var requestIdHeader = context.Request.Headers.GetValueOrDefault("Request-Id", "");
            return new JObject(
                new JProperty("Type", "request"),
                new JProperty("Headers", headers),
                new JProperty("EventTime", DateTime.UtcNow.ToString()),
                new JProperty("ServiceName", context.Deployment.ServiceName),
                new JProperty("requestIdHeader", requestIdHeader),
                new JProperty("RequestId", context.RequestId),
                new JProperty("RequestIp", context.Request.IpAddress),
                new JProperty("RequestMethod", context.Request.Method),
                new JProperty("RequestPath", context.Request.Url.Path),
                new JProperty("RequestQuery", context.Request.Url.QueryString),
                new JProperty("RequestBody", body),
                new JProperty("OperationName", context.Operation.Name),
                new JProperty("OperationMethod", context.Operation.Method),
                new JProperty("OperationUrl", context.Operation.UrlTemplate),
                new JProperty("ApiName", context.Api.Name),
                new JProperty("ApiPath", context.Api.Path)
                
            ).ToString();
            
        }</log-to-eventhub>
        <set-backend-service backend-id="${azurerm_api_management_backend.this.name}" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <log-to-eventhub logger-id="ehlogger" partition-id="1">@{
            var body = context.Response.Body?.As<string>(true);
            if (body != null && body.Length > 1024)
            {
                body = body.Substring(0, 1024);
            }

            var headers = context.Response.Headers
                                            .Select(h => string.Format("{0}: {1}", h.Key, String.Join(", ", h.Value)))
                                            .ToArray<string>();

            var requestIdHeader = context.Request.Headers.GetValueOrDefault("Request-Id", "");
            var requestBody = context.Request.Body?.As<string>(true);
            return new JObject(
                new JProperty("Type", "response"),
                new JProperty("Headers", headers),
                new JProperty("EventTime", DateTime.UtcNow.ToString()),
                new JProperty("ServiceName", context.Deployment.ServiceName),
                new JProperty("requestIdHeader", requestIdHeader),
                new JProperty("RequestId", context.RequestId),
                new JProperty("RequestIp", context.Request.IpAddress),
                new JProperty("RequestMethod", context.Request.Method),
                new JProperty("ResponseStatusCode", context.Response.StatusCode),
                new JProperty("ResponseStatusReason", context.Response.StatusReason),
                new JProperty("ResponseBody", body),
                new JProperty("OperationName", context.Operation.Name),
                new JProperty("OperationMethod", context.Operation.Method),
                new JProperty("OperationUrl", context.Operation.UrlTemplate),
                new JProperty("ApiName", context.Api.Name),
                new JProperty("ApiPath", context.Api.Path),
                new JProperty("RequestBody", requestBody),
                new JProperty("Duration", context.Elapsed)
                
            ).ToString();
            
        }</log-to-eventhub>
    </outbound>
    <on-error>
        <base />
        <log-to-eventhub logger-id="ehlogger" partition-id="1">@{
            var requestIdHeader = context.Request.Headers.GetValueOrDefault("Request-Id", "");
            return new JObject(
                new JProperty("Type", "error"),
                new JProperty("EventTime", DateTime.UtcNow.ToString()),
                new JProperty("ServiceName", context.Deployment.ServiceName),
                new JProperty("requestIdHeader", requestIdHeader),
                new JProperty("RequestId", context.RequestId),
                new JProperty("RequestIp", context.Request.IpAddress),
                new JProperty("LastErrorMessage", context.LastError.Message),
                new JProperty("OperationName", context.Operation.Name),
                new JProperty("OperationMethod", context.Operation.Method),
                new JProperty("OperationUrl", context.Operation.UrlTemplate),
                new JProperty("ApiName", context.Api.Name),
                new JProperty("ApiPath", context.Api.Path),
                new JProperty("Duration", context.Elapsed)
            ).ToString();
        }</log-to-eventhub>
    </on-error>
</policies>
XML
}

resource "azurerm_api_management_logger" "this" {
  name                = "ehlogger"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  

  eventhub {
    name              = azurerm_eventhub.this.name
    connection_string = azurerm_eventhub_namespace.this.default_primary_connection_string
  }
}