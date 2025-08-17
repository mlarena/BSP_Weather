# Step-by-Step Guide to Create BSP_Weather ASP.NET Core Web API

## Step 1: Create a new ASP.NET Core Web API project
Run the following command in your terminal or command prompt to create a new Web API project:
```bash
dotnet new webapi -n BSP_Weather
cd BSP_Weather
```

## Step 2: Add required NuGet packages
Add necessary packages for Swagger and logging:
```bash
dotnet add package Swashbuckle.AspNetCore
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.File
```

## Step 3: Create a service for Gismeteo API calls
Create a new file `GismeteoService.cs` in a `Services` folder with the following content:

<xaiArtifact artifact_id="4828104e-f66f-4d0c-95a9-1356802317c9" artifact_version_id="e574ef45-218e-49ff-a626-89111ada0538" title="GismeteoService.cs" contentType="text/csharp">

using System.Net.Http;
using System.Threading.Tasks;

namespace BSP_Weather.Services
{
    public class GismeteoService
    {
        public static async Task<string> GetAsyncHTTPS_GISMETEP(string url)
        {
            HttpClientHandler clientHandler = new HttpClientHandler();
            clientHandler.ServerCertificateCustomValidationCallback = (sender, cert, chain, sslPolicyErrors) => { return true; };
            HttpClient client = new HttpClient(clientHandler);
            client.DefaultRequestHeaders.Add("User-Agent", "C# App");
            client.DefaultRequestHeaders.Add("X-Gismeteo-Token", "3ui234u2io34ui23u423u4u23u454654");

            HttpResponseMessage response = await client.GetAsync(url);
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadAsStringAsync();
        }
    }
}