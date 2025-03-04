using Dynamic365.IServices;
using System.Net.Http.Headers;
using System.Text;

namespace Dynamic365.Services
{
    public class GetAllTables : IGetAllTablesServices
    {
        private readonly AuthenticationService _authenticationService;
        private readonly HttpClient _httpClient;
        private readonly string _tenantId;
        private readonly string _baseUrl;

        public GetAllTables(AuthenticationService authenticationService, HttpClient httpClient, IConfiguration configuration)
        {
            _authenticationService = authenticationService;
            _httpClient = httpClient;
            _tenantId = configuration["BusinessCentral:TenantId"];
            _baseUrl = configuration["BusinessCentral:BaseUrl"];
        }

        public async Task<string> GetTables()
        {
            try
            {
                var accessToken = await _authenticationService.GetAccessTokenAsync();
                var soapUri = $"{_baseUrl}/v2.0/{_tenantId}/Sandbox/WS/CRONUS%20IN/Codeunit/FetchRecords";

                if (string.IsNullOrEmpty(accessToken))
                    throw new Exception("Access token is empty.");

                // SOAP request body
                string soapBody = $@"<soapenv:Envelope xmlns:soapenv=""http://schemas.xmlsoap.org/soap/envelope/""
                                          xmlns:urn=""urn:microsoft-dynamics-schemas/codeunit/FetchRecords"">
                                          <soapenv:Header/>
                                             <soapenv:Body>
                                                <urn:FetchDatabaseRecords/>
                                             </soapenv:Body>
                                     </soapenv:Envelope>";

                Console.WriteLine("SOAP Request Body:\n" + soapBody);

                using (var request = new HttpRequestMessage(HttpMethod.Post, soapUri))
                {
                    request.Content = new StringContent(soapBody, Encoding.UTF8, "text/xml");

                    // Set headers
                    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                    request.Headers.Add("SOAPAction", "urn:microsoft-dynamics-schemas/codeunit/FetchDatabaseRecords:FetchDatabaseRecords");

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
            catch (Exception)
            {

                throw;
            }
        }
    }
}
