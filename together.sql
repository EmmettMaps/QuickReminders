/* 1 ── every user‑product combination only once */
WITH user_products AS (
    SELECT DISTINCT user_id, product_id
    FROM   transactions
),

/* 2 ── build unordered pairs inside each user’s basket
        (product_id < product_id avoids self‑pair and duplicates) */
pair_counts AS (
    SELECT
        LEAST(up1.product_id, up2.product_id)  AS prod_lo,
        GREATEST(up1.product_id, up2.product_id) AS prod_hi,
        COUNT(*)  AS qty
    FROM   user_products up1
    JOIN   user_products up2
           ON up1.user_id = up2.user_id
          AND up1.product_id < up2.product_id
    GROUP  BY prod_lo, prod_hi
),

/* 3 ── attach names and enforce alphabetical order for p1 / p2 */
named_pairs AS (
    SELECT
        CASE WHEN p_lo.name < p_hi.name THEN p_hi.name ELSE p_lo.name END AS p1,
        CASE WHEN p_lo.name < p_hi.name THEN p_lo.name ELSE p_hi.name END AS p2,
        pc.qty
    FROM   pair_counts pc
    JOIN   products p_lo ON pc.prod_lo = p_lo.id
    JOIN   products p_hi ON pc.prod_hi = p_hi.id
)

SELECT  p1, p2, qty
FROM    named_pairs
ORDER BY qty DESC
LIMIT   5;
