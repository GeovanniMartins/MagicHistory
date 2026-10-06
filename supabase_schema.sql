-- ==============================================================================
-- SOUNDKID - SCHEMA COMPLETO DO SUPABASE (BANCO DE DADOS & STORAGE)
-- ==============================================================================

-- 1. TABELA PRINCIPAL DE EFEITOS SONOROS E MÚSICAS DE AMBIÊNCIA
CREATE TABLE IF NOT EXISTS public.sound_effects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,                          -- Nome do efeito (ex: "Rugido do Monstro", "Chuva Suave")
    keywords TEXT[] NOT NULL DEFAULT '{}',       -- Array de palavras-chave ex: ['monstro', 'rugiu', 'bravo']
    audio_url TEXT NOT NULL,                     -- URL pública do áudio gravado/enviado no Storage
    video_url TEXT,                              -- URL pública de vídeo curto associado (opcional)
    cooldown_seconds INTEGER DEFAULT 3,          -- Tempo de pausa em segundos
    is_custom BOOLEAN DEFAULT true,              -- Identifica se foi criado pelo usuário
    sound_type TEXT DEFAULT 'effect',            -- 'effect' (disparo pontual por voz) ou 'ambient' (trilha em loop)
    volume FLOAT DEFAULT 1.0,                    -- Volume individual do som (0.0 a 1.0)
    theme_color TEXT DEFAULT '#8C62FF',          -- Cor temática do efeito visual em Hex
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar RLS e Políticas de Acesso
ALTER TABLE public.sound_effects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir leitura pública dos efeitos sonoros" 
ON public.sound_effects FOR SELECT 
USING (true);

CREATE POLICY "Permitir inserção de novos efeitos sonoros" 
ON public.sound_effects FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Permitir atualização de efeitos sonoros" 
ON public.sound_effects FOR UPDATE 
USING (true);

CREATE POLICY "Permitir exclusão de efeitos sonoros" 
ON public.sound_effects FOR DELETE 
USING (true);


-- 2. TABELA DE HISTÓRIAS / LIVROS (PRESETS)
CREATE TABLE IF NOT EXISTS public.stories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,                         -- Ex: "A Floresta Encantada", "Viagem ao Espaço"
    description TEXT,
    ambient_sound_id TEXT,                       -- ID do som ambiente associado a esta história
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar RLS e Políticas de Acesso
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir leitura pública das histórias" 
ON public.stories FOR SELECT 
USING (true);

CREATE POLICY "Permitir inserção de histórias" 
ON public.stories FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Permitir atualização de histórias" 
ON public.stories FOR UPDATE 
USING (true);

CREATE POLICY "Permitir exclusão de histórias" 
ON public.stories FOR DELETE 
USING (true);


-- 3. TABELA DE RELACIONAMENTO ENTRE HISTÓRIAS E SONS
CREATE TABLE IF NOT EXISTS public.story_sounds (
    story_id UUID REFERENCES public.stories(id) ON DELETE CASCADE,
    sound_id TEXT NOT NULL,
    PRIMARY KEY (story_id, sound_id)
);

ALTER TABLE public.story_sounds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir leitura da relação história/som" 
ON public.story_sounds FOR SELECT 
USING (true);

CREATE POLICY "Permitir inserção da relação história/som" 
ON public.story_sounds FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Permitir exclusão da relação história/som" 
ON public.story_sounds FOR DELETE 
USING (true);


-- ==============================================================================
-- BUCKETS DE STORAGE DO SUPABASE:
-- Certifique-se de criar 2 buckets no menu Storage do Supabase:
-- 1. 'sound_effects' (Public Bucket) -> Para arquivos de áudio (.mp3, .m4a, .wav)
-- 2. 'video_effects' (Public Bucket) -> Para vídeos curtos (.mp4, .webm, .mov)
-- ==============================================================================

