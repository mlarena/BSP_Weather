using Microsoft.OpenApi.Models;
using Serilog;
using Serilog.Events;
using BSP_Weather.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using System.IO;

Console.WriteLine("Starting application configuration...");

var builder = WebApplication.CreateBuilder(args);

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
});
builder.Services.AddSingleton<GismeteoService>();

// Configure HTTPS redirection (commented out for testing)
// builder.Services.AddHttpsRedirection(options =>
// {
//     options.HttpsPort = 5101;
// });

Console.WriteLine("Building application...");

var app = builder.Build();

Console.WriteLine("Configuring middleware pipeline...");

app.UseSwagger();
app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "BSP_Weather API v1"));

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
// app.UseHttpsRedirection(); // Disabled for testing
app.UseAuthorization();
app.MapControllers();

Console.WriteLine("Starting application...");
Log.Information("Application is starting...");

try
{
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application failed to start");
    throw;
}

Console.WriteLine("Application started.");