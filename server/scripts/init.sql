-- Players table (stores Roblox users)
CREATE TABLE IF NOT EXISTS public.players (
  id BIGSERIAL PRIMARY KEY,        -- Unique internal ID
  user_id BIGINT NOT NULL UNIQUE,   -- Roblox user ID
  created_at TIMESTAMPTZ DEFAULT NOW(),  -- When this player record was created
  rating BIGINT NOT NULL DEFAULT 0,      -- Player's current rating
  accuracy BIGINT NOT NULL DEFAULT 0,    -- Player's average accuracy
  play_count BIGINT NOT NULL DEFAULT 0,   -- Total number of plays
  name TEXT NOT NULL,                     -- Player's cached username
  allowed BOOLEAN NOT NULL DEFAULT TRUE   -- Whether the player is allowed (banned flag?)
);

-- Scores table (one entry per playthrough)
CREATE TABLE IF NOT EXISTS public.scores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  player_id BIGINT REFERENCES public.players(id) ON DELETE CASCADE,
  hash TEXT NOT NULL,
  score INT NOT NULL DEFAULT 0,
  accuracy FLOAT NOT NULL DEFAULT 100,
  combo INT NOT NULL DEFAULT 0,
  max_combo INT NOT NULL DEFAULT 0,
  marvelous INT NOT NULL DEFAULT 0,
  perfect INT NOT NULL DEFAULT 0,
  great INT NOT NULL DEFAULT 0,
  good INT NOT NULL DEFAULT 0,
  bad INT NOT NULL DEFAULT 0,
  miss INT NOT NULL DEFAULT 0,
  grade TEXT NOT NULL DEFAULT 'F',
  rating FLOAT NOT NULL DEFAULT 0,
  mean FLOAT NOT NULL DEFAULT 0, -- Optional mean value for the score
  created_at TIMESTAMP DEFAULT NOW(),
  rate INT NOT NULL DEFAULT 100
);

-- Index for fast leaderboard queries per song
CREATE INDEX IF NOT EXISTS idx_scores_song_score
  ON public.scores (hash, rating DESC);
