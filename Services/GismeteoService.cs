using System;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

namespace BSP_Weather.Services
{
    public class GismeteoService
    {
        private readonly string _gismeteoToken;

        public GismeteoService(IConfiguration configuration)
        {
            _gismeteoToken = configuration["Gismeteo:Token"] ?? throw new ArgumentNullException("Gismeteo:Token", "Gismeteo token is not configured.");
        }

        public async Task<string> GetAsyncHTTPS_GISMETEP(string url)
        {
            using var clientHandler = new HttpClientHandler
            {
                ServerCertificateCustomValidationCallback = (sender, cert, chain, sslPolicyErrors) => true
            };
            
            using var client = new HttpClient(clientHandler);
            client.DefaultRequestHeaders.Add("User-Agent", "C# App");
            client.DefaultRequestHeaders.Add("X-Gismeteo-Token", _gismeteoToken);

            HttpResponseMessage response = await client.GetAsync(url);
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadAsStringAsync();
        }
    }
}