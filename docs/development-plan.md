# Plan de desarrollo y seguimiento

Última actualización: 2026-11-12. Estado de cada punto refleja lo implementado en este repositorio, no una validación de producción.

## Hito 0 — Bootstrap (en curso)

- [x] Esqueleto API .NET y worker Python con endpoints de salud.
- [x] Compose con PostgreSQL/pgvector y datos sintéticos.
- [x] Documentación de arquitectura, decisiones y seguimiento.
- [x] Pruebas básicas y CI definidos.
- [ ] Ejecutar CI y verificar restauración, compilación .NET y Compose en un entorno con Docker y SDK 10.
- [ ] Validar políticas de versiones, licencias e imágenes; fijar digest cuando se establezca la política de actualizaciones.

## Hito 1 — Modelo y seguridad (pendiente)

Diseñar documentos, versiones, secciones, chunks, procedencia, estados y ACL; agregar migraciones y consultas autorizadas. Diseñar identidad para desarrollo y autorización fail-closed; probar denegación y revocación. No confundir identidad sintética con autenticación corporativa.

## Hito 2 — Ingesta y chunking (pendiente)

Ingerir Markdown sintético, conservar secciones y contexto padre/hijo, hashes y versiones. Incorporar PDF/DOCX mediante evaluación de Docling, con extracción verificable y pruebas de tablas/procedencia.

## Hito 3 — Retrieval híbrido (pendiente)

Generar embeddings locales; implementar FTS y búsqueda exacta de identificadores, pgvector, RRF y filtros ACL. Definir dimensiones e índices tras probar modelos y pgvector; medir recall con filtros.

## Hito 4 — Reranking y evidencias (pendiente)

Integrar reranker local, expansión autorizada, presupuesto de contexto y REST con fuentes, versiones y puntuaciones por etapa. Sin generación por LLM obligatoria.

## Hito 5 — Evaluación (pendiente)

Construir consultas etiquetadas; comparar FTS, vector, híbrido y reranking. Medir Recall@K, Precision@K, MRR, nDCG, latencia y aislamiento ACL. Comparar Qwen3 con BGE antes de fijar modelos.

## Hito 6 — Piloto y endurecimiento (pendiente)

Conectar una fuente corporativa autorizada; integrar identidad y ACL reales; añadir MCP y dos consumidores. Validar reindexación, revocación, auditoría sin contenido sensible, backup/restore, despliegue y observabilidad.

## Decisiones abiertas

Hardware y sistema operativo de despliegue; proveedor de identidad y propagación de ACL; primera fuente corporativa; límites y métricas objetivo; versiones exactas de herramientas de IA y modelos. No usar datos reales antes de resolver seguridad y autorización.
