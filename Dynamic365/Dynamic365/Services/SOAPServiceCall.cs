using Dynamic365.IServices;
using System.Net.Http.Headers;
using System.Text;

namespace Dynamic365.Services
{
    public class SOAPServiceCall : ISoapService
    {
        private readonly AuthenticationService _authenticationService;
        private readonly HttpClient _httpClient;
        private readonly string _tenantId;
        private readonly string _baseUrl;

        public SOAPServiceCall(AuthenticationService authenticationService, HttpClient httpClient, IConfiguration configuration)
        {
            _authenticationService = authenticationService;
            _httpClient = httpClient;
            _tenantId = configuration["BusinessCentral:TenantId"];
            _baseUrl = configuration["BusinessCentral:BaseUrl"];
        }

        public async Task<string> GetTableFieldsAsync(string tableName)
        {
            try
            {
                var accessToken = await _authenticationService.GetAccessTokenAsync();
                var soapUri = $"{_baseUrl}/v2.0/{_tenantId}/Sandbox/WS/CRONUS%20IN/Codeunit/GetTableData"; // Web Service URI 

                if (string.IsNullOrEmpty(accessToken))
                    throw new Exception("Access token is empty.");

                // SOAP request body
                string soapBody = $@"<?xml version=""1.0"" encoding=""utf-8""?>
    <soapenv:Envelope xmlns:soapenv=""http://schemas.xmlsoap.org/soap/envelope/""
                      xmlns:urn=""urn:microsoft-dynamics-schemas/codeunit/GetTableData"">
        <soapenv:Header/>
        <soapenv:Body>
            <urn:GetDataByTableName>
                <urn:tableName>{System.Security.SecurityElement.Escape(tableName)}</urn:tableName>
            </urn:GetDataByTableName>
        </soapenv:Body>
    </soapenv:Envelope>";

                Console.WriteLine("SOAP Request Body:\n" + soapBody);

                using (var request = new HttpRequestMessage(HttpMethod.Post, soapUri))
                {
                    request.Content = new StringContent(soapBody, Encoding.UTF8, "text/xml");

                    // Set headers
                    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                    request.Headers.Add("SOAPAction", "urn:microsoft-dynamics-schemas/codeunit/GetTableData:GetTableData");

                    Console.WriteLine("Headers:");
                    foreach (var header in request.Headers)
                    {
                        Console.WriteLine(header.Key + ": " + string.Join(",", header.Value));
                    }

                    using (var response = await _httpClient.SendAsync(request))
                    {
                        string responseContent = await response.Content.ReadAsStringAsync();
                        Console.WriteLine("Response: " + responseContent);

                        if (!response.IsSuccessStatusCode)
                        {
                            throw new Exception($"SOAP request failed: {response.StatusCode} - {responseContent}");
                        }

                        return responseContent;
                    }
                }
            }
            catch (HttpRequestException httpEx)
            {
                Console.WriteLine("HTTP Request Error: " + httpEx.Message);
                throw;
            }
            catch (Exception ex)
            {
                Console.WriteLine("General Error: " + ex.Message);
                throw;
            }
        }


    }
}