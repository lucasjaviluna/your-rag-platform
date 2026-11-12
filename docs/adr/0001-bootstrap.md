# ADR 0001: base de la plataforma

Estado: aceptado para el arranque. Fecha: 2026-11-12.

Usaremos ASP.NET Core 10 para la API y lógica de aplicación, Python para procesamiento documental e inferencia, y PostgreSQL con pgvector y FTS. La aplicación será modular; los servicios locales se agregarán sólo al necesitarlos. La recuperación será independiente de generación por LLM y expondrá evidencias con procedencia.

Las ACL son requisito del diseño y deben aplicarse antes o durante la recuperación y en la expansión, con comportamiento fail-closed. El esqueleto inicial no implementa seguridad y sólo admite datos sintéticos.

Docling/HybridChunker y Qwen3 son candidatos, no dependencias fijadas. Se compararán modelos y alternativas sobre casos etiquetados y el hardware disponible. BGE-M3 es alternativa de embeddings; BGE-reranker-v2-m3 es alternativa de reranking.
