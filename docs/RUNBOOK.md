# Runbook — pipeline-analytics-emergencia

Guia de procedimentos operacionais para manutenção do pipeline.

---

## Deploy da imagem de ingestão

**Quando usar:** sempre que houver alteração em qualquer arquivo dentro da pasta `ingestion/`.

**Comando:**
```bash
gcloud builds submit ingestion/ --tag us-east1-docker.pkg.dev/pipeline-analytics-emergencia/pipeline-ingestao/ingestao:latest
```

**O que esse comando faz:**
1. Envia a pasta `ingestion/` para o Cloud Build no GCP
2. Constrói a nova imagem Docker
3. Publica a imagem no Artifact Registry com a tag `latest`

**Após o deploy:** o Cloud Run Service já passa a usar a nova imagem automaticamente na próxima execução.