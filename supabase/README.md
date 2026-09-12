# Backend de Prep4Job

## Configuración

1. Crea un proyecto en Supabase.
2. Ejecuta `migrations/001_initial_schema.sql` en el SQL Editor.
3. Activa Apple en Authentication → Providers y registra el Service ID, Team ID y Key de Apple.
4. Define estos secretos para las Edge Functions:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
OPENAI_API_KEY
OPENAI_MODEL=gpt-4o-mini
APPLE_ROOT_CERTIFICATE_PEM
```

5. Despliega `ai-proxy`, `delete-account` y `apple-webhook`.
6. Configura App Store Server Notifications V2 para apuntar a `apple-webhook`.
7. Añade `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` al `Info.plist` o a un `.xcconfig` de la app.

El cliente nunca debe contener `SUPABASE_SERVICE_ROLE_KEY` ni `OPENAI_API_KEY`. La función `ai-proxy` exige un JWT de Supabase y un entitlement Premium activo antes de llamar al proveedor de IA.
