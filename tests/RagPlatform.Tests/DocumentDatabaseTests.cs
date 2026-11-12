using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Npgsql;
using Xunit;

public class DocumentDatabaseTests
{
    [Fact]
    public async Task Development_endpoint_enforces_grants_and_observes_revocation()
    {
        var connectionString = Environment.GetEnvironmentVariable("RAG_TEST_DATABASE");
        if (string.IsNullOrWhiteSpace(connectionString)) return;

        var document = Guid.NewGuid();
        var version = Guid.NewGuid();
        var section = Guid.NewGuid();
        var chunk = Guid.NewGuid();
        var principal = "test-" + Guid.NewGuid();
        await using var db = new NpgsqlConnection(connectionString);
        await db.OpenAsync();
        try
        {
            await using (var seed = new NpgsqlCommand("""
                INSERT INTO documents(id, source_key, source_uri, domain, classification, owner_id)
                VALUES (@d, @source, 'synthetic://test', 'test', 'internal', 'owner');
                INSERT INTO document_versions(id, document_id, version_number, title, content_hash, status)
                VALUES (@v, @d, 1, 'Test', 'hash', 'approved');
                INSERT INTO sections(id, version_id, title, ordinal) VALUES (@s, @v, 'Section', 0);
                INSERT INTO chunks(id, version_id, section_id, ordinal, content, content_hash)
                VALUES (@c, @v, @s, 0, 'synthetic evidence', 'hash');
                INSERT INTO document_read_grants(document_id, principal_id) VALUES (@d, @p);
                """, db))
            {
                seed.Parameters.AddWithValue("d", document);
                seed.Parameters.AddWithValue("v", version);
                seed.Parameters.AddWithValue("s", section);
                seed.Parameters.AddWithValue("c", chunk);
                seed.Parameters.AddWithValue("p", principal);
                seed.Parameters.AddWithValue("source", "test/" + document);
                await seed.ExecuteNonQueryAsync();
            }
            await using var app = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
            {
                builder.UseEnvironment("Development");
                builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(
                    new Dictionary<string, string?> {
                        ["DevelopmentIdentity:PrincipalId"] = principal,
                        ["ConnectionStrings:RagPlatform"] = connectionString
                    }));
            });
            using var client = app.CreateClient();
            var before = await client.GetFromJsonAsync<List<ChunkEvidence>>("/dev/chunks");
            Assert.Contains(before!, item => item.ChunkId == chunk);
            await using (var revoke = new NpgsqlCommand(
                "DELETE FROM document_read_grants WHERE document_id = @d AND principal_id = @p", db))
            {
                revoke.Parameters.AddWithValue("d", document);
                revoke.Parameters.AddWithValue("p", principal);
                await revoke.ExecuteNonQueryAsync();
            }
            var after = await client.GetFromJsonAsync<List<ChunkEvidence>>("/dev/chunks");
            Assert.DoesNotContain(after!, item => item.ChunkId == chunk);
        }
        finally
        {
            await using var cleanup = new NpgsqlCommand("DELETE FROM documents WHERE id = @d", db);
            cleanup.Parameters.AddWithValue("d", document);
            await cleanup.ExecuteNonQueryAsync();
        }
    }
}
