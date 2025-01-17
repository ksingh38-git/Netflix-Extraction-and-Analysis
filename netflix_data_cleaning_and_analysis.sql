-- SQL File: netflix_data_analysis.sql

-- Remove duplicates based on 'show_id'
SELECT show_id, COUNT(*) 
FROM netflix_raw
GROUP BY show_id
HAVING COUNT(*) > 1;

-- Check for duplicates in 'title' and 'type'
SELECT * 
FROM netflix_raw 
WHERE CONCAT(UPPER(title), type) IN (
    SELECT CONCAT(UPPER(title), type) 
    FROM netflix_raw
    GROUP BY UPPER(title), type
    HAVING COUNT(*) > 1
)
ORDER BY title;

-- Remove duplicates while keeping only unique values
WITH cte AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY title, type ORDER BY show_id) AS rn
    FROM netflix_raw
)
SELECT * 
FROM cte 
WHERE rn = 1;

-- Creating new tables for 'listed_in', 'director', 'country', 'cast'
SELECT show_id, TRIM(value) AS director
INTO netflix_directors
FROM netflix_raw
CROSS APPLY STRING_SPLIT(director, ',');

SELECT show_id, TRIM(value) AS country
INTO netflix_country
FROM netflix_raw
CROSS APPLY STRING_SPLIT(country, ',');

SELECT show_id, TRIM(value) AS genre
INTO netflix_genre
FROM netflix_raw
CROSS APPLY STRING_SPLIT(listed_in, ',');

SELECT show_id, TRIM(value) AS cast
INTO netflix_cast
FROM netflix_raw
CROSS APPLY STRING_SPLIT(cast, ',');

-- Populate missing values in 'country' using 'director' and 'country' combination
INSERT INTO netflix_country
SELECT nr.show_id, m.country 
FROM netflix_raw nr
INNER JOIN (
    SELECT nd.director, nc.country 
    FROM netflix_country nc
    INNER JOIN netflix_directors nd ON nc.show_id = nd.show_id
    GROUP BY nd.director, nc.country
) m ON nr.director = m.director
WHERE nr.country IS NULL;

-- Analyze movies and TV shows created by directors
SELECT nd.director,
       COUNT(DISTINCT CASE WHEN n.type = 'Movie' THEN n.show_id END) AS no_of_movies,
       COUNT(DISTINCT CASE WHEN n.type = 'TV Show' THEN n.show_id END) AS no_of_tvshow
FROM netflix_stg n
INNER JOIN netflix_directors nd ON n.show_id = nd.show_id
GROUP BY nd.director
HAVING COUNT(DISTINCT n.type) > 1;

-- Country with the highest number of comedy movies
SELECT TOP 1 nc.country, COUNT(DISTINCT ng.show_id) AS no_of_movies
FROM netflix_genre ng
INNER JOIN netflix_country nc ON ng.show_id = nc.show_id
INNER JOIN netflix_stg n ON ng.show_id = n.show_id
WHERE ng.genre = 'Comedies'
AND n.type = 'Movie'
GROUP BY nc.country
ORDER BY no_of_movies DESC;

-- Director with maximum movies released each year
WITH cte AS (
    SELECT nd.director, YEAR(n.date_added) AS date_year, COUNT(n.show_id) AS no_of_movies
    FROM netflix_stg n
    INNER JOIN netflix_directors nd ON n.show_id = nd.show_id
    WHERE n.type = 'Movie'
    GROUP BY nd.director, YEAR(n.date_added)
),
cte2 AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY date_year ORDER BY no_of_movies DESC, director) AS rn
    FROM cte
)
SELECT * FROM cte2 WHERE rn = 1;

-- Average duration of movies in each genre
SELECT ng.genre, AVG(CAST(REPLACE(duration, ' min', '') AS INT)) AS avg_duration
FROM netflix_stg n 
INNER JOIN netflix_genre ng ON n.show_id = ng.show_id
WHERE n.type = 'Movie'
GROUP BY ng.genre;

-- Directors who created both horror and comedy movies
SELECT nd.director,
       COUNT(DISTINCT CASE WHEN ng.genre = 'Comedies' THEN n.show_id END) AS no_of_comedy,
       COUNT(DISTINCT CASE WHEN ng.genre = 'Horror Movies' THEN n.show_id END) AS no_of_horror
FROM netflix_stg n
INNER JOIN netflix_directors nd ON n.show_id = nd.show_id
INNER JOIN netflix_genre ng ON n.show_id = n.show_id
WHERE n.type = 'Movie'
AND ng.genre IN ('Comedies', 'Horror Movies') 
GROUP BY nd.director
HAVING COUNT(DISTINCT ng.genre) = 2;
