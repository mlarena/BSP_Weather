
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;
using BSP_Weather.Services;
using System.Globalization;

namespace BSP_Weather.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class WeatherController : ControllerBase
    {
        private readonly ILogger<WeatherController> _logger;
        private readonly GismeteoService _gismeteoService;
        private readonly string _baseUrl = "https://api.gismeteo.net/v3/weather";

        public WeatherController(ILogger<WeatherController> logger, GismeteoService gismeteoService)
        {
            _logger = logger;
            _gismeteoService = gismeteoService;
            _logger.LogInformation("WeatherController initialized");
        }

        [HttpGet("bsp_abcd")]
        public async Task<IActionResult> GetCurrentWeather(double latitude = 55.7558, double longitude = 37.6173)
        {
            _logger.LogInformation("Received request for GetCurrentWeather with latitude: {Latitude}, longitude: {Longitude}", latitude, longitude);
            string url = $"{_baseUrl}/current/?latitude={latitude.ToString(CultureInfo.InvariantCulture)}&longitude={longitude.ToString(CultureInfo.InvariantCulture)}";
            return await ProxyRequest(url, latitude, longitude);
        }

        // [HttpGet("bsp_abcd/test")]
        // public async Task<IActionResult> GetCurrentWeatherTest()
        // {
        //     _logger.LogInformation("Received request for GetCurrentWeatherTest with test coordinates");
        //     string url = $"{_baseUrl}/current/?latitude=55.7558&longitude=37.6173";
        //     return await ProxyRequest(url, 55.7558, 37.6173);
        // }

        [HttpGet("bsp_efgh")]
        public async Task<IActionResult> GetForecastH1(double latitude = 55.7558, double longitude = 37.6173)
        {
            _logger.LogInformation("Received request for GetForecastH1 with latitude: {Latitude}, longitude: {Longitude}", latitude, longitude);
            string url = $"{_baseUrl}/forecast/h1/?latitude={latitude.ToString(CultureInfo.InvariantCulture)}&longitude={longitude.ToString(CultureInfo.InvariantCulture)}";
            return await ProxyRequest(url, latitude, longitude);
        }

        // [HttpGet("bsp_efgh/test")]
        // public async Task<IActionResult> GetForecastH1Test()
        // {
        //     _logger.LogInformation("Received request for GetForecastH1Test with test coordinates");
        //     string url = $"{_baseUrl}/forecast/h1/?latitude=55.7558&longitude=37.6173";
        //     return await ProxyRequest(url, 55.7558, 37.6173);
        // }

        [HttpGet("bsp_ijkl")]
        public async Task<IActionResult> GetForecastH3(double latitude = 55.7558, double longitude = 37.6173)
        {
            _logger.LogInformation("Received request for GetForecastH3 with latitude: {Latitude}, longitude: {Longitude}", latitude, longitude);
            string url = $"{_baseUrl}/forecast/h3/?latitude={latitude.ToString(CultureInfo.InvariantCulture)}&longitude={longitude.ToString(CultureInfo.InvariantCulture)}";
            return await ProxyRequest(url, latitude, longitude);
        }

        // [HttpGet("bsp_ijkl/test")]
        // public async Task<IActionResult> GetForecastH3Test()
        // {
        //     _logger.LogInformation("Received request for GetForecastH3Test with test coordinates");
        //     string url = $"{_baseUrl}/forecast/h3/?latitude=55.7558&longitude=37.6173";
        //     return await ProxyRequest(url, 55.7558, 37.6173);
        // }

        [HttpGet("bsp_mnop")]
        public async Task<IActionResult> GetForecastH6(double latitude = 55.7558, double longitude = 37.6173)
        {
            _logger.LogInformation("Received request for GetForecastH6 with latitude: {Latitude}, longitude: {Longitude}", latitude, longitude);
            string url = $"{_baseUrl}/forecast/h6/?latitude={latitude.ToString(CultureInfo.InvariantCulture)}&longitude={longitude.ToString(CultureInfo.InvariantCulture)}";
            return await ProxyRequest(url, latitude, longitude);
        }

        // [HttpGet("bsp_mnop/test")]
        // public async Task<IActionResult> GetForecastH6Test()
        // {
        //     _logger.LogInformation("Received request for GetForecastH6Test with test coordinates");
        //     string url = $"{_baseUrl}/forecast/h6/?latitude=55.7558&longitude=37.6173";
        //     return await ProxyRequest(url, 55.7558, 37.6173);
        // }

        [HttpGet("bsp_qrst")]
        public async Task<IActionResult> GetForecastH24(double latitude = 55.7558, double longitude = 37.6173)
        {
            _logger.LogInformation("Received request for GetForecastH24 with latitude: {Latitude}, longitude: {Longitude}", latitude, longitude);
            string url = $"{_baseUrl}/forecast/h24/?latitude={latitude.ToString(CultureInfo.InvariantCulture)}&longitude={longitude.ToString(CultureInfo.InvariantCulture)}";
            return await ProxyRequest(url, latitude, longitude);
        }

        // [HttpGet("bsp_qrst/test")]
        // public async Task<IActionResult> GetForecastH24Test()
        // {
        //     _logger.LogInformation("Received request for GetForecastH24Test with test coordinates");
        //     string url = $"{_baseUrl}/forecast/h24/?latitude=55.7558&longitude=37.6173";
        //     return await ProxyRequest(url, 55.7558, 37.6173);
        // }

        private async Task<IActionResult> ProxyRequest(string url, double latitude, double longitude)
        {
            var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
            var requestTime = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss");
            var requestDetails = $"URL: {url}, Client IP: {clientIp}, Latitude: {latitude.ToString(CultureInfo.InvariantCulture)}, Longitude: {longitude.ToString(CultureInfo.InvariantCulture)}";

            _logger.LogInformation($"Request received at {requestTime}. Details: {requestDetails}");
            _logger.LogDebug("Sending request to Gismeteo API: {Url}", url);

            // Валидация координат
            if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180)
            {
                _logger.LogWarning($"Invalid coordinates received. Latitude: {latitude.ToString(CultureInfo.InvariantCulture)}, Longitude: {longitude.ToString(CultureInfo.InvariantCulture)}");
                return BadRequest("Latitude must be between -90 and 90, and longitude must be between -180 and 180.");
            }

            try
            {
                string content = await _gismeteoService.GetAsyncHTTPS_GISMETEP(url);
                _logger.LogInformation($"Successful response from {url}. Response length: {content.Length} characters");
                return Ok(content);
            }
            catch (HttpRequestException ex)
            {
                _logger.LogWarning($"Failed request to {url}. Status: {ex.StatusCode}, Message: {ex.Message}, StackTrace: {ex.StackTrace}");
                return StatusCode((int)(ex.StatusCode ?? System.Net.HttpStatusCode.InternalServerError), ex.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error processing request to {url}: {ex.Message}, StackTrace: {ex.StackTrace}");
                return StatusCode(500, "Internal server error");
            }
        }
    }
}