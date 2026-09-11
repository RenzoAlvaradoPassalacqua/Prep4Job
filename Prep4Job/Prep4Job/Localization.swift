import Foundation

// Los valores de fallback contienen copy editorial; se mantiene cada mensaje
// completo para facilitar su revisión y extracción al catálogo de traducciones.

// swiftlint:disable type_body_length
// Textos visibles de Prep4Job en un único punto.
// Los valores se resuelven mediante `String(localized:)`, por lo que se pueden
// traducir más adelante añadiendo las claves a un catálogo de cadenas sin
// tener que volver a tocar las vistas.
// El catálogo se mantiene centralizado para que las vistas no contengan copy.
nonisolated enum L10n {
    nonisolated enum Common {
        static let ready = String(localized: "common.ready", defaultValue: "listo")

        static func percent(_ value: Int) -> String {
            String(localized: "common.percent", defaultValue: "\(value)%")
        }
    }

    nonisolated enum Errors {
        static let emptyContent = String(
            localized: "error.emptyContent",
            defaultValue: "No hay contenido disponible para mostrar."
        )
        static let loadFailed = String(
            localized: "error.loadFailed",
            defaultValue: "No se pudo cargar el contenido. Inténtalo de nuevo."
        )
        static let aiAnswerUnavailable = String(
            localized: "error.aiAnswerUnavailable",
            defaultValue: "La IA no pudo generar una respuesta en este momento."
        )
        static let notificationsDenied = String(
            localized: "error.notificationsDenied",
            defaultValue: "Activa las notificaciones en Ajustes para recibir recordatorios."
        )
        static let notificationsUnavailable = String(
            localized: "error.notificationsUnavailable",
            defaultValue: "No se pudo programar el recordatorio. Inténtalo de nuevo."
        )
    }

    nonisolated enum Tabs {
        static let home = String(localized: "tab.home", defaultValue: "Inicio")
        static let learn = String(localized: "tab.learn", defaultValue: "Aprender")
        static let progress = String(localized: "tab.progress", defaultValue: "Progreso")
    }

    nonisolated enum Home {
        static let appName = String(localized: "home.appName", defaultValue: "Prep4Job")
        static let subtitle = String(localized: "home.subtitle", defaultValue: "Tu coach de entrevistas con IA")
        static let greeting = String(localized: "home.greeting", defaultValue: "Buenos días, Renzo")
        static let intro = String(
            localized: "home.intro",
            defaultValue: "Pequeños avances, grandes oportunidades. Sigamos construyendo tu mejor versión."
        )
        static let todayPreparation = String(localized: "home.todayPreparation", defaultValue: "Tu preparación de hoy")
        static let todayDate = String(localized: "home.todayDate", defaultValue: "Lun, 14 abr.")
        static let twoConcepts = String(localized: "home.twoConcepts", defaultValue: "2 conceptos")
        static let oneQuestion = String(localized: "home.oneQuestion", defaultValue: "1 pregunta")
        static let onePractice = String(localized: "home.onePractice", defaultValue: "1 práctica")
        static let quickReview = String(localized: "home.quickReview", defaultValue: "Repaso rápido")
        static let start = String(localized: "home.start", defaultValue: "Comenzar")
        static let quote = String(localized: "home.quote", defaultValue: "La confianza también se entrena.")
    }

    nonisolated enum DailyQuestion {
        static func counter(current: Int, total: Int) -> String {
            String(localized: "dailyQuestion.counter", defaultValue: "PREGUNTA \(current) DE \(total)")
        }

        static let tip = String(localized: "dailyQuestion.tip", defaultValue: "Consejo")
        static let showAIAnswer = String(localized: "dailyQuestion.showAIAnswer", defaultValue: "Ver respuesta IA")
        static let writeAnswer = String(localized: "dailyQuestion.writeAnswer", defaultValue: "Escribir mi respuesta")
        static let title = String(localized: "dailyQuestion.title", defaultValue: "Pregunta diaria")
        static let close = String(localized: "common.close", defaultValue: "Cerrar")
        static let recommendedAnswer = String(
            localized: "dailyQuestion.recommendedAnswer",
            defaultValue: "Respuesta recomendada"
        )
        static let answerDescription = String(
            localized: "dailyQuestion.answerDescription",
            defaultValue: "Una forma efectiva de responder esta pregunta usando el método STAR."
        )
        static let personalize = String(
            localized: "dailyQuestion.personalize",
            defaultValue: "Personalizar con mi experiencia"
        )
        static let editorHint = String(
            localized: "dailyQuestion.editorHint",
            defaultValue: "Escribe una experiencia real. La app te ayudará a organizarla sin inventar información."
        )
        static let saveAnswer = String(localized: "dailyQuestion.saveAnswer", defaultValue: "Guardar respuesta")
        static let nextQuestion = String(localized: "dailyQuestion.nextQuestion", defaultValue: "Siguiente pregunta")
        static let myAnswer = String(localized: "dailyQuestion.myAnswer", defaultValue: "Mi respuesta")
        static let emptyTitle = String(localized: "dailyQuestion.emptyTitle", defaultValue: "Pregunta no disponible")
        static let emptyMessage = String(
            localized: "dailyQuestion.emptyMessage",
            defaultValue: "No hay preguntas disponibles en este momento."
        )
        static let generatingAnswer = String(
            localized: "dailyQuestion.generatingAnswer",
            defaultValue: "Generando respuesta con IA..."
        )
        static let retryAnswer = String(
            localized: "dailyQuestion.retryAnswer",
            defaultValue: "Reintentar respuesta IA"
        )
        static let cancelGeneration = String(
            localized: "dailyQuestion.cancelGeneration",
            defaultValue: "Cancelar"
        )
        static let rateAnswer = String(
            localized: "dailyQuestion.rateAnswer",
            defaultValue: "¿Qué tan fácil fue recordarla?"
        )
        static let ratingAgain = String(localized: "dailyQuestion.ratingAgain", defaultValue: "Otra vez")
        static let ratingHard = String(localized: "dailyQuestion.ratingHard", defaultValue: "Difícil")
        static let ratingGood = String(localized: "dailyQuestion.ratingGood", defaultValue: "Bien")
        static let ratingEasy = String(localized: "dailyQuestion.ratingEasy", defaultValue: "Fácil")
    }

    nonisolated enum Learn {
        static let title = String(localized: "learn.title", defaultValue: "Aprende y recuerda")
        static let subtitle = String(
            localized: "learn.subtitle",
            defaultValue: "Conceptos que convierten tus experiencias en respuestas más sólidas."
        )
        static let howToUse = String(localized: "learn.howToUse", defaultValue: "Cómo usarlo")
        static let conceptCompleted = String(localized: "learn.conceptCompleted", defaultValue: "Concepto completado")
        static let markAsLearned = String(localized: "learn.markAsLearned", defaultValue: "Marcar como aprendido")
        static let concept = String(localized: "learn.concept", defaultValue: "Concepto")
    }

    nonisolated enum Progress {
        static let title = String(localized: "progress.title", defaultValue: "Tu progreso")
        static let subtitle = String(
            localized: "progress.subtitle",
            defaultValue: "La constancia te acerca a grandes oportunidades."
        )
        static let days = [
            String(localized: "progress.day.monday", defaultValue: "Lun"),
            String(localized: "progress.day.tuesday", defaultValue: "Mar"),
            String(localized: "progress.day.wednesday", defaultValue: "Mié"),
            String(localized: "progress.day.thursday", defaultValue: "Jue"),
            String(localized: "progress.day.friday", defaultValue: "Vie"),
            String(localized: "progress.day.saturday", defaultValue: "Sáb"),
            String(localized: "progress.day.sunday", defaultValue: "Dom")
        ]
        static let concepts = String(localized: "progress.concepts", defaultValue: "conceptos")
        static let answers = String(localized: "progress.answers", defaultValue: "respuestas")
        static let streakDays = String(localized: "progress.streakDays", defaultValue: "días de racha")
        static func reviewToday(count _: Int) -> String {
            String(localized: "progress.reviewToday", defaultValue: "Repasar hoy · (count) temas")
        }

        static let reviewDescription = String(
            localized: "progress.reviewDescription",
            defaultValue: "Refuerza tus puntos más importantes y sigue avanzando."
        )
        static let motivation = String(
            localized: "progress.motivation",
            defaultValue: "Disciplina hoy, entrevista soñada mañana."
        )
        static let remindersTitle = String(
            localized: "progress.remindersTitle",
            defaultValue: "Recordatorio diario"
        )
        static let remindersEnabled = String(
            localized: "progress.remindersEnabled",
            defaultValue: "Te avisaremos cada día a las 19:00."
        )
        static let remindersDisabled = String(
            localized: "progress.remindersDisabled",
            defaultValue: "Recibe un aviso para mantener tu ritmo de estudio."
        )
        static let enableReminder = String(
            localized: "progress.enableReminder",
            defaultValue: "Activar recordatorio"
        )
        static let disableReminder = String(
            localized: "progress.disableReminder",
            defaultValue: "Desactivar recordatorio"
        )
        static func reviewProgress(reviewed _: Int, total _: Int) -> String {
            String(localized: "progress.reviewProgress", defaultValue: "(reviewed) de (total) temas repasados")
        }
    }

    nonisolated enum Notifications {
        static let title = String(localized: "notifications.title", defaultValue: "Prep4Job")
        static let body = String(
            localized: "notifications.body",
            defaultValue: "Tu sesión de hoy te acerca a tu próxima oportunidad."
        )
    }

    nonisolated enum Account {
        static let title = String(localized: "account.title", defaultValue: "Mi cuenta")
        static let createTitle = String(localized: "account.createTitle", defaultValue: "Crea tu cuenta")
        static let signInTitle = String(localized: "account.signInTitle", defaultValue: "Inicia sesión")
        static let email = String(localized: "account.email", defaultValue: "Correo electrónico")
        static let password = String(localized: "account.password", defaultValue: "Contraseña")
        static let displayName = String(localized: "account.displayName", defaultValue: "Nombre")
        static let signIn = String(localized: "account.signIn", defaultValue: "Iniciar sesión")
        static let signUp = String(localized: "account.signUp", defaultValue: "Crear cuenta")
        static let switchToSignUp = String(
            localized: "account.switchToSignUp",
            defaultValue: "¿Primera vez? Crea una cuenta"
        )
        static let switchToSignIn = String(
            localized: "account.switchToSignIn",
            defaultValue: "Ya tengo una cuenta"
        )
        static let signOut = String(localized: "account.signOut", defaultValue: "Cerrar sesión")
        static let developmentMode = String(
            localized: "account.developmentMode",
            defaultValue: "Modo local de desarrollo"
        )
        static let invalidCredentials = String(
            localized: "account.invalidCredentials",
            defaultValue: "Usa un correo válido y una contraseña de al menos 6 caracteres."
        )
        static let accountAlreadyExists = String(
            localized: "account.accountAlreadyExists",
            defaultValue: "Ya existe una cuenta local en este dispositivo."
        )
        static let networkUnavailable = String(
            localized: "account.networkUnavailable",
            defaultValue: "No se pudo conectar con el backend."
        )
        static let backendNotConfigured = String(
            localized: "account.backendNotConfigured",
            defaultValue: "El backend todavía no está configurado."
        )
        static let invalidResponse = String(
            localized: "account.invalidResponse",
            defaultValue: "El backend devolvió una respuesta no válida."
        )
        static let legal = String(localized: "account.legal", defaultValue: "Privacidad y cuenta")
        static let deleteAccount = String(localized: "account.deleteAccount", defaultValue: "Eliminar cuenta")
        static let deleteAccountMessage = String(
            localized: "account.deleteAccountMessage",
            defaultValue: "Esta acción elimina tu cuenta y tus datos asociados. No se puede deshacer."
        )
        static let confirmDelete = String(localized: "account.confirmDelete", defaultValue: "Eliminar definitivamente")
        static let cancel = String(localized: "account.cancel", defaultValue: "Cancelar")
        static let terms = String(localized: "account.terms", defaultValue: "Términos de uso")
        static let privacy = String(localized: "account.privacy", defaultValue: "Política de privacidad")
        static let legalBody = String(
            localized: "account.legalBody",
            // swiftlint:disable:next line_length
            defaultValue: "Prep4Job procesa tu cuenta, progreso de estudio y solicitudes de IA para ofrecer la experiencia de preparación. Puedes solicitar la eliminación de tu cuenta en cualquier momento."
        )
        static let termsBody = String(
            localized: "account.termsBody",
            // swiftlint:disable:next line_length
            defaultValue: "Usa Prep4Job de forma responsable. El contenido generado por IA es educativo y debe revisarse antes de usarlo en una entrevista."
        )
    }

    nonisolated enum Subscription {
        static let title = String(localized: "subscription.title", defaultValue: "Prep4Job Premium")
        static let subtitle = String(
            localized: "subscription.subtitle",
            defaultValue: "Aprende con más profundidad y mantén tu progreso sincronizado."
        )
        static let premiumActive = String(
            localized: "subscription.premiumActive",
            defaultValue: "Premium activo"
        )
        static let freePlan = String(localized: "subscription.freePlan", defaultValue: "Plan gratuito")
        static let monthly = String(localized: "subscription.monthly", defaultValue: "Premium mensual")
        static let yearly = String(localized: "subscription.yearly", defaultValue: "Premium anual")
        static let monthlyPeriod = String(localized: "subscription.monthlyPeriod", defaultValue: "por mes")
        static let yearlyPeriod = String(localized: "subscription.yearlyPeriod", defaultValue: "por año")
        static let dailyPeriod = String(localized: "subscription.dailyPeriod", defaultValue: "diario")
        static let weeklyPeriod = String(localized: "subscription.weeklyPeriod", defaultValue: "semanal")
        static let restore = String(localized: "subscription.restore", defaultValue: "Restaurar compras")
        static let productNotFound = String(
            localized: "subscription.productNotFound",
            defaultValue: "Producto Premium no disponible."
        )
        static let purchasePending = String(
            localized: "subscription.purchasePending",
            defaultValue: "La compra está pendiente de aprobación."
        )
        static let purchaseCancelled = String(
            localized: "subscription.purchaseCancelled",
            defaultValue: "La compra fue cancelada."
        )
        static let unverifiedTransaction = String(
            localized: "subscription.unverifiedTransaction",
            defaultValue: "No se pudo verificar la transacción."
        )
        static let storeUnavailable = String(
            localized: "subscription.storeUnavailable",
            defaultValue: "La tienda no está disponible en este momento."
        )
    }

    nonisolated enum Concepts {
        static let star = String(localized: "concept.star.title", defaultValue: "Método STAR")
        static let starSubtitle = String(
            localized: "concept.star.subtitle",
            defaultValue: "Convierte experiencias en respuestas claras y memorables."
        )
        static let starExplanation = String(
            localized: "concept.star.explanation",
            // swiftlint:disable:next line_length
            defaultValue: "El método STAR te ayuda a organizar una respuesta contando una experiencia real de forma lógica y completa."
        )
        static let situation = String(localized: "concept.star.situation", defaultValue: "Situación")
        static let situationDetail = String(
            localized: "concept.star.situationDetail",
            defaultValue: "Contexto. ¿Qué estaba pasando?"
        )
        static let task = String(localized: "concept.star.task", defaultValue: "Tarea")
        static let taskDetail = String(
            localized: "concept.star.taskDetail",
            defaultValue: "Tu responsabilidad. ¿Qué necesitabas lograr?"
        )
        static let action = String(localized: "concept.star.action", defaultValue: "Acción")
        static let actionDetail = String(
            localized: "concept.star.actionDetail",
            defaultValue: "Qué hiciste. ¿Cómo lo hiciste?"
        )
        static let result = String(localized: "concept.star.result", defaultValue: "Resultado")
        static let resultDetail = String(
            localized: "concept.star.resultDetail",
            defaultValue: "El impacto. ¿Qué lograste?"
        )

        static let measurableImpact = String(
            localized: "concept.measurableImpact.title",
            defaultValue: "Impacto medible"
        )
        static let measurableImpactSubtitle = String(
            localized: "concept.measurableImpact.subtitle",
            defaultValue: "Haz que tu contribución sea fácil de recordar."
        )
        static let measurableImpactExplanation = String(
            localized: "concept.measurableImpact.explanation",
            // swiftlint:disable:next line_length
            defaultValue: "Un resultado concreto ayuda al entrevistador a entender el valor que aportaste, incluso cuando el proyecto fue colaborativo."
        )
        static let before = String(localized: "concept.measurableImpact.before", defaultValue: "Antes")
        static let beforeDetail = String(
            localized: "concept.measurableImpact.beforeDetail",
            defaultValue: "Define el problema o punto de partida."
        )
        static let change = String(localized: "concept.measurableImpact.change", defaultValue: "Cambio")
        static let changeDetail = String(
            localized: "concept.measurableImpact.changeDetail",
            defaultValue: "Explica qué decisión o acción impulsaste."
        )
        static let after = String(localized: "concept.measurableImpact.after", defaultValue: "Después")
        static let afterDetail = String(
            localized: "concept.measurableImpact.afterDetail",
            defaultValue: "Comparte el resultado con una métrica o evidencia."
        )

        static let structuredThinking = String(
            localized: "concept.structuredThinking.title",
            defaultValue: "Pensamiento estructurado"
        )
        static let structuredThinkingSubtitle = String(
            localized: "concept.structuredThinking.subtitle",
            defaultValue: "Responde problemas complejos sin perder claridad."
        )
        static let structuredThinkingExplanation = String(
            localized: "concept.structuredThinking.explanation",
            // swiftlint:disable:next line_length
            defaultValue: "Separar hechos, hipótesis y próximos pasos demuestra criterio y reduce respuestas improvisadas."
        )
        static let clarify = String(localized: "concept.structuredThinking.clarify", defaultValue: "Aclarar")
        static let clarifyDetail = String(
            localized: "concept.structuredThinking.clarifyDetail",
            defaultValue: "Confirma el objetivo y las restricciones."
        )
        static let divide = String(localized: "concept.structuredThinking.divide", defaultValue: "Dividir")
        static let divideDetail = String(
            localized: "concept.structuredThinking.divideDetail",
            defaultValue: "Separa el problema en partes manejables."
        )
        static let validate = String(localized: "concept.structuredThinking.validate", defaultValue: "Validar")
        static let validateDetail = String(
            localized: "concept.structuredThinking.validateDetail",
            defaultValue: "Prueba la hipótesis con evidencia."
        )

        static let communication = String(localized: "concept.communication.title", defaultValue: "Comunicación")
        static let communicationSubtitle = String(
            localized: "concept.communication.subtitle",
            defaultValue: "Haz visible tu razonamiento y tu colaboración."
        )
        static let communicationExplanation = String(
            localized: "concept.communication.explanation",
            defaultValue: "Una buena respuesta muestra cómo informas, escuchas y alineas al equipo para avanzar."
        )
        static let listen = String(localized: "concept.communication.listen", defaultValue: "Escuchar")
        static let listenDetail = String(
            localized: "concept.communication.listenDetail",
            defaultValue: "Entiende perspectivas y necesidades."
        )
        static let align = String(localized: "concept.communication.align", defaultValue: "Alinear")
        static let alignDetail = String(
            localized: "concept.communication.alignDetail",
            defaultValue: "Acuerda un objetivo común."
        )
        static let act = String(localized: "concept.communication.act", defaultValue: "Actuar")
        static let actDetail = String(
            localized: "concept.communication.actDetail",
            defaultValue: "Define el siguiente paso y comunícalo."
        )
    }

    nonisolated enum Questions {
        static let conflictTitle = String(
            localized: "question.conflict.title",
            defaultValue: "Háblame de una ocasión en la que resolviste un conflicto en tu equipo."
        )
        static let behavioral = String(localized: "question.behavioral", defaultValue: "Conductual")
        static let conflictPurpose = String(
            localized: "question.conflict.purpose",
            defaultValue: "Evalúa liderazgo, comunicación y manejo de situaciones desafiantes."
        )
        static let conflictTip = String(
            localized: "question.conflict.tip",
            // swiftlint:disable:next line_length
            defaultValue: "Piensa en una situación real, el rol que tomaste, las acciones que realizaste y el resultado obtenido."
        )
        static let conflictAnswer = String(
            localized: "question.conflict.answer",
            // swiftlint:disable:next line_length
            defaultValue: "En mi anterior trabajo surgió un conflicto entre dos miembros del equipo por diferencias en la forma de abordar un proyecto clave. Organicé una reunión para que pudieran expresar sus puntos de vista, facilité la conversación y propuse un plan de trabajo con objetivos comunes. Como resultado, mejoró la colaboración del equipo y entregamos el proyecto a tiempo, superando las expectativas del cliente."
        )
        static let leadership = String(localized: "question.leadership", defaultValue: "Liderazgo")
        static let conflictResolution = String(
            localized: "question.conflictResolution",
            defaultValue: "Resolución de conflictos"
        )

        static let proudProjectTitle = String(
            localized: "question.proudProject.title",
            defaultValue: "Cuéntame sobre un proyecto del que te sientas especialmente orgulloso."
        )
        static let experience = String(localized: "question.experience", defaultValue: "Experiencia")
        static let proudProjectPurpose = String(
            localized: "question.proudProject.purpose",
            defaultValue: "Busca evidencias concretas de impacto, criterio y capacidad de ejecución."
        )
        static let proudProjectTip = String(
            localized: "question.proudProject.tip",
            defaultValue: "Incluye el problema inicial, tu contribución específica y una métrica de resultado."
        )
        static let proudProjectAnswer = String(
            localized: "question.proudProject.answer",
            // swiftlint:disable:next line_length
            defaultValue: "Lideré la mejora del flujo de registro de usuarios, reduciendo pasos y simplificando la validación. Trabajé con diseño y backend para priorizar los cambios, y medimos el resultado con una prueba controlada. El abandono del flujo disminuyó un 18% durante el primer mes."
        )
        static let measurableImpact = String(localized: "question.measurableImpact", defaultValue: "Impacto medible")
        static let prioritization = String(localized: "question.prioritization", defaultValue: "Priorización")
        static let collaboration = String(localized: "question.collaboration", defaultValue: "Colaboración")

        static let technicalProblemTitle = String(
            localized: "question.technicalProblem.title",
            defaultValue: "¿Qué haces cuando no conoces la respuesta a un problema técnico?"
        )
        static let problemSolving = String(
            localized: "question.problemSolving",
            defaultValue: "Resolución de problemas"
        )
        static let technicalProblemPurpose = String(
            localized: "question.technicalProblem.purpose",
            defaultValue: "Evalúa aprendizaje, autonomía y comunicación bajo incertidumbre."
        )
        static let technicalProblemTip = String(
            localized: "question.technicalProblem.tip",
            defaultValue: "Describe cómo divides el problema, investigas y haces visible el progreso."
        )
        static let technicalProblemAnswer = String(
            localized: "question.technicalProblem.answer",
            // swiftlint:disable:next line_length
            defaultValue: "Primero defino qué parte del problema está confirmada y cuál es la incógnita. Después consulto documentación primaria, preparo una prueba pequeña y comparto mis hipótesis con el equipo. Así evito investigar sin dirección y puedo pedir ayuda con una pregunta concreta."
        )
        static let structuredThinking = String(
            localized: "question.structuredThinking",
            defaultValue: "Pensamiento estructurado"
        )
        static let continuousLearning = String(
            localized: "question.continuousLearning",
            defaultValue: "Aprendizaje continuo"
        )
    }
}

// swiftlint:enable type_body_length
