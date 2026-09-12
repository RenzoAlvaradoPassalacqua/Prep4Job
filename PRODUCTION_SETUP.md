# Configuración de producción

El script `setup-production.sh` automatiza la configuración técnica sin guardar secretos en Git.

## Uso

Desde la raíz del proyecto:

```bash
cd /Users/renzo/Documents/Prep4Job
chmod +x setup-production.sh
npx supabase login
```

Define los secretos solo en la sesión actual de Terminal:

```bash
read -s OPENAI_API_KEY
export OPENAI_API_KEY
export OPENAI_MODEL=gpt-4o-mini
./setup-production.sh
unset OPENAI_API_KEY OPENAI_MODEL
```

Para el certificado raíz de Apple, usa un archivo local que no esté versionado:

```bash
export APPLE_ROOT_CERTIFICATE_FILE="/ruta/local/apple-root-certificate.pem"
./setup-production.sh
unset APPLE_ROOT_CERTIFICATE_FILE
```

El script ejecuta:

1. Comprobación de login de Supabase CLI.
2. `supabase init` si falta la configuración local.
3. Enlace con el proyecto `acwfqycsiauktidsvgci`.
4. `supabase db push`.
5. Configuración de `OPENAI_MODEL` y secretos opcionales.
6. Despliegue de `ai-proxy`, `delete-account` y `apple-webhook`.

No incluye claves en el repositorio y no acepta `SUPABASE_SECRET_KEY` dentro de la app iOS.
