using Npgsql;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "rag-api" }));

// Deliberately unavailable outside Development. The principal is configured
// on the server for the whole process, never supplied by the HTTP caller.
if (app.Environment.IsDevelopment())
{
    app.MapGet("/dev/chunks", async (IConfiguration config, CancellationToken cancellationToken) =>
    {
        var principal = config["DevelopmentIdentity:PrincipalId"];
        var connectionString = config.GetConnectionString("RagPlatform");
        if (string.IsNullOrWhiteSpace(principal) || string.IsNullOrWhiteSpace(connectionString))
            return Results.Problem("Development identity and database connection must be configured.", statusCode: 503);

        var chunks = new List<ChunkEvidence>();
        await using var connection = new NpgsqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = new NpgsqlCommand(
            "SELECT chunk_id, document_id, version_id, section_id, title, content, source_uri, source_locator FROM authorized_chunks($1) ORDER BY chunk_id LIMIT 100", connection);
        command.Parameters.AddWithValue(principal);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
            chunks.Add(new(reader.GetGuid(0), reader.GetGuid(1), reader.GetGuid(2), reader.GetGuid(3),
                reader.GetString(4), reader.GetString(5), reader.GetString(6),
                reader.IsDBNull(7) ? null : reader.GetString(7)));
        return Results.Ok(chunks);
    });
}

app.Run();

public partial class Program { }

public record ChunkEvidence(Guid ChunkId, Guid DocumentId, Guid VersionId, Guid SectionId,
    string Title, string Content, string SourceUri, string? SourceLocator);
