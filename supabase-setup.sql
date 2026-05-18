-- ============================================
-- MUNDIAL FAMILIAR 2026 - Setup de Supabase
-- Copia y pega esto en el SQL Editor de Supabase
-- ============================================

-- 1. Tabla de perfiles (usuarios)
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text,
  created_at timestamptz default now()
);

-- 2. Tabla de partidos (caché de API-Football)
create table if not exists matches (
  id integer primary key,
  date timestamptz,
  team1 text not null,
  team2 text not null,
  team1_flag text,
  team2_flag text,
  group_name text,
  status text default 'NS',
  goals1 integer,
  goals2 integer,
  venue text,
  updated_at timestamptz default now()
);

-- 3. Tabla de pronósticos
create table if not exists predictions (
  id uuid primary key default gen_random_uuid(),
  match_id integer references matches(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  prediction text not null check (prediction in ('local','empate','visitante')),
  created_at timestamptz default now(),
  unique(match_id, user_id)
);

-- ============================================
-- SEGURIDAD (Row Level Security)
-- ============================================

alter table profiles enable row level security;
alter table matches enable row level security;
alter table predictions enable row level security;

-- Profiles: cada quien ve todos los perfiles (para la tabla de posiciones)
create policy "Todos pueden ver perfiles" on profiles for select using (true);
create policy "Solo tú puedes crear tu perfil" on profiles for insert with check (auth.uid() = id);
create policy "Solo tú puedes editar tu perfil" on profiles for update using (auth.uid() = id);

-- Matches: todos pueden ver, solo el sistema inserta
create policy "Todos pueden ver partidos" on matches for select using (true);
create policy "Usuarios autenticados pueden insertar partidos" on matches for insert with check (auth.role() = 'authenticated');
create policy "Usuarios autenticados pueden actualizar partidos" on matches for update using (auth.role() = 'authenticated');

-- Predictions: todos pueden ver, cada quien gestiona las suyas
create policy "Todos pueden ver pronósticos" on predictions for select using (true);
create policy "Solo tú puedes crear tus pronósticos" on predictions for insert with check (auth.uid() = user_id);
create policy "Solo tú puedes borrar tus pronósticos" on predictions for delete using (auth.uid() = user_id);
