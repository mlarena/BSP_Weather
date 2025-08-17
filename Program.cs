using Microsoft.OpenApi.Models;
using Serilog;
using Serilog.Events;
using BSP_Weather.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using System.IO;

var builder = WebApplication.CreateBuilder(args);

// Log configuration loading
Console.WriteLine("Starting application configuration...");
var configFilePath = Path.Combine(Directory.GetCurrentDirectory(), "appsettings.json");
Console.WriteLine($"Checking for appsettings.json at: {configFilePath}");
Console.WriteLine($"appsettings.json exists: {File.Exists(configFilePath)}");

Console.WriteLine("Configuring Serilog...");

// Ensure logs directory exists
var logDirectory = Path.Combine(Directory.GetCurrentDirectory(), "logs");
Console.WriteLine($"Ensuring log directory exists at: {logDirectory}");
Directory.CreateDirectory(logDirectory);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Debug()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .WriteTo.Console()
    .WriteTo.File(
        path: Path.Combine(logDirectory, "weather-api-{Date}.txt"),
        rollingInterval: RollingInterval.Day,
        outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .CreateLogger();

builder.Host.UseSerilog();

// Log Gismeteo token
var gismeteoToken = builder.Configuration["Gismeteo:Token"];
Log.Information($"Gismeteo Token: {(string.IsNullOrEmpty(gismeteoToken) ? "Not found" : "Found")}");

Console.WriteLine("Adding services...");

// Add CORS policy
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyHeader()
               .AllowAnyMethod();
    });
});

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "BSP_Weather API", Version = "v1" });
    Log.Information("SwaggerGen configured for v1");
});
builder.Services.AddSingleton<GismeteoService>();

Console.WriteLine("Building application...");

var app = builder.Build();

Console.WriteLine("Configuring middleware pipeline...");

// Configure Swagger
app.UseSwagger(c =>
{
    c.RouteTemplate = "swagger/{documentName}/swagger.json";
    Log.Information("Swagger middleware configured with RouteTemplate: {RouteTemplate}", c.RouteTemplate);
});
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "BSP_Weather API v1");
    c.RoutePrefix = "swagger";
    Log.Information("Swagger UI configured with RoutePrefix: {RoutePrefix}", c.RoutePrefix);
});

app.Use(async (context, next) =>
{
    Log.Information("Incoming request: {Method} {Path} from {RemoteIp}, Headers: {Headers}",
        context.Request.Method,
        context.Request.Path,
        context.Connection.RemoteIpAddress?.ToString(),
        string.Join("; ", context.Request.Headers.Select(h => $"{h.Key}: {h.Value}")));
    await next(context);
    Log.Information("Response for {Path}: Status Code: {StatusCode}",
        context.Request.Path,
        context.Response.StatusCode);
});

app.UseCors("AllowAll");
app.UseAuthorization();
app.MapControllers();

Log.Information("Application is starting...");
Console.WriteLine("Starting application...");

try
{
    Log.Information("Test log entry to verify file logging");
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application failed to start");
    throw;
}

Console.WriteLine("Application started.");