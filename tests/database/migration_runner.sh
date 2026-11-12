#!/usr/bin/env bash
set -euo pipefail

# Runs against the disposable CI database after the regular migration.
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT
cp infra/postgres/migrations/001_document_model.sql "$test_dir/001_document_model.sql"

# A changed historical file must be rejected before anything else runs.
printf '\n-- checksum change\n' >> "$test_dir/001_document_model.sql"
if dotnet run --project src/RagPlatform.Migrations -- "$test_dir"; then
  echo 'Changed migration unexpectedly accepted' >&2
  exit 1
fi
cp infra/postgres/migrations/001_document_model.sql "$test_dir/001_document_model.sql"
cp tests/database/migration_failure.sql.fixture "$test_dir/002_failure.sql"
if dotnet run --project src/RagPlatform.Migrations -- "$test_dir"; then
  echo 'Failing migration unexpectedly accepted' >&2
  exit 1
fi
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U rag_local -d rag_platform <<'SQL'
DO $$ BEGIN
  IF to_regclass('public.migration_test_rollback') IS NOT NULL THEN
    RAISE EXCEPTION 'Failed migration was not rolled back';
  END IF;
  IF EXISTS (SELECT 1 FROM rag_schema_migrations WHERE name = '002_failure.sql') THEN
    RAISE EXCEPTION 'Failed migration was recorded';
  END IF;
END $$;
SQL

# Two simultaneous runners must serialize and apply the second file only once.
cp tests/database/migration_concurrency.sql.fixture "$test_dir/002_concurrent.sql"
rm -- "$test_dir/002_failure.sql"
dotnet run --project src/RagPlatform.Migrations -- "$test_dir" &
first=$!
dotnet run --project src/RagPlatform.Migrations -- "$test_dir" &
second=$!
wait "$first"
wait "$second"
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U rag_local -d rag_platform <<'SQL'
DO $$ BEGIN
  IF (SELECT count(*) FROM migration_test_concurrency) <> 1 THEN
    RAISE EXCEPTION 'Concurrent migration applied more than once';
  END IF;
END $$;
DROP TABLE migration_test_concurrency;
DELETE FROM rag_schema_migrations WHERE name = '002_concurrent.sql';
SQL
