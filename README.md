# Prep4Job
IOS App to prepare for job HR questions

Fase 1
Apliqué una refactorización senior orientada a Clean Architecture, SOLID y concurrencia segura.
Cambios principales:
	•	Separé responsabilidades:
	◦	Dominio: [Models.swift]
	◦	Datos y repositorio: [DemoContentRepository.swift]
	◦	Presentación y estado: [PrepStore.swift]
	•	PrepStore ahora:
	◦	Usa ObservableObject y @Published de Combine.
	◦	Protege el estado con private(set).
	◦	Usa async/await y async let para cargar contenido.
	◦	Tiene inyección de dependencias mediante PrepContentRepository.
	◦	Evita crashes si no existen preguntas.
	◦	Limita el progreso máximo al 100%.
	◦	Mantiene la UI aislada en @MainActor.
	•	Reemplacé las tuplas de pasos por LearningStep, compatible con:
	◦	Identifiable
	◦	Hashable
	◦	Codable
	◦	Sendable
	•	Activé concurrencia estricta:


Fase 2
Clean Architecture con casos de uso y ViewModels por feature.
Cambios principales:
	•	Casos de uso en [PreparationUseCases.swift]:
	◦	Cargar contenido.
	◦	Seleccionar pregunta diaria.
	◦	Revelar respuesta.
	◦	Completar conceptos.
	◦	Calcular progreso.
	•	ViewModels en [FeatureViewModels.swift]:
	◦	HomeViewModel
	◦	DailyQuestionViewModel
	◦	LearnViewModel
	◦	ProgressViewModel
	•	Las vistas ya no ejecutan directamente la lógica del PrepStore.
	•	Combine se usa para propagar cambios del estado hacia los ViewModels.
	•	PrepStore ahora coordina casos de uso, no concentra toda la lógica.
	•	Se mantiene async/await, @MainActor y concurrencia estricta.
	•	Se añadieron pruebas directas para los casos de uso.
Validaciones realizadas:
	•	Build con SWIFT_STRICT_CONCURRENCY = complete: correcto.
	•	SwiftLint: 0 violaciones.
	•	SwiftFormat: correcto.
	•	5 tests unitarios pasaron.
	•	La app se instaló y ejecutó correctamente en el simulador.
La siguiente etapa sería el paso 3: integrar el servicio de IA mediante un protocolo como AIAnswerService, manejar estados loading/success/error, cancelación de tareas y posteriormente persistencia local.


Paso 4 completado.
Implementado:
- Repetición espaciada basada en SM-2 con niveles: Otra vez, Difícil, Bien y Fácil.
- Próxima fecha de revisión calculada automáticamente.
- Persistencia de intervalos, repeticiones, factor de facilidad y fechas.
- Seguimiento de actividad diaria, racha y temas repasados.
- Progreso dinámico en Home y Dashboard.
- Recordatorios diarios mediante UNUserNotificationCenter, programados inicialmente a las 19:00.
- Compatibilidad con snapshots antiguos sin perder datos.
- Tests de algoritmo, progreso, migración y notificaciones.
Archivos principales:
- [SpacedRepetition.swift]
- [StudyProgress.swift]
- [StudyReminderScheduler.swift]
- [PrepStore.swift]
- [ProgressDashboardView.swift]
- [Prep4JobTests.swift]
Validación:
- 11 tests aprobados.
- Compilación con concurrencia estricta correcta.
- SwiftLint: 0 violaciones.
- SwiftFormat ejecutado.
- App instalada y ejecutada en el simulador.

Paso 5 implementado en /Users/renzo/Documents/Prep4Job.
Incluye:
- Registro, inicio/cierre de sesión y restauración local.
- Arquitectura AuthService preparada para conectar Supabase.
- Suscripciones Premium con StoreKit 2.
- Modo Demo para desarrollo sin cuenta Apple.
- Pantalla de cuenta y Premium accesible desde el icono de usuario.
- Productos:
  - prep4job.premium.monthly
  - prep4job.premium.yearly
- Localización centralizada.
- Tests para autenticación y suscripciones.
Archivos principales:
- [AccountView.swift](/Users/renzo/Documents/Prep4Job/Prep4Job/Prep4Job/AccountView.swift)
- [LocalAuthService.swift](/Users/renzo/Documents/Prep4Job/Prep4Job/Prep4Job/Data/LocalAuthService.swift)
- [SupabaseAuthService.swift](/Users/renzo/Documents/Prep4Job/Prep4Job/Prep4Job/Data/SupabaseAuthService.swift)
- [StoreKitSubscriptionService.swift](/Users/renzo/Documents/Prep4Job/Prep4Job/Prep4Job/Data/StoreKitSubscriptionService.swift)
- [SessionStore.swift](/Users/renzo/Documents/Prep4Job/Prep4Job/Prep4Job/Presentation/SessionStore.swift)
- [SubscriptionStore.swift](/Users/renzo/Documents/Prep4Job/Prep4Job/Prep4Job/Presentation/SubscriptionStore.swift)
Verificación realizada:
- SwiftLint: 0 violaciones.
- Compilación Debug estricta: correcta.
- Compilación Release estricta: correcta.
- Tests unitarios: 13/13 correctos.
- Instalación y ejecución en simulador: correcta.
Actualmente funciona en modo local/Demo, por lo que no necesitas todavía cuenta de Apple Developer ni Supabase. Para producción faltaría configurar Supabase, crear los productos en App Store Connect y añadir persistencia segura de sesión mediante Keychain.

RevenueCat
- SPM oficial: `https://github.com/RevenueCat/purchases-ios-spm.git`. El proyecto enlaza los productos `RevenueCat` y `RevenueCatUI` (versión resuelta 5.90.1).
- El SDK se configura al iniciar la app mediante `RevenueCatConfiguration` con la clave pública de prueba `test_...` proporcionada para este proyecto.
- `SubscriptionServiceFactory` usa `RevenueCatSubscriptionService` cuando RevenueCat está configurado; sin configuración conserva Demo en Debug y StoreKit 2 en Release.
- Entitlement esperado en RevenueCat: `prep4job_pro`.
- Crea estos productos en RevenueCat y asígnalos al offering actual:
  - `prep4job.premium.lifetime` (Lifetime)
  - `prep4job.premium.yearly` (Yearly)
  - `prep4job.premium.monthly` (Monthly)
- `PremiumCard` presenta el Paywall remoto con `RevenueCatUI.PaywallView` y ofrece `CustomerCenterView` para gestionar/restaurar compras.

La clave pública de RevenueCat puede incluirse en el cliente; nunca uses una clave secreta del dashboard dentro de la app. Configura el entitlement, offering y productos en el dashboard antes de probar compras.


Implementé todo lo que puede quedar preparado en el repositorio sin credenciales externas.
Backend Supabase
- Migración SQL con tablas:
  - profiles
  - interview_questions
  - learning_concepts
  - progress_items
  - entitlements
- Trigger automático para crear perfil y entitlement al registrar usuario.
- Políticas RLS para proteger datos por usuario.
Archivo: [001_initial_schema.sql](/Users/renzo/Documents/Prep4Job/supabase/migrations/001_initial_schema.sql)
Funciones Edge
- ai-proxy: exige JWT válido y entitlement Premium antes de llamar a OpenAI.
- delete-account: elimina la cuenta autenticada.
- apple-webhook: recibe notificaciones de App Store Server y actualiza entitlements.
Archivos:
- [ai-proxy/index.ts](/Users/renzo/Documents/Prep4Job/supabase/functions/ai-proxy/index.ts)
- [delete-account/index.ts](/Users/renzo/Documents/Prep4Job/supabase/functions/delete-account/index.ts)
- [apple-webhook/index.ts](/Users/renzo/Documents/Prep4Job/supabase/functions/apple-webhook/index.ts)
StoreKit y compras
Creé configuración local para probar suscripciones:
[Prep4Job.storekit](/Users/renzo/Documents/Prep4Job/Prep4Job/Prep4Job.storekit)
Incluye:
- prep4job.premium.monthly
- prep4job.premium.yearly
- prep4job.premium.lifetime
También agregué eliminación de cuenta, privacidad y términos en [AccountView.swift](/Users/renzo/Documents/Prep4Job/Prep4Job/Prep4Job/AccountView.swift).
Estado real
La implementación técnica está preparada, pero todavía debes realizar manualmente:
1. Crear el proyecto Supabase.
2. Ejecutar la migración SQL.
3. Configurar Apple Auth.
4. Añadir secretos de Supabase, OpenAI y Apple.
5. Crear productos en App Store Connect.
6. Configurar Sandbox y webhook.
7. Revisar legalmente los textos de privacidad y términos.
La app compila correctamente, SwiftLint queda en cero y las 13 pruebas unitarias pasan.
