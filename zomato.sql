create database zomato;
use zomato;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- Data Analysis

-- 1. What is the total amount each customer spent on zomato?

select s.userid,sum(p.price) as totalspent
from sales s
join product p
on s.product_id=p.product_id
group by s.userid;

-- 2. How many days has each customer visited zomato?

select userid,count(distinct created_date) as activedays
from sales
group by userid;

-- 3. What was the first product purchased by each customer?

select *
from
(select *,
row_number() over (partition by userid order by created_date) as ro
from sales) a 
where ro=1;

-- 4. What is the most purchased item and how many time was it purchased by each customer?

select userid,count(product_id) as cnt
 from sales where product_id=
(select product_id
from sales
group by product_id
order by count(product_id) desc
limit 1)
group by userid;

-- 5. Which item was the most popular for each customer?

select userid,product_id from
(select *, rank() over(partition by userid order by cnt desc) as rnk from
(select userid,product_id,count(product_id) as cnt
from sales
group  by userid,product_id) as a) as b
where rnk=1;

-- 6. Which item was purchased first after they became a gold member?

select userid,product_id,created_date,gold_signup_date from
(select * ,rank() over (partition by userid order by created_date) rnk
from( 
select s.userid,s.product_id,s.created_date,g.gold_signup_date from sales s
inner join goldusers_signup g
on s.userid=g.userid and s.created_date>g.gold_signup_date) d)t
where rnk=1;


-- 7. Which item was purchased just before the customer became a member?

select userid,product_id,created_date,gold_signup_date
from
(select * ,rank() over (partition by userid order by created_date desc) rnk
from( 
select s.userid,s.product_id,s.created_date,g.gold_signup_date from sales s
inner join goldusers_signup g
on s.userid=g.userid and s.created_date<=g.gold_signup_date) d)r
where rnk=1;

-- 8. What is the total order and amount spent for each member before they became a member?

select userid,count(created_date) as numoforder, sum(price) as totalprice
from
(select s.userid,s.product_id,s.created_date,g.gold_signup_date,p.price from sales s
inner join goldusers_signup g
on s.userid=g.userid and s.created_date<=g.gold_signup_date
inner join product p 
on s.product_id=p.product_id) d
group by userid;


-- 9. If buying each product generates point for eg- rs5-2 zomato points and each product has different purchasing points 
-- for eg p1 5rs- 1 zomato point,p2 10rs-5 zomato points,p3 5rs-1 zomato points.
-- calculate point collected for each customer and for which product most point has been given till now. 

select userid, 
round(sum(case 
when product_id=1 then (total/5)*1
when product_id=2 then (total/10)*5
else (total/5)*1
end),0) as points
from
(select s.userid,p.product_id,sum(price) as total from sales s 
inner join product p 
on s.product_id=p.product_id
group by userid,product_id)d
group by userid;


select product_id, 
round(sum(case 
when product_id=1 then (total/5)*1
when product_id=2 then (total/10)*5
else (total/5)*1
end),0) as points
from
(select s.userid,p.product_id,sum(price) as total from sales s 
inner join product p 
on s.product_id=p.product_id
group by userid,product_id)d
group by product_id
order by points desc;

-- 10. In the first one year after a customer joins a gold program(include there join date) 
-- irrespective of what the customer had purchased they earn 5 zomato point for each 10 rs spent 
-- who earned more 1 or 3 and what was their point earning in the first year?

select userid,round(sum((price/10)*5),0) as pointearned
from
(select s.userid,s.created_date,p.product_id,p.price,g.gold_signup_date from sales s
inner join goldusers_signup g 
on s.userid=g.userid and s.created_date >=g.gold_signup_date and created_date<=DATE_ADD(gold_signup_date,interval 1 year)
inner join product p 
on s.product_id=p.product_id) asd 
group by userid;

-- 11. Rank all the transaction of the customers. 

select *,
rank() over (partition by userid order by created_date) as rnk
from sales;

-- 12. Rank all the transaction for each member whenever they are a zomato gold member for every non gold member transaction mark as NA.

select *,
case 
when gold_signup_date is null then "na"
else rank() over (partition by userid order by created_date desc) 
end as rnk
from
 (select s.*, g.gold_signup_date
 from sales s
 left join goldusers_signup g
 on s.userid=g.userid and s.created_date> g.gold_signup_date) t;
