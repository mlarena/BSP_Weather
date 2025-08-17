using Microsoft.OpenApi.Models;
using Serilog;
using Serilog.Events;
using BSP_Weather.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

Console.WriteLine("Starting application configuration...");

var builder = WebApplication.CreateBuilder(args);

Console.WriteLine("Configuring Serilog...");

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Debug()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .WriteTo.Console()
    .WriteTo.File(
        path: "logs/weather-api-{Date}.txt",
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
builder.Services.AddHttpsRedirection(options =>
{
    options.HttpsPort = 5101;
});

Console.WriteLine("Building application...");

var app = builder.Build();

Console.WriteLine("Configuring middleware pipeline...");

// Configure the HTTP request pipeline
//if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "BSP_Weather API v1"));
}

// Логирование всех входящих запросов
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
//app.UseHttpsRedirection(); // Отключено для тестирования
app.UseAuthorization();
app.MapControllers();

Console.WriteLine("Starting application...");
Log.Information("Application is starting...");

app.Run();

Console.WriteLine("Application started.");