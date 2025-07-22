##Jupyter#######################
python -m venv env
source env/bin/activate          # Windows: env\Scripts\activate
pip install jupyterlab duckdb duckdb-engine geopandas pyrosm ipython-sql

###Notebook set up ####################
# notebook 00_setup.ipynb
%load_ext sql
%sql duckdb:///airbnb_demo.duckdb

# enable spatial functions once
%%sql
INSTALL spatial; LOAD spatial;

### lOAD A csv in ONE LINE AND RUN A QUERY##################

%%sql
CREATE TABLE listings AS
SELECT * FROM read_csv_auto('listings.csv', header=TRUE);

SELECT listing_id, COUNT(*) 
FROM listings 
GROUP BY 1 
LIMIT 5;

##Average vacant stays: #########################################

WITH listing_vacancies AS (
SELECT 
  listings.listing_id,
  365 - COALESCE(
    SUM(
      CASE WHEN checkout_date>'12/31/2021' THEN '12/31/2021' ELSE checkout_date END -
      CASE WHEN checkin_date<'01/01/2021' THEN '01/01/2021' ELSE checkin_date END 
  ),0) AS vacant_days
FROM listings 
LEFT JOIN bookings
  ON listings.listing_id = bookings.listing_id 
WHERE listings.is_active = 1
GROUP BY listings.listing_id)

SELECT ROUND(AVG(vacant_days)) 
FROM listing_vacancies;

## Average monthly listings #######################################
SELECT 
EXTRACT(MONTH from submit_date) as mth, 
listing_id, 
AVG(stars) as avg_stars
FROM 
reviews
GROUP BY 
mth, 
listing_id
ORDER BY 
listing_id, 
mth;

## Housing data and ranking in specific cities #########################################
SELECT l.listing_id, l.name, l.city, avg(r.stars) as average_rating
FROM listings l
JOIN reviews r ON l.listing_id = r.listing_id
WHERE l.city in ('San Francisco', 'New York') 
AND l.reviews_count >= 10
GROUP BY l.listing_id
HAVING avg(r.stars) >= 4.5;

## UNIQUE??? ######################
The UNIQUE constraint is used to ensure the uniqueness of the data in a column or set of columns in a table. It prevents the insertion of duplicate values in the specified column or columns and helps to ensure the integrity and reliability of the data in the database.
For example, say you were on the Marketing Analytics team at Airbnb and were doing some automated keyword research:

Your keyword database might store SEO data like this:

CREATE TABLE keywords (
    keyword_id INTEGER PRIMARY KEY,
    keyword VARCHAR(255) NOT NULL UNIQUE,
    search_volume INTEGER NOT NULL,
    competition FLOAT NOT NULL
);

## Guests per booking per city ################################################
SELECT p.city, AVG(b.guests) AS average_guests
FROM bookings b
JOIN properties p ON b.property_id = p.property_id
GROUP BY p.city;

## CTR which is bookings/listings ##############################################################
WITH total_views AS (
    SELECT 
        listing_id, 
        COUNT(*) AS view_count
    FROM
        listing_views
    WHERE
        DATE(visit_date) BETWEEN '2022‑07‑01' AND '2022‑07‑31'
    GROUP BY 
        listing_id
),
total_bookings AS (
    SELECT 
        listing_id, 
        COUNT(*) AS booking_count
    FROM
        bookings
    WHERE
        DATE(visit_date) BETWEEN '2022‑07‑01' AND '2022‑07‑31'
    GROUP BY 
        listing_id
)
SELECT 
    V.listing_id, 
    B.booking_count::decimal / NULLIF(V.view_count, 0) AS CTR
FROM 
    total_views V
LEFT JOIN 
    total_bookings B ON V.listing_id = B.listing_id;


### Most popular city ##################################
SELECT l.city, COUNT(b.booking_id) AS num_bookings
FROM bookings b
JOIN listings l ON b.listing_id = l.listing_id
GROUP BY l.city
ORDER BY num_bookings DESC
LIMIT 1;

## What is intersect###########################
Only shared rows from multiple selects! like: 

SELECT first_name, last_name
FROM airbnb_contractors

INTERSECT

SELECT first_name, last_name
FROM airbnb_employees

## Performance of hosts listings ##############################################
SELECT H.listing_id, H.listing_name, COUNT(B.booking_id) AS number_of_bookings 
FROM hosts H
LEFT JOIN bookings B ON H.listing_id = B.listing_id 
GROUP BY H.listing_id, H.listing_name 
ORDER BY number_of_bookings DESC 
LIMIT 10;




