-- 1. Spatial join: listings to counties
WITH county AS (
  SELECT geoid, geom
  FROM ref.county_boundaries)
SELECT c.geoid,
       COUNT(*) AS listing_ct
FROM raw.airbnb_listings l
JOIN county c
  ON ST_Contains(c.geom, l.geom)
GROUP BY c.geoid;

-- 2. Windowed aggregations
SELECT geoid,
       SUM(nights_booked) OVER (PARTITION BY geoid) AS nights_total
FROM fact.booking_stats;

-- 3. Incremental ETL pattern
INSERT INTO dw.dim_host (_dt, host_id, is_superhost, country)
SELECT CURRENT_DATE, host_id, is_superhost, country
FROM staging.hosts_new
WHERE ingestion_ts > (SELECT MAX(_dt) FROM dw.dim_host);
