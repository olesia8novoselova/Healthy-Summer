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
