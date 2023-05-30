-- 1) Easy Questions :-

-- Q1 - Who is the senior employee according to title?

SELECT * FROM employee
ORDER BY levels DESC
limit 1;

-- Q2 - Which country has the most invoices?

SELECT count(*) as invoice_no , billing_country FROM invoice
GROUP BY billing_country
ORDER BY invoice_no desc

-- Q3 - What are top 3 values of total invoice?

SELECT * FROM invoice
order by total DESC
limit 3

-- Q4 - Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals

select billing_city, sum(cast(total as decimal(4,2))) as tot from invoice
group by billing_city
order by tot desc
limit 1

-- Q5 - Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money.

SELECT customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) as tot FROM customer
join invoice on customer.customer_id = invoice.customer_id
group BY customer.customer_id
ORDER BY tot desc
limit 1




-- 2) Moderate Questions :-

-- Q1 - Write query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A

SELECT distinct customer.email, customer.first_name, customer.last_name from customer
join invoice on customer.customer_id = invoice.invoice_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in 
( SELECT track_id FROM track_1
join genre on genre.genre_id = track_1.genre_id
where genre.name like "%Rock%"
)
order by customer.email

-- Q2 - Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands

SELECT artist.artist_id, artist.name, count(track_1.track_id) as track_count FROM artist
join album on artist.artist_id = album.artist_id
join track_1 on album.album_id = track_1.album_id
WHERE track_id IN
(
    SELECT track_id from track_1
    join genre on track_1.genre_id = genre.genre_id
    where genre.name like "%Rock%"
)
group BY artist.artist_id
order by track_count DESC
limit 10

-- Q3 - Return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.

select name, milliseconds FROM track_1
WHERE milliseconds >
(
    SELECT avg(milliseconds) as avg from track_1
)
ORDER BY milliseconds desc




-- 3) Advance Questions :-

-- Q1 - Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent

WITH cte as 
( 
    SELECT artist.artist_id, artist.name, sum(invoice_line.unit_price*invoice_line.quantity) as amount from artist
    join album on album.artist_id = artist.artist_id
    join track_1 on track_1.album_id = album.album_id
    join invoice_line on invoice_line.track_id = track_1.track_id
    GROUP BY 1
    order by 3 desc
   limit 1
)
SELECT customer.customer_id, customer.first_name,
customer.last_name, cte.name, cast(sum(invoice_line.unit_price*invoice_line.quantity) as DECIMAL(5,2)) as amount_spent
from invoice
join customer on customer.customer_id = invoice.invoice_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
join track_1 ON track_1.track_id = invoice_line.track_id
join album ON album.album_id = track_1.album_id
join cte ON cte.artist_id = album.artist_id
group by 1,2,3,4
ORDER BY 5 DESC;

-- Q2 - We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.

WITH recursive popular_genre AS
(
SELECT COUNT(*) AS purchases, customer.country, genre.name, genre.genre_id
FROM invoice_line
JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
JOIN customer ON customer.customer_id = invoice.customer_id
JOIN track_1 ON track_1.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track_1.genre_id 
GROUP BY 2,3,4
ORDER BY 2 
),
cte as 
(
    select country, max(purchases) as max_purschase_per_genre
    from popular_genre
    group by country

)

select popular_genre.* from popular_genre 
join cte on popular_genre.country = cte.country
where cte.max_purschase_per_genre = popular_genre.purchases
group by 2,3,4
order by 1 desc


-- Q3 - Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount

With Recursive cte As 
(
Select customer.customer_id, customer.first_name, customer.last_name, invoice.billing_country, sum(invoice.total) as sales_amount
from 
customer
join invoice on customer.customer_id = invoice.customer_id
group by 2,3,4
order by 4
),
max_cte AS 
(
    Select billing_country, max(sales_amount) as max_sales_amount
    from cte 
    group by 1
    order by 1
)

select cte.* from cte 
join max_cte on cte.billing_country = max_cte.billing_country
where cte.sales_amount = max_cte.max_sales_amount
group by 4,2,3
order by 5 desc 