SELECT
  v.id,
  v.name,
  v.address,
  v.avg_rating,
  v.review_count,
  ROUND(
    ST_Distance(
      v.location::geography,
      ST_SetSRID(ST_MakePoint(15.9775, 45.8130), 4326)::geography
    )
  ) AS distance_m
FROM v_place_overview v
WHERE ST_DWithin(
  v.location::geography,
  ST_SetSRID(ST_MakePoint(15.9775, 45.8130), 4326)::geography,
  2000
)
ORDER BY v.avg_rating DESC NULLS LAST, v.review_count DESC, distance_m ASC
LIMIT 5;

SELECT
  v.name,
  v.avg_rating,
  v.review_count,
  (v.meta->>'price_level')::int AS price_level,
  ROUND(
    ST_Distance(
      v.location::geography,
      ST_SetSRID(ST_MakePoint(15.9775, 45.8130), 4326)::geography
    )
  ) AS distance_m
FROM v_place_overview v
WHERE
  ST_DWithin(
    v.location::geography,
    ST_SetSRID(ST_MakePoint(15.9775, 45.8130), 4326)::geography,
    2000
  )
  AND (v.meta->>'wifi')::boolean = true
  AND (v.meta->>'price_level')::int <= 2
ORDER BY v.avg_rating DESC NULLS LAST, v.review_count DESC, distance_m ASC;

SELECT
  name,
  meta->'cuisine' AS cuisine,
  meta->>'takeaway' AS takeaway,
  avg_rating,
  review_count
FROM v_place_overview
WHERE
  meta->'cuisine' ? 'italian'
  AND (meta->>'takeaway')::boolean = true
ORDER BY avg_rating DESC NULLS LAST, review_count DESC;

SELECT
  p.id,
  p.name,
  COUNT(r.id) AS reviews_last_30d,
  ROUND(AVG(r.rating)::numeric, 2) AS avg_rating_last_30d
FROM places p
JOIN reviews r ON r.place_id = p.id
WHERE r.visited_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.id, p.name
HAVING COUNT(r.id) >= 1
ORDER BY reviews_last_30d DESC, avg_rating_last_30d DESC
LIMIT 10;

SELECT
  v.name,
  v.avg_rating,
  v.review_count,
  (v.meta->>'pets_allowed')::boolean AS pets_allowed,
  (v.meta->>'parking')::boolean AS parking,
  ROUND(
    ST_Distance(
      v.location::geography,
      ST_SetSRID(ST_MakePoint(15.9775, 45.8130), 4326)::geography
    )
  ) AS distance_m
FROM v_place_overview v
WHERE
  ST_DWithin(
    v.location::geography,
    ST_SetSRID(ST_MakePoint(15.9775, 45.8130), 4326)::geography,
    2500
  )
  AND (v.meta->>'pets_allowed')::boolean = true
  AND (v.meta->>'parking')::boolean = true
ORDER BY distance_m ASC, v.avg_rating DESC NULLS LAST;

SELECT
  id, name, address, avg_rating, review_count
FROM v_place_overview
WHERE review_count = 0
ORDER BY created_at DESC;

SELECT
  v.name,
  v.avg_rating,
  v.review_count,
  ROUND(
    ST_Distance(
      v.location::geography,
      ST_SetSRID(ST_MakePoint(15.9775, 45.8130), 4326)::geography
    ) / 1000.0
  , 2) AS distance_km,
  ROUND(
    (v.avg_rating / (1 + (ST_Distance(
      v.location::geography,
      ST_SetSRID(ST_MakePoint(15.9775, 45.8130), 4326)::geography
    ) / 1000.0)))::numeric
  , 3) AS score
FROM v_place_overview v
WHERE
  v.review_count >= 1
  AND ST_DWithin(
    v.location::geography,
    ST_SetSRID(ST_MakePoint(15.9775, 45.8130), 4326)::geography,
    3000
  )
ORDER BY score DESC
LIMIT 10;
