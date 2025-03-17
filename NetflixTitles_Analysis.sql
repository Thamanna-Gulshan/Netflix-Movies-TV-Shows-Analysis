/* DATABASE CREATION */

CREATE DATABASE netflix_Movies;
USE netflix_Movies;

/* CREATE TABLE SCHEMA  */

CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);

/* LOAD DATA */

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\netflix_titles.csv'
INTO TABLE netflix
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM netflix;

SELECT COUNT(*) AS total_content
FROM netflix;

/* DATA CLEANING */

-- Identify duplicates
WITH duplicate_cte as 
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY show_id) AS ranking
FROM netflix
)
SELECT * FROM duplicate_cte WHERE ranking>1;
-- Data has no duplicate values

-- Updating empty values to NULL
UPDATE netflix
SET date_added = null WHERE date_added='';

/* CORRECTING DATA TYPE */

SELECT distinct(date_added), STR_TO_DATE(date_added,'%M %d, %Y')
FROM netflix;

-- Formatting the date_added column to supported date format
UPDATE netflix SET date_added = STR_TO_DATE(date_added,'%M %d, %Y');

-- Change the data type of the column
ALTER TABLE netflix MODIFY COLUMN date_added DATE;

/* DATA ANALYSIS */

/* Find Number of Movies vs TV Shows */

SELECT 
type, COUNT(*) AS total_content
FROM netflix
GROUP BY `type`;

/* Find the Most Common Rating for Movies and TV Shows */

WITH RatingCounts AS (
	SELECT 
	type,
	rating,
	COUNT(*) AS rating_count
	FROM netflix
	GROUP BY type, rating
),
RankedRatings AS (
SELECT 
type,
rating,
rating_count,
RANK() OVER (PARTITION BY type ORDER BY rating_count DESC) AS ranking
FROM RatingCounts
)
SELECT 
type,
rating AS most_frequent_rating
FROM RankedRatings
WHERE ranking = 1;

/* List All Movies Released in 2020 */
SELECT title
FROM netflix
WHERE 
type = 'Movie' AND release_year = 2020;

/* Identify the Longest Movie */

SELECT title
FROM netflix
WHERE type = 'movie'
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 1;

/* Find Content Added in the Last 5 Years */
SELECT *
FROM netflix
WHERE date_added >= DATE_SUB(current_date(), INTERVAL 5 YEAR);

/* Find All Movies/TV Shows by Director 'Rajiv Chilaka' */
SELECT title
FROM netflix
WHERE director LIKE '%Rajiv Chilaka%';

/* List All TV Shows with More Than 5 Seasons */
SELECT title
FROM netflix
WHERE type = 'TV show' AND 
CONVERT(SUBSTRING_INDEX(duration,' ', 1), UNSIGNED)>5;

/* Count the Number of Content Items in Each Genre */
WITH genre_split AS (
    SELECT genre
    FROM netflix,
    JSON_TABLE(
        CONCAT('["', REPLACE(listed_in, ', ', '","'), '"]'),  -- Convert CSV to JSON array
        "$[*]"
        COLUMNS (genre VARCHAR(100) PATH "$")
    ) AS genre_table
)
SELECT genre, COUNT(*) AS total_content
FROM genre_split
GROUP BY genre
ORDER BY total_content DESC;

/* Find each year and the number of content release in India on netflix. */
SELECT release_year, COUNT(show_id) AS no_of_content
FROM netflix
WHERE country LIKE '%India%'
GROUP BY release_year
ORDER BY release_year;

/* List All Movies that are Documentaries */
SELECT title
FROM netflix
WHERE type = 'movie' AND listed_in LIKE '%Documentaries%';

/* Find All Content Without a Director */
SELECT *
FROM netflix
WHERE director IS NULL or director='';

/* Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years */
SELECT * 
FROM netflix
WHERE casts LIKE '%Salman Khan%'
AND release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10;

/* Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India */
SELECT *
FROM netflix;

/* Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords */
SELECT 
Category, COUNT(*) AS content_count
FROM
(
SELECT 
title, 
case when description LIKE '%kill%' OR description LIKE '%Violence%' THEN 'Bad' ELSE 'Good' END AS Category
FROM netflix)categorized_content
GROUP BY Category;












