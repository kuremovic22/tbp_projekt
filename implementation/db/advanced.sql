BEGIN;

CREATE TABLE IF NOT EXISTS place_stats (
  place_id      BIGINT PRIMARY KEY REFERENCES places(id) ON DELETE CASCADE,
  avg_rating    NUMERIC(3,2) NOT NULL DEFAULT 0,
  review_count  INT NOT NULL DEFAULT 0,
  last_review_at TIMESTAMP
);

CREATE OR REPLACE FUNCTION recompute_place_stats(p_place_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_avg NUMERIC(3,2);
  v_cnt INT;
  v_last TIMESTAMP;
BEGIN
  SELECT
    COALESCE(ROUND(AVG(rating)::numeric, 2), 0),
    COUNT(*),
    MAX(created_at)
  INTO v_avg, v_cnt, v_last
  FROM reviews
  WHERE place_id = p_place_id;

  INSERT INTO place_stats(place_id, avg_rating, review_count, last_review_at)
  VALUES (p_place_id, v_avg, v_cnt, v_last)
  ON CONFLICT (place_id)
  DO UPDATE SET
    avg_rating = EXCLUDED.avg_rating,
    review_count = EXCLUDED.review_count,
    last_review_at = EXCLUDED.last_review_at;
END;
$$;

CREATE OR REPLACE FUNCTION trg_reviews_recompute_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM recompute_place_stats(NEW.place_id);
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.place_id <> OLD.place_id THEN
      PERFORM recompute_place_stats(OLD.place_id);
    END IF;
    PERFORM recompute_place_stats(NEW.place_id);
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM recompute_place_stats(OLD.place_id);
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS reviews_recompute_stats ON reviews;

CREATE TRIGGER reviews_recompute_stats
AFTER INSERT OR UPDATE OR DELETE ON reviews
FOR EACH ROW
EXECUTE FUNCTION trg_reviews_recompute_stats();

INSERT INTO place_stats(place_id, avg_rating, review_count, last_review_at)
SELECT
  p.id,
  COALESCE(ROUND(AVG(r.rating)::numeric, 2), 0) AS avg_rating,
  COALESCE(COUNT(r.id), 0) AS review_count,
  MAX(r.created_at) AS last_review_at
FROM places p
LEFT JOIN reviews r ON r.place_id = p.id
GROUP BY p.id
ON CONFLICT (place_id)
DO UPDATE SET
  avg_rating = EXCLUDED.avg_rating,
  review_count = EXCLUDED.review_count,
  last_review_at = EXCLUDED.last_review_at;

CREATE OR REPLACE VIEW v_place_overview AS
SELECT
  p.id,
  p.name,
  p.address,
  p.description,
  p.created_at,
  ps.avg_rating,
  ps.review_count,
  ps.last_review_at,
  p.meta,
  p.location
FROM places p
LEFT JOIN place_stats ps ON ps.place_id = p.id;

COMMIT;
