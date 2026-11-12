# Your RAG Platform

Plataforma de recuperación documental corporativa. Hito 0: base de desarrollo; aún no implementa ingesta, embeddings, búsqueda ni seguridad corporativa.

## Requisitos

- .NET SDK 10, Python 3.12, Docker con Compose y Git.
- Los ejemplos son sintéticos. No cargar información corporativa en esta etapa.

## Inicio (Linux, macOS y PowerShell)

1. Copiar `.env.example` a `.env` y cambiar las credenciales locales.
2. Ejecutar `docker compose up -d`.
3. Ejecutar `dotnet run --project src/RagPlatform.Api` y consultar `http://localhost:5080/health`.
4. En otra terminal ejecutar `python -m worker` desde `workers/rag_worker` y consultar `http://127.0.0.1:8090/health`.
5. Comprobar `dotnet test tests/RagPlatform.Tests` y `python -m unittest discover -s workers/rag_worker/tests` desde la raíz.

La API y el worker son esqueletos independientes. `/health` sólo indica que cada proceso responde; no verifica PostgreSQL ni disponibilidad de modelos. El worker usa únicamente la biblioteca estándar de Python.

## Modelo documental experimental

En una base local recién creada, aplicar la migración una sola vez:

```bash
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U rag_local -d rag_platform < infra/postgres/migrations/001_document_model.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U rag_local -d rag_platform < tests/database/document_model.sql
```

Estos comandos usan las credenciales de ejemplo; ajustarlas si se cambió `.env`. El test hace rollback de sus datos. La migración aún no tiene gestor de versiones. No usar con datos reales.

Para probar la consulta desde la API, configurar `DevelopmentIdentity__PrincipalId` con una identidad sintética y `ConnectionStrings__RagPlatform` con una conexión local de PostgreSQL, y ejecutar la API en Development. `GET /dev/chunks` devuelve hasta 100 chunks aprobados y autorizados para esa identidad fija. Deben existir datos y permisos sintéticos cargados previamente; el test SQL no los conserva. El endpoint no se registra fuera de Development y no autentica usuarios. No exponerlo a redes compartidas: cualquier cliente local que acceda hereda esa identidad. La consulta requiere autenticación real y permisos de base de datos restrictivos antes de un uso corporativo.

La prueba HTTP de base de datos sólo se ejecuta si `RAG_TEST_DATABASE` contiene la conexión a una base de pruebas con la migración aplicada. CI configura esta variable explícitamente. La prueba crea datos sintéticos y los elimina al finalizar; usar una base dedicada a tests.

Compose publica PostgreSQL sólo en localhost. Su volumen persiste al detener los contenedores. No usar estas credenciales ni esta configuración en producción.

## Documentación

- [Arquitectura](docs/architecture.md)
- [Plan y seguimiento](docs/development-plan.md)
- [Decisiones técnicas](docs/adr/0001-bootstrap.md)
- [Datos sintéticos](sample-data/README.md)

