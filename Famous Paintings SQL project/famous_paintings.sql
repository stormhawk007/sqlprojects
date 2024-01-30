set sql_safe_updates = 0;
-- All the paintings which are not displayed in any museums
SELECT * 
FROM work
WHERE museum_id IS NULL;

-- 2.) Are there any museums without any paintings
SELECT m.museum_id,COUNT(work_id) AS num_paintings
FROM museum m 
LEFT JOIN work w
ON m.museum_id = w.museum_id
GROUP BY museum_id
HAVING num_paintings<=0
ORDER BY num_paintings DESC;

-- select * from museum m
-- 	where not exists (select 1 from work w
-- 			  where w.museum_id=m.museum_id)

-- 3.) How many paintings have an asking price of more than their regular price
SELECT * 
FROM product_size
WHERE sale_price > regular_price;

-- 4) Identify the paintings whose asking price is less than 50% of its regular price
SELECT * 
FROM product_size
WHERE sale_price < regular_price * 0.50;

-- 5) Which canvas size costs the most?
SELECT c.size_id,width,height,label,p.sale_price,p.regular_price
FROM canvas_size c
LEFT JOIN product_size p
ON p.size_id = c.size_id
ORDER BY p.sale_price DESC 
LIMIT 1;

-- 6) Delete duplicate records from work, product_size, subject and image_link tables
set sql_safe_updates = 0;

SELECT work_id
FROM image_link
GROUP BY work_id
HAVING count(*)>1;

create table temp
select distinct * 
from image_link;
truncate image_link;
insert into image_link select * from temp;
drop table temp;

-- Solution: IN POSTGRE SQL
-- delete from work 
-- where ctid not in (select min(ctid)
-- 						from work
-- 						group by work_id );


-- 7.) Identify the museums with invalid city information in the given dataset
select *
from museum
where city regexp("^[0-9]");

-- 8)  Museum_Hours table has 1 invalid entry. Identify it and remove it.
select * from  museum_hours;

create table temp
select distinct * 
from museum_hours;

truncate museum_hours;
insert into museum_hours select * from temp;
drop table temp;

-- 9) Fetch the top 10 most famous painting subject
select * 
from (
	select s.subject,count(1) as no_of_paintings
	,rank() over(order by count(1) desc) as ranking
	from work w
	join subject s on s.work_id=w.work_id
	group by s.subject ) x
where ranking <= 10;

-- 10) Identify the museums which are open on both Sunday and Monday. Display museum name, city.
select m1.museum_id,name,city
from museum_hours m1
join museum
on m1.museum_id = museum.museum_id
where day = 'Sunday' and
	  exists (select 1
			  from museum_hours m2
              where m1.museum_id = m2.museum_id 
              and m2.day = 'Monday');
              
-- 11) How many museums are open every single day?
select * from museum m
where museum_id in (select museum_id
			  from museum_hours m2
              group by museum_id
              having count(1)=7);
			
-- 12)Which are the top 5 most popular museum? 
-- (Popularity is defined based on most no of paintings in a museum)
select m.museum_id,m.name,m.city,count(work_id) as num_paintings,
rank() over (order by count(work_id) desc) as final_rank
from work w
inner join museum m 
on w.museum_id = m.museum_id
group by m.museum_id,m.name,m.city
limit 5;

-- 13) Who are the top 5 most popular artist? 
-- (Popularity is defined based on most no of paintings done by an artist)
select a.artist_id,a.full_name,a.nationality,count(work_id) as num_paintings,
rank() over (order by count(work_id) desc) as final_rank
from work w
inner join artist a 
on w.artist_id = a.artist_id
group by a.artist_id,a.full_name,a.nationality
limit 5;

-- 14) Display the 3 least popular canva sizes
select c.size_id,c.height,c.width,c.label,
count(work_id) as num_paintings,
dense_rank() over (order by count(work_id) desc) as final_rank
from canvas_size c
join product_size p on c.size_id = p.size_id
group by c.size_id,c.height,c.width,c.label
limit 5;

-- 15) Which museum is open for the longest during a day. 
-- Dispay museum name, state and hours open and which day?
select * 
from
	(select name,day,m1.museum_id,state,open,close,
	time(str_to_date(trim(close),"%h:%i:%p") - str_to_date(trim(open),"%h:%i:%p")) as open_hours,
	dense_rank() over (order by time(str_to_date(trim(close),"%h:%i:%p") - str_to_date(trim(open),"%h:%i:%p")) desc) as final_rank
	from museum_hours m1
	join museum m2
	on m1.museum_id = m2.museum_id) x
where final_rank <10;

-- 16) Which museum has the most no of most popular painting style?
with pop_style as (select style, rank () over (order by count(1) desc) as rnk
				   from work 
                   group by style),
cte as (select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings,
		rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		join pop_style ps on ps.style = w.style
		where w.museum_id is not null
		and ps.rnk=1
		group by w.museum_id, m.name,ps.style)

select museum_name,style,no_of_paintings
from cte
order by rnk ;

-- 17) Identify the artists whose paintings are displayed in multiple countries
with cte as
	(select distinct a.full_name as artist
    , w.name as painting, m.name as museum
	, m.country
	from work w
	join artist a on a.artist_id=w.artist_id
	join museum m on m.museum_id=w.museum_id)
select artist,count(1) as no_of_countries
from cte
group by artist
having count(1)>1
order by 2 desc;

-- 18) Display the country and the city with most no of museums.
-- Output 2 seperate columns to mention the city and country. 
-- If there are multiple value, seperate them with comma.
with cte_country as 
			(select country, count(1)
			, rank() over(order by count(1) desc) as rnk
			from museum
			group by country),
		cte_city as
			(select city, count(1)
			, rank() over(order by count(1) desc) as rnk
			from museum
			group by city)
select group_concat(distinct country.country separator ', ') as country,
group_concat(city.city separator ', ') as city
from cte_country country
cross join cte_city city
where country.rnk = 1
and city.rnk = 1;


-- 19) Identify the artist and the museum where the most expensive and least expensive painting is placed. 
-- Display the artist name, sale_price, painting name, museum name, museum city and canvas label
SELECT *
from (select DISTINCT a.artist_id,
		   p.sale_price,
		   w.name as painting_name,
		   m.name as museun_name,
		   m.city as museum_city,
		   c.label as canvas_label, 
		   rank() over(order by sale_price desc) as rnk,
		   rank() over(order by sale_price ) as rnk_asc
		from product_size p
		join work w on w.work_id = p.work_id
		join artist a on w.artist_id = a.artist_id
		join canvas_size c on c.size_id = p.size_id
		join museum m on m.museum_id = w.museum_id) a
where rnk = 1 or rnk_asc = 1;

-- 20) Which country has the 5th highest no of paintings?
select m.country,
 count(work_id) as num_paintings,
 rank() over (order by count(work_id) desc) as rnk
from museum m
join work w
on w.museum_id = m.museum_id
group by country
limit 4,1;

-- 21) Which are the 3 most popular and 3 least popular painting styles?
with cte as 
		(select style, count(1) as cnt
		, rank() over(order by count(1) desc) rnk
		, count(1) over() as no_of_records
		from work
		where style is not null
		group by style)
	select style
	, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte
	where rnk <=3
	or rnk > no_of_records - 3;


-- 22) Which artist has the most no of Portraits paintings outside USA?. 
-- Display artist name, no of paintings and the artist nationality.
with cte as (select a.artist_id,a.full_name as name,a.nationality,
				count(w.work_id) as num_paintings,
				rank() over (order by count(w.work_id) desc) as rnk
			from artist a
			join work w on a.artist_id = w.artist_id
			join museum m on m.museum_id = w.museum_id and m.country <>"USA"
			join subject s on s.work_id = w.work_id and s.subject = "Portraits"
            group by artist_id,full_name,nationality)

select *
from cte
where rnk = 1;




