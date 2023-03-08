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
create or replace view Beers_Styles_abv_details(name, max_abv, min_abv, abv) 
as
  SELECT b.name, s.max_abv, s.min_abv, b.abv
  FROM beers b
  FULL OUTER JOIN styles s
  on b.style = s.id
;

create or replace view Q2(beer, style, abv, reason)
as
  SELECT name 
  FROM Beers_Styles_abs_details AS v
  WHERE abv > max_abv OR abv < min_abv
;

-- Q3: Number of beers brewed in each country

-- put any Q3 helper views/functions here

create or replace view Q3(country, "#beers")
as
select null, null::bigint  -- replace this with your SQL code
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

