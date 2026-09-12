alter table public.progress_items
  add column if not exists saved_answer text not null default '';
