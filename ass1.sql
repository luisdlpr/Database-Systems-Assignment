-- COMP3311 23T1 Assignment 1

-- Q1: amount of alcohol in the best beers

-- put any Q1 helper views/functions here

create or replace view Q1(beer, "sold in", alcohol)
as
  SELECT 
    name,
    volume || 'ml ' || sold_in, 
    (volume * ABV / 100)::numeric(5, 1) || 'ml'
  FROM Beers
  WHERE rating > 9
;

-- Q2: beers that don't fit the ABV style guidelines

-- put any Q2 helper views/functions here
-- select b.name, s.max_abv, s.min_abv, b.abv from beers b full outer join styles s on b.style = s.id;
-- select name from (select b.name, s.max_abv, s.min_abv, b.abv from beers b full outer join styles s on b.style = s.id) as v where abv > max_abv or abv < min_abv;
create or replace view Beers_Styles_abv_details(name, style, max_abv, min_abv, abv) 
as
  SELECT b.name, s.name, s.max_abv, s.min_abv, b.abv
  FROM beers b
  FULL OUTER JOIN styles s
  on b.style = s.id
;

CREATE OR REPLACE function generate_reason(
  max_abv ABVvalue, 
  min_abv ABVvalue, 
  abv ABVvalue
) returns text
as $$
  begin
    if (abv < min_abv) then
      return 'too weak by ' || (min_abv - abv)::numeric(3,1) || '%';
    else
      return 'too strong by ' || (abv - max_abv)::numeric(3,1) || '%';
    end if;
  end
$$ language plpgsql;

create or replace view Q2(beer, style, abv, reason)
as
  SELECT name, style, abv, generate_reason(max_abv, min_abv, abv)
  FROM Beers_Styles_abv_details
  WHERE abv > max_abv OR abv < min_abv
;

-- Q3: Number of beers brewed in each country
-- select c.name, count(*) from countries c left join (select b.name, l.within from breweries b inner join (select * from locations) as l on b.located_in = l.id) as i on i.within = c.id group by id;
-- select count(bby.brewery), brew.id from brewed_by as bby right join (select name, id from breweries) as brew on brew.id = bby.brewery group by brew.id;

-- ass1=# select l.located_in, sum(b.count) from breweries l left join numBeersByBrewery as b on b.brewery = l.located_in group by l.located_in;
-- ass1=# select max(sum) from (select l.located_in, sum(b.count) from breweries l left join numBeersByBrewery as b on b.brewery = l.located_in group by l.located_in) as b;
--  max
-- -----
--   56
-- (1 row)

-- ass1=# se(select l.located_in, sum(b.count) from breweries l left join numBeersByBrewery as b on b.brewery = l.located_in group by l.located_in);
-- ass1=# create view numBeersByBrewery(brewery, count) as select brewery, count(beer) from brewed_by group by brewery;

-- select br.located_in, sum(be.count) from breweries as br left join (select * from numBeersByBrewery) as be on be.brewery = br.id group by br.located_in;
-- create view breweryBeerCount(location, count) as select br.located_in, sum(be.count) from breweries as br left join (select * from numBeersByBrewery) as be on be.brewery = br.id group by br.located_in;
-- create view numBeersCountryNN(country, count) as select l.within, sum(count) from locations as l right join (select * from breweryBeerCount) as b on b.location = l.id group by l.within;
-- select c.name, coalesce(sum(b.count), 0) from countries c left join (select * from numBeersCountryNN) as b on b.country = c.id group by c.name;
-- CREATE VIEW
-- -- put any Q3 helper views/functions here
create or replace view beer_count_by_brewery(brewery, count)
as
select brewery, count(beer)
from brewed_by
group by brewery;

create or replace view beer_count_by_location(location, count)
as
select br.located_in, sum(be.count)
from breweries as br
left join (select * from beer_count_by_brewery) as be 
on be.brewery = br.id
group by br.located_in
;

create or replace view beer_count_by_country_id(country, count)
as
select l.within, sum(count)
from locations as l
right join (
  select *
  from beer_count_by_location
) as b
on b.location = l.id
group by l.within
;

create or replace view Q3(country, "#beers")
as
select c.name, coalesce(sum(b.count))::bigint
from countries c 
left join (
  select * from beer_count_by_country_id
) as b
on b.country = c.id
group by c.name-- replace this with your SQL code
;

-- Q4: Countries where the worst beers are brewed

-- put any Q4 helper views/functions here

create or replace view Q4(beer, brewery, country)
as
select null, null, null  -- replace this with your SQL code
;

-- Q5: Beers that use ingredients from the Czech Republic

-- put any Q5 helper views/functions here

create or replace view Q5(beer, ingredient, "type")
as
select null, null, null::IngredientType  -- replace this with your SQL code
;

-- Q6: Beers containing the most used hop and the most used grain

-- put any Q6 helper views/functions here

create or replace view Q6(beer)
as
select null  -- replace this with your SQL code
;

-- Q7: Breweries that make no beer

-- put any Q7 helper views/functions here

create or replace view Q7(brewery)
as
select null  -- replace this with your SQL code
;

-- Q8: Function to give "full name" of beer

-- put any Q8 helper views/functions here

create or replace function
	Q8(beer_id integer) returns text
as
$$
begin
end;
$$ language plpgsql
;

-- Q9: Beer data based on partial match of beer name

drop type if exists BeerData cascade;
create type BeerData as (beer text, brewer text, info text);


-- put any Q9 helper views/functions here

create or replace function
	Q9(partial_name text) returns setof BeerData
as
$$
begin
end;
$$ language plpgsql
;

