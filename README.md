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

