select * from bankdata;
select * from bonddata;
select * from donordata;
select * from receiverdata;
--Find out how much donors spent on bonds.
select 
     sum(denominations) as total_money_spend
from bonddata
inner join donordata
on bonddata.unique_key = donordata.unique_key;
-- Find out total funds politicians got.
select 
     sum(denominations) as total_money_spend
from bonddata
inner join receiverdata
on bonddata.unique_key = receiverdata.unique_key;
-- Find out the total amount of unaccounted money received by parties (bonds without donors).
select
    sum(denominations)
from donordata as d right join receiverdata as r
on d.unique_key = r.unique_key
join bonddata as b
on r.unique_key = b.unique_key
where purchaser is Null;
-- Find year-wise how much money is spent on bonds.
select
   extract(year from d.purchasedate) as "year",
   sum(b.denominations) as "Yearly spend"
from donordata as d
left join bonddata as b
on d.unique_key = b.unique_key
group by year
order by "Yearly spend" desc;
--In which month was the most amount spent on bonds?
select 
    extract(month from d.purchasedate) as "Months",
	sum(b.denominations) as "Max amount spend in one month"
from donordata as d
join bonddata as b
on d.unique_key = b.unique_key
group by "Months" 
order by "Max amount spend in one month" desc 
limit 1;
-- Find out which company bought the highest number of bonds and what is the total money spend of those bonds
-- 6 and 7 questions are done in a single query
select 
    d.purchaser as "Name of company",
    count(d.purchaser) as "Number of bond",
	sum(b.denominations) as "Bond Value"
from donordata as d 
join bonddata as b
on d.unique_key = b.unique_key
group by "Name of company" 
order by "Number of bond" desc
limit 1;
-- List companies which paid the least to political parties.
select 
    d.purchaser as "Name of company",
    count(d.purchaser) as "Number of bond",
	sum(b.denominations) as "Bond Value"
from donordata as d 
join bonddata as b
on d.unique_key = b.unique_key
group by "Name of company" 
having sum(b.denominations) = (
select 
    min(money_spent) 
	from (
select sum(denominations) as money_spent from donordata as d
join bonddata as b 
on d.unique_key = b.unique_key
group by purchaser
	)
);
--Which political party received the highest cash?
select 
    r.partyname as "Political Party",
	sum(b.denominations) as "Total amount received"
from receiverdata as r 
join bonddata as b 
on r.unique_key = b.unique_key
group by "Political Party"
order by "Total amount received" desc
limit 1;
--Which political party received the highest number of electoral bonds?
select 
    r.partyname as "Political Party",
	count(b.unique_key) as "Total bonds received"
from receiverdata as r 
join bonddata as b 
on r.unique_key = b.unique_key
group by "Political Party"
order by "Total bonds received" desc
limit 1;
--Which political party received the least cash?
select 
    r.partyname as "Political Party",
	sum(b.denominations) as "Total amount received"
from receiverdata as r 
join bonddata as b 
on r.unique_key = b.unique_key
group by "Political Party"
order by "Total amount received" asc
limit 1;
-- Which political party received the least number of electoral bonds?
select 
    r.partyname as "Political Party",
	count(b.unique_key) as "Total bonds received"
from receiverdata as r 
join bonddata as b 
on r.unique_key = b.unique_key
group by "Political Party"
order by "Total bonds received" asc
limit 1;
--Find the 2nd highest donor in terms of the amount paid.
WITH donor_totals AS (
    SELECT
        d.purchaser AS donor,
        SUM(b.denominations) AS amount_paid,
        DENSE_RANK() OVER (ORDER BY SUM(b.denominations) DESC) AS rank
    FROM donordata d
    JOIN bonddata b ON d.unique_key = b.unique_key
    GROUP BY d.purchaser
)
SELECT donor, amount_paid
FROM donor_totals
WHERE rank = 2;
-- Find the party which received the second-highest donations and number of donations
-- 14 and 15 
WITH donor_totals AS (
    SELECT
        r.partyname AS party,
        SUM(b.denominations) AS amount_paid,
		count(b.unique_key) as "Number of Bonds",
        DENSE_RANK() OVER (ORDER BY SUM(b.denominations) DESC) AS rank
    FROM receiverdata r
    JOIN bonddata b ON r.unique_key = b.unique_key
    GROUP BY r.partyname
)
SELECT party, amount_paid,"Number of Bonds"
FROM donor_totals
WHERE rank = 2;
-- In which city were the most number of bonds purchased?
with City_wise_donor as(
select  
    b.city as "City",
	count(c.denominations) as "Total bonds Purchsed",
	dense_rank() over(order by count(c.denominations) desc) as rank
from donordata as d
join bankdata as b
on d.paybranchcode = b.branchcodeno
join bonddata as c on c.unique_key = d.unique_key
group by "City"
)
select "City" , "Total bonds Purchsed"
from City_wise_donor
where rank = 1;
-- In which city was the highest amount spent on electoral bonds?
with City_wise_donor_amount_spend as(
select  
    b.city as "City",
	Sum(c.denominations) as "Total bonds Purchsed Amount",
	dense_rank() over(order by sum(c.denominations) desc) as rank
from donordata as d
join bankdata as b
on d.paybranchcode = b.branchcodeno
join bonddata as c on c.unique_key = d.unique_key
group by "City"
)
select "City" , "Total bonds Purchsed Amount"
from City_wise_donor_amount_spend
where rank = 1;
-- In which city were the least number of bonds purchased?
with City_wise_donor as(
select  
    b.city as "City",
	count(c.denominations) as "Total bonds Purchsed",
	dense_rank() over(order by count(c.denominations) asc) as rank
from donordata as d
join bankdata as b
on d.paybranchcode = b.branchcodeno
join bonddata as c on c.unique_key = d.unique_key
group by "City"
)
select "City" , "Total bonds Purchsed"
from City_wise_donor
where rank = 1;
-- In which city were the most number of bonds encashed?
with city_bond_amt as (
select 
     b.city,
	 count(r.unique_key) as "city bond encashment" 
from 
receiverdata as r 
join bankdata as b 
on r.paybranchcode=b.branchcodeno
join bonddata as c 
on c.unique_Key=r.unique_key 
group by b.city)
select * from 
city_bond_amt 
where "city bond encashment" = 
(select max("city bond encashment") 
from city_bond_amt);
-- List the branches where no electoral bonds were bought; if none, mention it as null
SELECT 
    b.address AS "Branch",
    b.branchcodeno AS "Branch Code"
FROM bankdata b
LEFT JOIN donordata d
    ON b.branchcodeno = d.paybranchcode
WHERE d.paybranchcode IS NULL;
--Break down how much money is spent on electoral bonds for each year and provide
--the year and the amount. Provide values for the highest and least year and amount	
select
   extract(year from d.purchasedate) as "year",
   sum(b.denominations) as "Yearly spend"
from donordata as d
left join bonddata as b
on d.unique_key = b.unique_key
group by year
order by "Yearly spend" desc;
-- Find out how many donors bought the bonds but did not donate to any political party.
WITH Not_donated AS (
    SELECT 
        d.purchaser AS "Purchaser",
        COUNT(d.urn) AS "Number of Bonds Purchased",
        SUM(b.denominations) AS "Bond Value"
    FROM donordata d
    LEFT JOIN receiverdata r
        ON d.unique_key = r.unique_key
    JOIN bonddata b
        ON d.unique_key = b.unique_key
    WHERE r.unique_key IS NULL
    GROUP BY d.purchaser
)
SELECT COUNT(*) FROM Not_donated;
-- Another way of above query wit full report 
SELECT 
    COUNT(DISTINCT d.unique_key) AS number_of_bonds_not_donated,
    COUNT(DISTINCT d.purchaser) AS number_of_donors_not_donated,
    SUM(b.denominations) AS total_amount_not_donated
FROM donordata d
LEFT JOIN receiverdata r ON d.unique_key = r.unique_key
JOIN bonddata b ON d.unique_key = b.unique_key
WHERE r.unique_key IS NULL;
--
select 
      sum(Denominations) as "PM fund" 
from donordata as d 
left join receiverdata as r 
on r.unique_key=d.unique_key
join bonddata as b 
on b.unique_key=d.unique_key
where partyname is null;
--
CREATE VIEW donor_employee_performance AS (
 SELECT Payteller, COUNT(b.unique_key) AS "employee_bond_count", 
 SUM(Denominations) AS "employee_bond_amount"
 FROM donordata d
 JOIN bonddata b ON d.unique_key = b.unique_key
 GROUP BY Payteller
 ORDER BY employee_bond_count, employee_bond_amount
);
select * from donor_employee_performance;
-- 27.Find the employee ID who issued the highest number of bonds 
select 
      payteller,
	  employee_bond_count 
from donor_employee_performance 
where employee_bond_count=(
      select max(employee_bond_count)
      from donor_employee_performance
);
-- 28.Find the employee ID who issued the bonds for highest amount 
select 
     payteller,
	 employee_bond_amount 
from donor_employee_performance 
where employee_bond_amount=
    (select max(employee_bond_amount) 
     from donor_employee_performance
);
-- 29.Find the employee ID who issued the least number of bonds 
select 
	payteller,
	employee_bond_count 
from donor_employee_performance 
where employee_bond_count=(
    select min(employee_bond_count) 
    from donor_employee_performance
);
-- 30.Find the employee ID who issued the bonds for least amount
select 
	payteller,
	employee_bond_amount 
from donor_employee_performance 
where employee_bond_amount=(
	select min(employee_bond_amount) 
	from donor_employee_performance
);
/* creating view for employee  and receiver */
create view receiver_employee_performance as (
select payteller,count(r.unique_key) as "employee_bond_count",
sum(Denominations) as "employee_bond_amount" from receiverdata as r
join bonddata as b on r.unique_key=b.unique_Key group by payteller
);
select * from receiver_employee_performance;
-- 31. Find the employee ID who assisted in redeeming or encashing a bonds in higest number
-- [ receiverdata  bonddata]
select 
	payteller,
	employee_bond_count 
from receiver_employee_performance 
where employee_bond_count=(
	select max(employee_bond_count) from receiver_employee_performance);
-- 32. Find the employee ID who assisted in redeeming or encashing bonds for highest amount 
select
	payteller,
	employee_bond_amount 
from receiver_employee_performance 
where employee_bond_amount=(
	select max(employee_bond_amount) from receiver_employee_performance);
-- 33. Find the employee ID who assisted in redeeming or encashing a bonds in least number 
select 
	payteller,
	employee_bond_count 
from receiver_employee_performance 
where employee_bond_count=(
	select min(employee_bond_count) from receiver_employee_performance);
-- 34. Find the employee ID who assisted in redeeming or encashing bonds for least amount
select 
	payteller,
	employee_bond_amount 
from receiver_employee_performance 
where employee_bond_amount=(
	select min(employee_bond_amount) from receiver_employee_performance);
