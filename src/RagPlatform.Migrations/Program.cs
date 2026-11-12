using System.Security.Cryptography;
using Npgsql;

// Migrations are append-only SQL files, each executed in a separate transaction.
var connectionString = Environment.GetEnvironmentVariable("RAG_MIGRATIONS_DATABASE");
if (string.IsNullOrWhiteSpace(connectionString))
{
    Console.Error.WriteLine("Set RAG_MIGRATIONS_DATABASE to a dedicated migration connection.");
    return 1;
}

var directory = args.Length == 1 ? args[0] : "infra/postgres/migrations";
if (args.Length > 1 || !Directory.Exists(directory))
{
    Console.Error.WriteLine("Usage: RagPlatform.Migrations [migration-directory]");
    return 1;
}

var paths = Directory.GetFiles(directory, "*.sql").Order(StringComparer.Ordinal).ToArray();
if (paths.Length == 0)
{
    Console.Error.WriteLine("No SQL migrations found.");
    return 1;
}

try
{
    await using var db = new NpgsqlConnection(connectionString);
    await db.OpenAsync();
    // A session lock covers the entire run, including creation of the history table.
    await using (var lockCommand = new NpgsqlCommand("SELECT pg_advisory_lock(1380010033)", db))
        await lockCommand.ExecuteNonQueryAsync();
    try
    {
        await using (var setup = new NpgsqlCommand("""
            CREATE TABLE IF NOT EXISTS rag_schema_migrations (
                name text PRIMARY KEY,
                sha256 text NOT NULL,
                applied_at timestamptz NOT NULL DEFAULT now()
            )
            """, db))
            await setup.ExecuteNonQueryAsync();

        foreach (var path in paths)
        {
            var name = Path.GetFileName(path);
            var bytes = await File.ReadAllBytesAsync(path);
            var hash = Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();
            await using var tx = await db.BeginTransactionAsync();
            await using var check = new NpgsqlCommand("SELECT sha256 FROM rag_schema_migrations WHERE name = $1", db, tx);
            check.Parameters.AddWithValue(name);
            var existing = (string?)await check.ExecuteScalarAsync();
            if (existing is not null)
            {
                if (!StringComparer.Ordinal.Equals(existing, hash))
                    throw new InvalidOperationException($"Migration {name} differs from the applied checksum; restore it and add a new migration.");
                Console.WriteLine($"Already applied: {name}");
                await tx.CommitAsync();
                continue;
            }
            var sql = System.Text.Encoding.UTF8.GetString(bytes);
            await using (var execute = new NpgsqlCommand(sql, db, tx))
                await execute.ExecuteNonQueryAsync();
            await using (var record = new NpgsqlCommand("INSERT INTO rag_schema_migrations (name, sha256) VALUES ($1, $2)", db, tx))
            {
                record.Parameters.AddWithValue(name);
                record.Parameters.AddWithValue(hash);
                await record.ExecuteNonQueryAsync();
            }
            await tx.CommitAsync();
            Console.WriteLine($"Applied: {name}");
        }
    }
    finally
    {
        await using var unlock = new NpgsqlCommand("SELECT pg_advisory_unlock(1380010033)", db);
        await unlock.ExecuteNonQueryAsync();
    }
    return 0;
}
catch (Exception ex)
{
    // Avoid dumping connection strings or SQL contents into CI logs.
    Console.Error.WriteLine($"Migration failed ({ex.GetType().Name}). Check migration history and database configuration.");
    return 1;
}
