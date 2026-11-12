# Plan de desarrollo y seguimiento

Última actualización: 2026-11-12. Estado de cada punto refleja lo implementado en este repositorio, no una validación de producción.

## Hito 0 — Bootstrap (en curso)

- [x] Esqueleto API .NET y worker Python con endpoints de salud.
- [x] Compose con PostgreSQL/pgvector y datos sintéticos.
- [x] Documentación de arquitectura, decisiones y seguimiento.
- [x] Pruebas básicas y CI definidos.
- [ ] Ejecutar CI y verificar restauración, compilación .NET y Compose en un entorno con Docker y SDK 10.
- [ ] Validar políticas de versiones, licencias e imágenes; fijar digest cuando se establezca la política de actualizaciones.

## Hito 1 — Modelo y seguridad (en curso)

- [x] Migración SQL inicial para documentos, versiones, secciones, chunks y permisos individuales de lectura.
- [x] Consulta de chunks autorizados: permisos explícitos y versiones aprobadas; denegación por defecto y revocación inmediata en base de datos.
- [x] Prueba SQL de concesión, aislamiento, identidad ausente, borradores y revocación; incluida en CI.
- [ ] Ejecutar y verificar migración y pruebas con PostgreSQL real; este entorno no dispone de Docker/PostgreSQL.
- [ ] Incorporar gestor de migraciones versionadas para actualizaciones seguras y repetibles.
- [ ] Integrar autenticación verificada y consulta autorizada en la API; no aceptar identidad de un parámetro controlado por el cliente.
- [ ] Agregar grupos, herencia/sincronización de ACL de fuente, auditoría y protección de acceso directo a tablas.
- [ ] Tests de integración reales para identidad, expansión y revocación en el flujo completo.

La función SQL es una consulta de aplicación, no una barrera autónoma de seguridad: el acceso directo a tablas debe restringirse y la identidad debe ser confiable. Por ahora no se expone ningún endpoint documental. Todo permanece limitado a datos sintéticos.

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
