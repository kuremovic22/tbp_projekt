BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS users (
  id            BIGSERIAL PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  created_at    TIMESTAMP    NOT NULL DEFAULT now()
);


CREATE TABLE IF NOT EXISTS places (
  id          BIGSERIAL PRIMARY KEY,
  name        VARCHAR(200) NOT NULL,
  address     VARCHAR(300) NOT NULL,
  description TEXT,
  location    geometry(Point, 4326) NOT NULL,
  meta        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMP NOT NULL DEFAULT now(),
  CONSTRAINT places_location_srid_chk CHECK (ST_SRID(location) = 4326)
);

CREATE TABLE IF NOT EXISTS reviews (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  place_id   BIGINT NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  rating     INT    NOT NULL,
  comment    TEXT,
  visited_at DATE   NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  CONSTRAINT reviews_rating_chk CHECK (rating BETWEEN 1 AND 5)
);

CREATE INDEX IF NOT EXISTS idx_places_location_gist
  ON places USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_places_meta_gin
  ON places USING GIN (meta);

CREATE INDEX IF NOT EXISTS idx_reviews_place_id ON reviews(place_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id  ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_visited_at ON reviews(visited_at);

COMMIT;
