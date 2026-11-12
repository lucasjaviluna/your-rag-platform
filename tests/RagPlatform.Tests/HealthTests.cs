using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

public class HealthTests
{
    [Fact]
    public async Task Health_endpoint_reports_service_status()
    {
        await using var app = new WebApplicationFactory<Program>();
        using var client = app.CreateClient();
        using var response = await client.GetAsync("/health");
        response.EnsureSuccessStatusCode();
        Assert.Contains("rag-api", await response.Content.ReadAsStringAsync());
    }
}
