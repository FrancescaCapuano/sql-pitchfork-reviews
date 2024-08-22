/*
Pitchfork Reviews Exploration

Skills used: Joins, Temp Tables, Aggregate Functions, Subqueries, Filtering, Creating Views, Ordering, Arithmetic Operations, Data Retrieval

Dataset: 18,393 Pitchfork Reviews
Source: Kaggle
Queried using: PostgreSQL14
*/


-- Question 1: Do we have duplicate reviews?
SELECT COUNT(*) FROM reviews;
--18393
SELECT COUNT(*) FROM (
	SELECT DISTINCT * FROM reviews
) AS distinct_rows;
--18389 (4 duplicates)


-- Question 2: Do all artists (in artists) have a review (in reviews)?
SELECT COUNT(*) FROM (
SELECT DISTINCT(artists.reviewid) FROM artists
INNER JOIN reviews 
ON artists.reviewid = reviews.reviewid
) AS artists_with_review;
--yes, 18389


-- Question 3: What is the number of albums reviewed per year?
SELECT pub_year, COUNT(*) FROM reviews
GROUP BY pub_year
ORDER BY pub_year ASC;


-- Question 4: Mean review score per genre?

-- create view, we will reuse it later on
CREATE OR REPLACE VIEW reviews_genre AS
SELECT reviews.reviewid, genre, score, author, pub_year, artist FROM reviews
INNER JOIN genres
ON reviews.reviewid = genres.reviewid;

SELECT genre, AVG(score), COUNT(*) FROM reviews_genre
GROUP BY genre
ORDER BY avg ASC;
-- a lot of reviews unclassified on genre (null), let's explore it -->


-- Question 5: Which artists are unclassified?
SELECT artist, COUNT(*) FROM reviews_genre
WHERE genre IS NULL
GROUP BY artist
ORDER BY COUNT(*) DESC;
-- most unclassified reviews are from 'various artists'


-- Question 6: Which author gives the worst scores?
-- create view of authors that have a consistent amount of reviews, otherwise results are spurious
CREATE OR REPLACE VIEW authors_with_many_reviews AS
SELECT author, COUNT(*) FROM reviews_genre
GROUP BY author
HAVING COUNT(*) > 10;

-- how many are thre?
SELECT COUNT(*) FROM authors_with_many_reviews;

-- order authors by average review score
SELECT reviews_genre.author, AVG(score), COUNT(score) FROM reviews_genre
JOIN authors_with_many_reviews
ON reviews_genre.author = authors_with_many_reviews.author
GROUP BY reviews_genre.author 
ORDER BY AVG(score) ASC;
-- Michael Sandlin seems particularly harsh


-- Question 7: Are authors specializing in particular genres?
-- translates to: considering only those authors with a significant amount of reviews,
-- how many write more than 50% of their reviews in one genre?
SELECT reviews_genre.author, genre, COUNT(*)*100/authors_with_many_reviews.count AS percentage FROM reviews_genre
JOIN authors_with_many_reviews
ON reviews_genre.author = authors_with_many_reviews.author
GROUP BY reviews_genre.author, genre, authors_with_many_reviews.count
HAVING COUNT(*)*100/authors_with_many_reviews.count > 50
ORDER BY reviews_genre.author;
-- 105 authors out of 219 write the majority of their reviews in one genre



-- Question 8: Are some authors no longer active?
SELECT author, MAX(pub_year) FROM reviews
GROUP BY author
ORDER BY MAX(pub_year);
-- some wrote their last review as far back as in 1999