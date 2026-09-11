#!/usr/bin/env bash

# Prep4Job production setup.
# This script never stores secrets in the repository.
set -Eeuo pipefail

PROJECT_REF="acwfqycsiauktidsvgci"
SUPABASE_URL="https://acwfqycsiauktidsvgci.supabase.co"
CLI=(npx --yes supabase)

log() { printf '\n[Prep4Job] %s\n' "$1"; }
fail() { printf '\n[Prep4Job] ERROR: %s\n' "$1" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

command -v npx >/dev/null 2>&1 || fail "Node.js/npx no está instalado."

log "Comprobando autenticación de Supabase CLI"
if ! "${CLI[@]}" projects list >/dev/null 2>&1; then
    printf 'Ejecuta primero: npx supabase login\n'
    exit 2
fi

if [[ ! -f "supabase/config.toml" ]]; then
    log "Inicializando configuración local de Supabase"
    "${CLI[@]}" init
fi

log "Enlazando el proyecto remoto ${PROJECT_REF}"
"${CLI[@]}" link --project-ref "$PROJECT_REF"

log "Aplicando migraciones SQL"
"${CLI[@]}" db push

log "Configurando secretos no sensibles"
"${CLI[@]}" secrets set OPENAI_MODEL="${OPENAI_MODEL:-gpt-4o-mini}"

if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    log "Configurando OPENAI_API_KEY desde variable de entorno"
    "${CLI[@]}" secrets set OPENAI_API_KEY="$OPENAI_API_KEY"
else
    printf 'OPENAI_API_KEY no está definida; se omitirá.\n'
    printf 'Configúrala después con: npx supabase secrets set OPENAI_API_KEY=...\n'
fi

if [[ -n "${APPLE_ROOT_CERTIFICATE_PEM:-}" ]]; then
    log "Configurando certificado raíz de Apple desde variable de entorno"
    "${CLI[@]}" secrets set APPLE_ROOT_CERTIFICATE_PEM="$APPLE_ROOT_CERTIFICATE_PEM"
elif [[ -f "${APPLE_ROOT_CERTIFICATE_FILE:-}" ]]; then
    log "Configurando certificado raíz de Apple desde archivo local"
    "${CLI[@]}" secrets set APPLE_ROOT_CERTIFICATE_PEM="$(<"$APPLE_ROOT_CERTIFICATE_FILE")"
else
    printf 'APPLE_ROOT_CERTIFICATE_PEM no está definido; se omitirá.\n'
fi

log "Desplegando Edge Functions"
"${CLI[@]}" functions deploy ai-proxy
"${CLI[@]}" functions deploy delete-account
"${CLI[@]}" functions deploy apple-webhook

log "Configuración técnica completada"
printf 'Proyecto: %s\n' "$SUPABASE_URL"
printf 'Migraciones y Edge Functions desplegadas.\n'
printf 'Revisa los secretos omitidos antes de habilitar producción.\n'
