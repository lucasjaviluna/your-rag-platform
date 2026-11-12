-- Group identifiers and membership are local pilot data. They are not proof of
-- corporate identity and must be synchronized from a trusted source later.
CREATE TABLE access_groups (
    id text PRIMARY KEY CHECK (length(trim(id)) > 0)
);

CREATE TABLE group_memberships (
    group_id text NOT NULL REFERENCES access_groups(id) ON DELETE CASCADE,
    principal_id text NOT NULL CHECK (length(trim(principal_id)) > 0),
    PRIMARY KEY (group_id, principal_id)
);

CREATE INDEX group_memberships_principal_idx ON group_memberships(principal_id, group_id);

CREATE TABLE document_group_read_grants (
    document_id uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    group_id text NOT NULL REFERENCES access_groups(id) ON DELETE CASCADE,
    PRIMARY KEY (document_id, group_id)
);

-- Direct or group grants allow reading. Missing principals and unapproved
-- versions remain denied. The trusted caller must supply the principal.
CREATE OR REPLACE FUNCTION authorized_chunks(p_principal_id text)
RETURNS TABLE(chunk_id uuid, document_id uuid, version_id uuid, section_id uuid,
              title text, content text, source_uri text, source_locator text)
LANGUAGE sql STABLE AS $$
    SELECT c.id, d.id, v.id, s.id, v.title, c.content, d.source_uri, c.source_locator
    FROM chunks c
    JOIN sections s ON s.id = c.section_id AND s.version_id = c.version_id
    JOIN document_versions v ON v.id = c.version_id
    JOIN documents d ON d.id = v.document_id
    WHERE v.status = 'approved'
      AND p_principal_id IS NOT NULL AND length(trim(p_principal_id)) > 0
      AND (
        EXISTS (SELECT 1 FROM document_read_grants g
                WHERE g.document_id = d.id AND g.principal_id = p_principal_id)
        OR EXISTS (SELECT 1 FROM document_group_read_grants dg
                   JOIN group_memberships gm ON gm.group_id = dg.group_id
                   WHERE dg.document_id = d.id AND gm.principal_id = p_principal_id)
      );
$$;
