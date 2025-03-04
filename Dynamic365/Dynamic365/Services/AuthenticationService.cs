using Microsoft.Identity.Client;

namespace Dynamic365.Services
{
	public class AuthenticationService
	{
        private readonly IConfiguration _config;
        private IConfidentialClientApplication _clientApp;

        public AuthenticationService(IConfiguration config)
        {
            _config = config;
            // Build the ConfidentialClientApplication using client ID, client secret, and authority.
            _clientApp = ConfidentialClientApplicationBuilder.Create(_config["AzureAd:ClientId"])
                    .WithClientSecret(_config["AzureAd:ClientSecret"])
                    .WithAuthority(new Uri(_config["AzureAd:Authority"])) // This is your tenant authority
                    .Build();
        }

        public async Task<string> GetAccessTokenAsync()
        {
            try
            {
                // Define the scope - this should be the same scope you use for your API
                var scopes = new string[] { "https://api.businesscentral.dynamics.com/.default" };

                // Acquire token for the given scope (no need for a hardcoded token URL here)
                var result = await _clientApp.AcquireTokenForClient(scopes).ExecuteAsync();

                return result.AccessToken;
            }
            catch (MsalServiceException ex)
            {
                Console.WriteLine($"Error retrieving access token: {ex.Message}");
                Console.WriteLine($"Error Code: {ex.ErrorCode}");
                throw;
            }
        }
    }
}
