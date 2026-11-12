\set ON_ERROR_STOP on
BEGIN;
INSERT INTO documents(id, source_key, source_uri, domain, classification, owner_id) VALUES
 ('00000000-0000-0000-0000-000000000001','test/one','synthetic://one','test','internal','owner'),
 ('00000000-0000-0000-0000-000000000002','test/two','synthetic://two','test','internal','owner');
INSERT INTO document_versions(id, document_id, version_number, title, content_hash, status) VALUES
 ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001',1,'Approved','h1','approved'),
 ('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002',1,'Draft','h2','draft');
INSERT INTO sections(id, version_id, title, ordinal) VALUES
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Section',0),
 ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','Section',0);
INSERT INTO chunks(id, version_id, section_id, ordinal, content, content_hash) VALUES
 ('30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',0,'authorized','c1'),
 ('30000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002',0,'draft','c2');
INSERT INTO document_read_grants VALUES
 ('00000000-0000-0000-0000-000000000001','alice'),
 ('00000000-0000-0000-0000-000000000002','alice');
DO $$ BEGIN
 IF (SELECT count(*) FROM authorized_chunks('alice')) <> 1 THEN RAISE EXCEPTION 'approved grant failed'; END IF;
 IF EXISTS (SELECT FROM authorized_chunks('bob')) THEN RAISE EXCEPTION 'unauthorized access'; END IF;
 IF EXISTS (SELECT FROM authorized_chunks(NULL)) THEN RAISE EXCEPTION 'missing principal must deny'; END IF;
END $$;
DELETE FROM document_read_grants WHERE principal_id='alice';
DO $$ BEGIN
 IF EXISTS (SELECT FROM authorized_chunks('alice')) THEN RAISE EXCEPTION 'revocation failed'; END IF;
END $$;
INSERT INTO access_groups(id) VALUES ('pilot-business'), ('pilot-other');
INSERT INTO group_memberships(group_id, principal_id) VALUES
 ('pilot-business','alice'), ('pilot-other','bob');
INSERT INTO document_group_read_grants(document_id, group_id) VALUES
 ('00000000-0000-0000-0000-000000000001','pilot-business'),
 ('00000000-0000-0000-0000-000000000002','pilot-business');
DO $$ BEGIN
 IF (SELECT count(*) FROM authorized_chunks('alice')) <> 1 THEN RAISE EXCEPTION 'group grant or draft exclusion failed'; END IF;
 IF EXISTS (SELECT FROM authorized_chunks('bob')) THEN RAISE EXCEPTION 'unrelated group leaked'; END IF;
 IF EXISTS (SELECT FROM authorized_chunks(NULL)) OR EXISTS (SELECT FROM authorized_chunks('')) THEN RAISE EXCEPTION 'missing identity leaked'; END IF;
END $$;
-- Overlapping direct and group grants must not duplicate rows.
INSERT INTO document_read_grants VALUES ('00000000-0000-0000-0000-000000000001','alice');
DO $$ BEGIN
 IF (SELECT count(*) FROM authorized_chunks('alice')) <> 1 THEN RAISE EXCEPTION 'duplicate grant leaked rows'; END IF;
END $$;
DELETE FROM document_read_grants WHERE principal_id='alice';
DELETE FROM document_group_read_grants WHERE group_id='pilot-business' AND document_id='00000000-0000-0000-0000-000000000001';
DO $$ BEGIN
 IF EXISTS (SELECT FROM authorized_chunks('alice')) THEN RAISE EXCEPTION 'group grant revocation failed'; END IF;
END $$;
INSERT INTO document_group_read_grants(document_id, group_id)
VALUES ('00000000-0000-0000-0000-000000000001','pilot-business');
DELETE FROM group_memberships WHERE principal_id='alice';
DO $$ BEGIN
 IF EXISTS (SELECT FROM authorized_chunks('alice')) THEN RAISE EXCEPTION 'group membership revocation failed'; END IF;
END $$;
ROLLBACK;
