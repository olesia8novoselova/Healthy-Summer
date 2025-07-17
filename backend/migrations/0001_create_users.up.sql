CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name         TEXT NOT NULL,
  email        TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  avatar_url   TEXT,
  weight NUMERIC,
  height NUMERIC
);

CREATE TABLE achievements (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title       TEXT NOT NULL,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_achievements (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  unlocked_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  --challenge_id UUID
);
CREATE TABLE IF NOT EXISTS friend_requests (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS friends (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TYPE activity_type AS ENUM ('running', 'swimming', 'cycling', 'yoga');

CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  type activity_type NOT NULL,
  name TEXT NOT NULL,       -- custom name from user
  duration INT,
  intensity TEXT,
  calories INT,
  location TEXT,
  performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_steps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  steps INT NOT NULL,
  day DATE NOT NULL,   -- Store as date for daily stats
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, day)
);

CREATE TABLE meals (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id),
  fdc_id integer,
  description text,
  calories double precision,
  protein double precision,
  fat double precision,
  carbs double precision,
  quantity double precision,
  unit text,
  created_at timestamptz DEFAULT NOW()
);

CREATE TABLE water_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  amount_ml INT NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE water_goals (
  user_id UUID PRIMARY KEY,
  goal_ml INT NOT NULL DEFAULT 2000,
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE calorie_goals (
  user_id UUID PRIMARY KEY,
  goal INT NOT NULL DEFAULT 2000,
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE step_goals (
  user_id UUID PRIMARY KEY,
  goal INT NOT NULL DEFAULT 10000,
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE activity_goals (
  user_id UUID PRIMARY KEY,
  goal INT NOT NULL DEFAULT 500,
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE post_activities (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    type TEXT NOT NULL,
    message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE messages (
  id UUID PRIMARY KEY,
  sender_id UUID NOT NULL REFERENCES users(id),
  receiver_id UUID NOT NULL REFERENCES users(id),
  text TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE challenges (
  id           UUID PRIMARY KEY,
  creator_id   UUID NOT NULL REFERENCES users(id),
  type         VARCHAR(32)  NOT NULL CHECK (type IN ('steps','workouts','calories')),
  target       INT          NOT NULL,                 -- steps / workouts / kcal
  title        TEXT         NOT NULL,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE challenge_participants (
  challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES users(id)     ON DELETE CASCADE,
  progress     INT  NOT NULL DEFAULT 0,
  joined_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (challenge_id, user_id)
);
CREATE INDEX ON challenge_participants (user_id);

ALTER TABLE user_achievements
  ADD COLUMN IF NOT EXISTS challenge_id UUID;

CREATE UNIQUE INDEX IF NOT EXISTS ua_unique
ON user_achievements (user_id, achievement_id, challenge_id);

CREATE TABLE workout_schedules (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  weekday     INT  NOT NULL,          -- 0 = Monday … 6 = Sunday
  at_time     TIME NOT NULL,          -- 24-h HH:MM:SS
  title       TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE hydration_settings (
  user_id   UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  interval  INT  NOT NULL DEFAULT 7 -- minutes
);
