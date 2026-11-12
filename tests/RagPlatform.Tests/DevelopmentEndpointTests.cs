using System.Net;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Xunit;

public class DevelopmentEndpointTests
{
    [Fact]
    public async Task Production_does_not_expose_development_endpoint()
    {
        await using var app = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder => builder.UseEnvironment("Production"));
        using var response = await app.CreateClient().GetAsync("/dev/chunks");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Development_endpoint_requires_server_identity_and_connection()
    {
        await using var app = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.UseEnvironment("Development");
                builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(
                    new Dictionary<string, string?> {
                        ["DevelopmentIdentity:PrincipalId"] = "",
                        ["ConnectionStrings:RagPlatform"] = ""
                    }));
            });
        var request = new HttpRequestMessage(HttpMethod.Get, "/dev/chunks");
        request.Headers.Add("X-Principal-Id", "alice");
        using var response = await app.CreateClient().SendAsync(request);
        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
    }
}
