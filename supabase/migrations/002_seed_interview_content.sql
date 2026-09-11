-- Banco inicial de Prep4Job. Idempotente para poder ejecutarse de forma segura.
insert into public.interview_questions (id, category, question, answer, concepts, is_premium)
values
('20000000-0000-0000-0000-000000000001', 'Conductual', 'Háblame de un conflicto con un compañero y cómo lo resolviste.', 'Usaría STAR: describiría el contexto sin culpar a nadie, explicaría mi responsabilidad, detallaría la conversación y los acuerdos alcanzados, y cerraría con el resultado medible y el aprendizaje.', array['STAR', 'Comunicación', 'Resolución de conflictos'], false),
('20000000-0000-0000-0000-000000000002', 'Experiencia', '¿Cuál es el proyecto del que te sientes más orgulloso?', 'Presentaría el problema, mi contribución específica, las decisiones técnicas relevantes y el impacto obtenido. Cuantificaría el resultado y explicaría qué haría diferente hoy.', array['Impacto medible', 'Ownership', 'Priorización'], false),
('20000000-0000-0000-0000-000000000003', 'Resolución de problemas', 'Cuéntame sobre un problema técnico difícil que hayas resuelto.', 'Explicaría cómo aislé el problema, qué hipótesis validé, las alternativas consideradas, la solución aplicada y cómo evité que volviera a ocurrir mediante pruebas o monitoreo.', array['Pensamiento estructurado', 'Debugging', 'Aprendizaje continuo'], false),
('20000000-0000-0000-0000-000000000004', 'Liderazgo', 'Describe una ocasión en la que tuviste que influir sin autoridad formal.', 'Aclararía el objetivo común, escucharía las restricciones de cada persona, presentaría datos y propondría un experimento pequeño. Finalmente mostraría cómo medimos y comunicamos el resultado.', array['Influencia', 'Colaboración', 'Comunicación'], false),
('20000000-0000-0000-0000-000000000005', 'iOS', '¿Cómo diseñarías la arquitectura de una app iOS nueva?', 'Comenzaría por los casos de uso y límites de dominio. Separaría presentación, dominio y datos, definiría protocolos para invertir dependencias y elegiría SwiftUI, async/await y una estrategia clara de persistencia y testing.', array['Clean Architecture', 'SOLID', 'Concurrencia'], true),
('20000000-0000-0000-0000-000000000006', 'iOS', '¿Cuándo usarías async/await, Combine o ambos?', 'Usaría async/await para operaciones puntuales y flujos estructurados. Combine es útil para streams de eventos y composición reactiva. Evitaría duplicar capas y definiría una frontera clara entre publishers y async sequences.', array['Concurrencia', 'Combine', 'Diseño de APIs'], true),
('20000000-0000-0000-0000-000000000007', 'iOS', '¿Cómo mejorarías el rendimiento de una app que se siente lenta?', 'Mediría primero con Instruments y métricas de producción. Revisaría trabajo en el hilo principal, imágenes, consultas, listas y consumo de memoria; aplicaría cambios pequeños y comprobaría cada mejora con datos.', array['Performance', 'Instruments', 'Observabilidad'], true),
('20000000-0000-0000-0000-000000000008', 'Calidad', '¿Cómo aseguras la calidad de una funcionalidad antes de publicarla?', 'Combinaría tests unitarios de dominio, tests de integración para datos y pruebas de UI para los flujos críticos. Añadiría revisión de código, CI, logs y un plan de rollback o feature flag.', array['Testing', 'CI/CD', 'Observabilidad'], false),
('20000000-0000-0000-0000-000000000009', 'Conductual', 'Háblame de un error que cometiste y qué aprendiste.', 'Explicaría el impacto con transparencia, las acciones inmediatas para contenerlo y el cambio de proceso que evitó repetirlo. Enfatizaría el aprendizaje sin buscar culpables.', array['Responsabilidad', 'Aprendizaje continuo', 'Comunicación'], false),
('20000000-0000-0000-0000-000000000010', 'Experiencia', '¿Cómo decides qué hacer cuando tienes varias prioridades?', 'Alinearía las tareas con el objetivo del producto, estimaría impacto y esfuerzo, haría visibles las dependencias y renegociaría prioridades con datos cuando el contexto cambie.', array['Priorización', 'Impacto medible', 'Ownership'], false)
on conflict (id) do update set
  category = excluded.category,
  question = excluded.question,
  answer = excluded.answer,
  concepts = excluded.concepts,
  is_premium = excluded.is_premium;

insert into public.learning_concepts (id, title, summary, detail, is_premium)
values
('30000000-0000-0000-0000-000000000001', 'STAR', 'Estructura respuestas conductuales con claridad.', 'Describe la Situación, la Tarea, la Acción concreta que realizaste y el Resultado medible.', false),
('30000000-0000-0000-0000-000000000002', 'Clean Architecture', 'Separa responsabilidades y protege el dominio.', 'Organiza la app en presentación, dominio y datos. El dominio no debe depender de frameworks ni detalles de infraestructura.', true),
('30000000-0000-0000-0000-000000000003', 'SOLID', 'Principios para diseñar código mantenible.', 'Aplica responsabilidad única, inversión de dependencias y contratos pequeños para reducir acoplamiento y facilitar pruebas.', true),
('30000000-0000-0000-0000-000000000004', 'Impacto medible', 'Conecta decisiones con resultados verificables.', 'Explica la línea base, el cambio que realizaste y la métrica que mejoró: conversión, estabilidad, tiempo, coste o satisfacción.', false),
('30000000-0000-0000-0000-000000000005', 'Concurrencia en Swift', 'Realiza trabajo asíncrono de forma segura.', 'Usa async/await, actores y cancelación cooperativa para evitar bloqueos, carreras y actualizaciones inconsistentes del estado.', true),
('30000000-0000-0000-0000-000000000006', 'Testing', 'Demuestra calidad antes y después del release.', 'Prioriza tests deterministas del dominio, contratos de datos y los recorridos de usuario que representan mayor riesgo.', false)
on conflict (id) do update set
  title = excluded.title,
  summary = excluded.summary,
  detail = excluded.detail,
  is_premium = excluded.is_premium;
