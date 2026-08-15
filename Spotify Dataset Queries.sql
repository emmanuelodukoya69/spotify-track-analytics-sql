-- create table
DROP TABLE IF EXISTS spotify;

CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);

------ Data Exploration
SELECT * FROM spotify
LIMIT 100;


SELECT DISTINCT artist
FROM spotify;

SELECT COUNT(DISTINCT artist)
FROM spotify;

SELECT COUNT(DISTINCT album)
FROM spotify;

SELECT DISTINCT album_type
FROM spotify;

SELECT MAX(duration_min) as max_duration
FROM spotify;

--- Track the Minimum Duration
SELECT * 
FROM spotify
WHERE duration_min = 0;

-- Then we proceed to delete them
DELETE FROM spotify
WHERE duration_min = 0;

-- to view
SELECT * 
FROM spotify
WHERE duration_min = 0;

--- To examine each track per album
SELECT DISTINCT
	album,
	track
FROM spotify
ORDER BY 1,2;

-- Count of tracks per album
SELECT album,
	COUNT(DISTINCT track) as track_count
FROM spotify
GROUP BY 1
ORDER BY track_count DESC;


SELECT COUNT(*) FROM spotify;

SELECT DISTINCT most_played_on
FROM spotify;

-------------------------------------------- 15 Practice Questions ---------------------------------------------

--------------------------------------------- Easy Level -------------------------------------------------

-- 1. Retrieve the names of all tracks that have more than 1 billion streams.
SELECT track, artist, stream
FROM spotify
WHERE stream > 1000000000
ORDER BY stream DESC;

-- 2. List all albums along with their respective artists.
SELECT DISTINCT
	album,
	artist
FROM spotify
ORDER BY 1,2;

-- 3. Get the total number of comments for tracks where `licensed = TRUE`.
SELECT SUM(comments) as total_comments
FROM spotify
WHERE licensed = 'TRUE';

--- OR (TO GET FOR EACH TRACK)
SELECT track,
	   SUM(comments) as total_comments
FROM spotify
WHERE licensed = 'TRUE'
GROUP BY 1
ORDER BY 2 DESC;

-- 4. Find all tracks that belong to the album type `single`.
SELECT 
	track,
	artist,
	album
FROM spotify
WHERE album_type = 'single';

-- 5. Count the total number of tracks by each artist.
SELECT 
	artist,
	COUNT(track) as track_num
FROM spotify
GROUP BY 1
ORDER BY 2 DESC;


-------------------------------------------- Medium Level --------------------------------------------------
-- 1. Calculate the average danceability of tracks in each album.
SELECT
	album,
	AVG(danceability) as avg_dance
FROM spotify
GROUP BY 1
ORDER BY 2 DESC;

-- 2. Find the top 5 tracks with the highest energy values.
SELECT track,artist, energy
FROM spotify
ORDER BY 3 DESC
LIMIT 5;

-- 3. List all tracks along with their views and likes where `official_video = TRUE`.
SELECT 
	track,
	views,
	likes
FROM spotify
WHERE official_video = TRUE
ORDER BY 2 DESC;

-- OR (TO SCAN THE VIEWS VS LIKES)
SELECT 
	track,
	views,
	likes,
	ROUND((likes * 100.0 / nullif(views,0))::NUMERIC,2) as likes_pct	
FROM spotify
WHERE official_video = TRUE
ORDER BY 2 DESC;

-- 4. For each album, calculate the total views of all associated tracks.
SELECT
	album,
	track,
	SUM(views) as total_views,
	COUNT(*) AS track_count
FROM spotify
GROUP BY 1,2
ORDER BY 3 DESC;

-- OR
SELECT 
    album,
    artist,
    SUM(views) AS total_views,
    COUNT(*) AS track_count
FROM spotify
GROUP BY album, artist
ORDER BY total_views DESC;


-- 5. Retrieve the track names that have been streamed on Spotify more than YouTube.
SELECT * FROM 
	(SELECT
		track,
		COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN stream END),0) AS streamed_on_youtube,
		COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END),0) AS streamed_on_spotify
	FROM spotify
	GROUP BY 1
	) as t1
WHERE streamed_on_spotify > streamed_on_youtube
AND streamed_on_youtube <> 0
ORDER BY streamed_on_spotify DESC;



--------------------------------------------- Advanced Level -----------------------------------------------
-- 1. Find the top 3 most-viewed tracks for each artist using window functions.
WITH total_views AS (
	SELECT
		track,
		artist,
		SUM(views) as total_views
	FROM spotify
	GROUP BY 1,2
),
ranked_view AS (
	SELECT 
		*, 
		DENSE_RANK() OVER (PARTITION BY artist ORDER BY total_views DESC) AS rank
	FROM total_views
)
SELECT *
FROM ranked_view
WHERE rank <= 3;


-- 2. Write a query to find tracks where the liveness score is above the average.
SELECT track,
	   artist,
	   liveness
FROM spotify
WHERE liveness > (SELECT avg(liveness) FROM spotify)
ORDER BY 3 DESC;

-- USING CTEs
WITH avg_liveness AS (
    SELECT ROUND(AVG(liveness)::NUMERIC,3) AS avg_live
    FROM spotify
)
SELECT 
    track, 
    artist, 
    liveness,
    avg_live
FROM spotify, avg_liveness
WHERE liveness > avg_live
ORDER BY liveness DESC;
	   
-- 3. Use a `WITH` clause to calculate the difference between the highest and 
-- lowest energy values for tracks in each album.
WITH Energy_diff AS (
	SELECT
		album,
		max(energy) as max_energy,
		min(energy) as min_energy
	FROM spotify
	GROUP BY 1
)
SELECT 
	album,
	ROUND((max_energy - min_energy)::NUMERIC,2) as energy_difference
FROM Energy_diff
ORDER BY 2 DESC;

--- 4. Find tracks where the energy-to-liveness ratio is greater than 1.2.
SELECT 
    track, 
    artist, 
    energy, 
    liveness,
    ROUND(energy::NUMERIC / NULLIF(liveness, 0)::NUMERIC, 4) AS energy_liveness_ratio
FROM spotify
WHERE liveness > 0 
  AND (energy / liveness) > 1.2
ORDER BY energy_liveness_ratio DESC;


--- Calculate the cumulative sum of likes for tracks ordered by the number of views,
--- using window functions.
SELECT 
    track,
    artist,
    views,
    likes,
    SUM(likes) OVER (ORDER BY views DESC) AS cumulative_likes
FROM spotify
ORDER BY views DESC;


--- Question: What is the average energy, danceability, and valence for "Top Streamed" tracks vs. 
--- "Low Streamed" tracks?
SELECT 
    CASE WHEN stream > (SELECT AVG(stream) FROM spotify) THEN 'High Performance'
         ELSE 'Low Performance' END as performance_category,
    ROUND(AVG(danceability)::numeric, 3) as avg_danceability,
    ROUND(AVG(energy)::numeric, 3) as avg_energy,
    ROUND(AVG(valence)::numeric, 3) as avg_positivity
FROM spotify
GROUP BY 1;


--- Question: Which tracks have the highest comment-to-view ratio (Engagement Index)?
SELECT 
    track, 
    artist,
    views,
    comments,
    ROUND((comments) * 100.0 / NULLIF(views, 0)::NUMERIC,3) as engage_index_per_views
FROM spotify
WHERE views > 1000000
ORDER BY engage_index_per_views DESC
LIMIT 10;

--- Question: What percentage of total streams comes from non-licensed or unofficial content? 
SELECT 
    official_video,
    licensed,
    COUNT(*) as track_count,
    SUM(stream) as total_streams,
    ROUND(SUM(stream) * 100.0 / (SELECT SUM(stream) FROM spotify), 2) as stream_percentage
FROM spotify
GROUP BY official_video, licensed
ORDER BY total_streams DESC;

---- Platform dominance split — Spotify vs YouTube by album type
SELECT
  album_type,
  most_played_on AS platform,
  COUNT(*) AS track_count,
  SUM(stream) AS total_streams,
  SUM(views) AS total_yt_views,
  ROUND(100.0 * SUM(stream)
    / (SELECT SUM(stream) FROM spotify)::NUMERIC, 1) AS spotify_share_pct,
  ROUND(AVG(danceability)::NUMERIC, 3) AS avg_danceability
FROM spotify
WHERE most_played_on IN ('Spotify', 'Youtube')
GROUP BY album_type, most_played_on
ORDER BY album_type, total_streams DESC;





















































































