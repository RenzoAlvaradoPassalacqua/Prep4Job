alter table public.interview_questions
  add column if not exists purpose text not null default '',
  add column if not exists tip text not null default '';

update public.interview_questions set
  purpose = 'Evalúa liderazgo, comunicación y manejo de situaciones desafiantes.',
  tip = 'Piensa en una situación real, el rol que tomaste, las acciones que realizaste y el resultado obtenido.'
where id = '20000000-0000-0000-0000-000000000001';

update public.interview_questions set
  purpose = 'Busca evidencias concretas de impacto, criterio y capacidad de ejecución.',
  tip = 'Incluye el problema inicial, tu contribución específica y una métrica de resultado.'
where id = '20000000-0000-0000-0000-000000000002';

update public.interview_questions set
  purpose = 'Evalúa aprendizaje, autonomía y comunicación bajo incertidumbre.',
  tip = 'Describe cómo divides el problema, investigas y haces visible el progreso.'
where id = '20000000-0000-0000-0000-000000000003';

update public.interview_questions set
  purpose = 'Evalúa colaboración, influencia y capacidad de alinear al equipo.',
  tip = 'Explica cómo construiste confianza y llegaste a un acuerdo sin imponer tu solución.'
where id = '20000000-0000-0000-0000-000000000004';

update public.interview_questions set
  purpose = 'Evalúa criterio técnico y capacidad de diseñar sistemas mantenibles.',
  tip = 'Explica límites de responsabilidad, dependencias y cómo probarías cada capa.'
where id = '20000000-0000-0000-0000-000000000005';

update public.interview_questions set
  purpose = 'Evalúa dominio de concurrencia y composición de flujos asíncronos.',
  tip = 'Compara los casos de uso y menciona cancelación, aislamiento y manejo de errores.'
where id = '20000000-0000-0000-0000-000000000006';

update public.interview_questions set
  purpose = 'Evalúa capacidad de diagnosticar y mejorar una app con datos.',
  tip = 'Mide antes de optimizar y valida cada cambio con Instruments o métricas reales.'
where id = '20000000-0000-0000-0000-000000000007';

update public.interview_questions set
  purpose = 'Evalúa disciplina de calidad y preparación para producción.',
  tip = 'Relaciona cada nivel de prueba con el riesgo que reduce y el flujo que protege.'
where id = '20000000-0000-0000-0000-000000000008';

update public.interview_questions set
  purpose = 'Evalúa responsabilidad, madurez y aprendizaje continuo.',
  tip = 'Cuenta qué cambiaste en el proceso para evitar que el error se repitiera.'
where id = '20000000-0000-0000-0000-000000000009';

update public.interview_questions set
  purpose = 'Evalúa criterio de producto y capacidad de tomar decisiones.',
  tip = 'Explica cómo comparas impacto, esfuerzo, riesgo y dependencias.'
where id = '20000000-0000-0000-0000-000000000010';
