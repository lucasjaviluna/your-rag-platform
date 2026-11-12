-- Apply as a transaction. Bootstrap is intended for a fresh local database.
BEGIN;

CREATE TABLE documents (
    id uuid PRIMARY KEY,
    source_key text NOT NULL UNIQUE,
    source_uri text NOT NULL,
    domain text NOT NULL,
    classification text NOT NULL,
    owner_id text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE document_versions (
    id uuid PRIMARY KEY,
    document_id uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    version_number integer NOT NULL CHECK (version_number > 0),
    title text NOT NULL,
    content_hash text NOT NULL,
    status text NOT NULL CHECK (status IN ('draft', 'approved', 'superseded', 'archived')),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (document_id, version_number),
    UNIQUE (id, document_id)
);

CREATE TABLE sections (
    id uuid PRIMARY KEY,
    version_id uuid NOT NULL REFERENCES document_versions(id) ON DELETE CASCADE,
    parent_id uuid,
    title text NOT NULL,
    ordinal integer NOT NULL CHECK (ordinal >= 0),
    source_locator text,
    UNIQUE (id, version_id),
    FOREIGN KEY (parent_id, version_id) REFERENCES sections(id, version_id),
    CHECK (parent_id IS NULL OR parent_id <> id)
);

CREATE TABLE chunks (
    id uuid PRIMARY KEY,
    version_id uuid NOT NULL REFERENCES document_versions(id) ON DELETE CASCADE,
    section_id uuid NOT NULL,
    ordinal integer NOT NULL CHECK (ordinal >= 0),
    content text NOT NULL,
    content_hash text NOT NULL,
    source_locator text,
    FOREIGN KEY (section_id, version_id) REFERENCES sections(id, version_id),
    UNIQUE (section_id, ordinal)
);

-- Local pilot: explicit grants to individual principals. Deny by default.
-- Group membership and source ACL synchronization are future work.
CREATE TABLE document_read_grants (
    document_id uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    principal_id text NOT NULL CHECK (length(trim(principal_id)) > 0),
    PRIMARY KEY (document_id, principal_id)
);

CREATE INDEX chunks_version_idx ON chunks(version_id);
CREATE INDEX versions_document_idx ON document_versions(document_id);
CREATE INDEX document_read_grants_principal_idx ON document_read_grants(principal_id, document_id);

-- The caller must derive principal_id from verified identity, never from an
-- untrusted request field. This query does not itself enforce DB privileges.
CREATE FUNCTION authorized_chunks(p_principal_id text)
RETURNS TABLE(chunk_id uuid, document_id uuid, version_id uuid, section_id uuid,
              title text, content text, source_uri text, source_locator text)
LANGUAGE sql STABLE AS $$
    SELECT c.id, d.id, v.id, s.id, v.title, c.content, d.source_uri, c.source_locator
    FROM chunks c
    JOIN sections s ON s.id = c.section_id AND s.version_id = c.version_id
    JOIN document_versions v ON v.id = c.version_id
    JOIN documents d ON d.id = v.document_id
    WHERE v.status = 'approved'
      AND EXISTS (SELECT 1 FROM document_read_grants g
                  WHERE g.document_id = d.id AND g.principal_id = p_principal_id);
$$;

COMMIT;
