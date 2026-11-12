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

Compose publica PostgreSQL sólo en localhost. Su volumen persiste al detener los contenedores. No usar estas credenciales ni esta configuración en producción.

## Documentación

- [Arquitectura](docs/architecture.md)
- [Plan y seguimiento](docs/development-plan.md)
- [Decisiones técnicas](docs/adr/0001-bootstrap.md)
- [Datos sintéticos](sample-data/README.md)

