/* Q1: Who is the senior most employee based on job title? */
Select * from employee
order by levels desc
limit 1

/* Q2: Which countries have the most Invoices? */
Select count(*) as Total_invoice, billing_country from invoice
group by billing_country
order by Total_invoice desc

/* Q3: What are top 3 values of total invoice?*/
Select total from invoice
order by total desc
limit 3

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. */
Select sum(total) as total, billing_city from invoice
group by billing_city 
order by total desc 
limit 1

/* Q5: Who is the best customer? The customer who has spent the most money will be declared as the best customer. 
Write a query that returns the person who has spent the most money*/
Select c.customer_id,first_name,last_name,CAST(sum(total) AS decimal(100,2))from customer c
join invoice i on c.customer_id=i.customer_id
group by c.customer_id
order by sum(total) desc
limit 1

/* Q6: Write query to return the email, first name & last name of all Rock Music listeners. 
Return your list ordered alphabetically by email in ascending*/
Select Distinct c.email,c.first_name,c.last_name from customer c
join invoice i on i.customer_id=c.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
where il.track_id in(
	Select track_id from track
	join genre on track.genre_id=genre.genre_id
	where genre.name like '%Rock%'
)
order by c.email

/* Q7: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands*/

Select a.artist_id,a.name,count(a.artist_id) as no_of_songs from track t
join album al on al.albu9_id=t.album_id
join artist a on al.artist_id=a.artist_id
join genre g on g.genre_id=t.genre_id
where g.name like 'Rock'
group by a.artist_id
order by no_of_songs desc
limit 10

/* Q8: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first*/
Select name, milliseconds from track
where milliseconds > (
	Select Avg(milliseconds) from track)
order by milliseconds desc


/* Q9: Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent */
WITH best_selling_artist as(
	Select artist.artist_id as artist_id, artist.name as artist_name,
	sum(invoice_line.unit_price*invoice_line.quantity) as total_amt from invoice_line
	join track on track.track_id=invoice_line.track_id
	join album on album.album_id=track.album_id
	join artist on artist.artist_id=album.artist_id
	group by 1
	order by 3 desc
	limit 1
)
Select c.customer_id, c.first_name,c.last_name, bsa.artist_name, sum(il.unit_price * il.quantity) as amount_spent from invoice i
join customer c on c.customer_id=i.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
join track t on t.track_id=il.track_id
join album al on al.album_id=t.album_id
join best_selling_artist bsa on bsa.artist_id=al.artist_id
group by 1,2,3,4
order by amount_spent desc;

/* Q10: We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres */
With Recursive sales_per_country as(
	Select count(*) as purchases_per_genre, customer.country,genre.genre_id,genre.name 
	from invoice_line
	join invoice on invoice.invoice_id=invoice_line.invoice_id
	join customer on customer.customer_id=invoice.customer_id
	join track on track.track_id=invoice_line.track_id
	join genre on genre.genre_id=track.genre_id
	group by 2,3,4
	order by 2,1 desc
	),
	max_genre as (
		Select max(purchases_per_genre) as max_genre_number,country
		from sales_per_country
		group by 2
		order by 2
	)
Select sales_per_country.* from sales_per_country
join max_genre on max_genre.country=sales_per_country.country
where sales_per_country.purchases_per_genre=max_genre.max_genre_number

/* Q11: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount*/
With recursive
 customer_spent as(
	 Select customer.customer_id,first_name,last_name,billing_country,sum(total) as max_spending from invoice
	 join customer on customer.customer_id=invoice.customer_id
	 group by 1,2,3,4
	 order by 2,3 desc
	),
	max_spent as(
		Select billing_country,max(max_spending) as maximum_amt from customer_spent
		group by billing_country	
	)
Select customer_spent.* from customer_spent
join max_spent on max_spent.billing_country=customer_spent.billing_country
where customer_spent.max_spending=max_spent.maximum_amt
order by billing_country 

/* Q12: For each country give the revenue genreated by the most popular genre of that country */
With recursive revenue_per_country as( 
	Select i.billing_country,g.name,sum(il.unit_price*il.quantity) as revenue,
		ROW_NUMBER() OVER(PARTITION BY i.billing_country ORDER BY COUNT(il.quantity) DESC) AS RowNo
	from invoice_line il
	join invoice i on i.invoice_id=il.invoice_id
	join track t on il.track_id=t.track_id
	join genre g on g.genre_id=t.genre_id
	group by 1,2
	order by 1,3 desc
)
Select rp.billing_country,rp.name,rp.revenue from revenue_per_country rp where rowno<=1 order by 3 desc

/* Q13: Write a query to fetch top 10 most popular artist based on no of songs sold  */
Select ar.name, count(*) as total_songs_sold from track t
join album a on a.album_id=t.album_id
join artist ar on ar.artist_id=a.artist_id
join invoice_line il on il.track_id=t.track_id
join invoice i on i.invoice_id=il.invoice_id
group by ar.name,il.quantity
order by 2 desc
limit 10

/* Q14: Write a query to fetch the most famous song of all artist*/
with recursive most_famous_song as(
	Select ar.name as artist_name,t.name as track_name,(sum(total)*sum(il.quantity)) as total_amount from track t
	join album a on a.album_id=t.album_id
	join artist ar on ar.artist_id=a.artist_id
	join invoice_line il on il.track_id=t.track_id
	join invoice i on i.invoice_id=il.invoice_id
	group by ar.name,t.name
	order by 1,3 desc
),
top_hit as(
	Select artist_name, max(total_amount) as max_total_amt from most_famous_song
	group by artist_name
	order by 1,2 desc
)
Select m.artist_name,m.track_name from most_famous_song m
join top_hit t on t.artist_name=m.artist_name
where m.total_amount=t.max_total_amt
order by 1
