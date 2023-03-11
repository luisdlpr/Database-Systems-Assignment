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
select c.name, coalesce(sum(b.count), 0)::bigint
from countries c 
left join (
  select * from beer_count_by_country_id
) as b
on b.country = c.id
group by c.name-- replace this with your SQL code
;

-- Q4: Countries where the worst beers are brewed

-- put any Q4 helper views/functions here
-- create view ing_from_cze(name, id) as select i.name, i.id from ingredients i inner join (select c.id, c.code from countries c where c.code = 'CZE') as c on c.id = i.origin;
-- select by.beer, br.name, br.located_in from brewed_by by inner join (select id, name, located_in from breweries) br on by.brewery = br.id;
-- select b.beer, b.brewery_name, l.within from beer_by_location b inner join (select id, within from locations) as l on l.id = b.location;
-- select b.name, c.brewery_name, c.country from beer_by_country_id c inner join (select id, name from beers where rating < 3) b on b.id = c.beer;
-- select q.name, q.brewery, c.name from q4_cid q inner join (select id, name from countries) c on c.id = q.country;

create or replace view b_by_loc(b_id, brewery, l_id)
as 
select by.beer, br.name, br.located_in 
from brewed_by by
inner join (
  select id, name, located_in
  from breweries
) as br
on by.brewery = br.id
;

create or replace view b_by_c(b_id, brewery, c_id)
as
select b.b_id, b.brewery, l.within 
from b_by_loc b 
inner join (
  select id, within
  from locations
) as l
on l.id = b.l_id;

create or replace view b_by_c_filtered (beer, brewery, c_id)
as
select b.name, c.brewery, c.c_id
from b_by_c c
inner join (
  select id, name
  from beers
  where rating < 3
) as b
on b.id = c.b_id
;

create or replace view Q4(beer, brewery, country)
as
select q.beer, q.brewery, c.name
from b_by_c_filtered q
inner join (
  select id, name
  from countries
) c
on c.id = q.c_id
;

-- Q5: Beers that use ingredients from the Czech Republic

-- put any Q5 helper views/functions here
create or replace view ing_cze(i_id, name, itype, c_id)
as
select i.id, i.name, i.itype, i.origin
from ingredients as i
inner join (
  select id
  from countries
  where countries.code = 'CZE'
) as c
on c.id = i.origin
;

create or replace view b_id_cze(b_id, ingredient, itype)
as
select c.beer, i.name, i.itype
from contains c
inner join (
  select * from ing_cze
) as i
on i.i_id = c.ingredient;

create or replace view Q5(beer, ingredient, "type")
as
select b.name, i.ingredient, i.itype::IngredientType  -- replace this with your SQL code
from b_id_cze as i
inner join (
  select name, id
  from beers
) b 
on b.id = i.b_id
;

-- Q6: Beers containing the most used hop and the most used grain

-- put any Q6 helper views/functions here
-- count occurences of each ingredient
-- incorporate itype here instead to filter and name
create or replace view ing_freq(_count, ingredient)
as
select count(c.beer), c.ingredient
from contains as c
group by c.ingredient
;

create or replace view ing_freq_ext(_count, i_id, name, itype)
as
select f._count, f.ingredient, i.name, i.itype
from ing_freq as f
inner join (
  select i.name, i.itype, i.id
  from ingredients i
) as i
on f.ingredient = i.id
;

-- select most popular ing of each type
create or replace view most_popular_grain(id)
as
select i_id
from ing_freq_ext as i
right join (
  select max(_count), itype
  from ing_freq_ext
  where itype = 'grain'
  group by itype
) as g 
on g.max = i._count and g.itype = i.itype
;

-- get seperates then get union
create or replace view b_ids_w_pop_grain(b_id)
as
select c.beer
from contains c
inner join (
  select *
  from most_popular_grain
) as p 
on c.ingredient = p.id
;

-- select most popular ing of each type
create or replace view most_popular_hop(id)
as
select i_id
from ing_freq_ext as i
right join (
  select max(_count), itype
  from ing_freq_ext
  where itype = 'hop'
  group by itype
) as g 
on g.max = i._count and g.itype = i.itype
;

-- get seperates then get union
create or replace view b_ids_w_pop_hop(b_id)
as
select c.beer
from contains c
inner join (
  select *
  from most_popular_hop
) as p 
on c.ingredient = p.id
;-- select i_id from ing_freq_ext as i right join (select max(_count), itype from ing_freq_ext where itype = 'grain' or itype = 'hop' group by itype) as g on g.max = i._count and g.itype = i.itype;

-- select max(_count), itype from ing_freq_ext group by itype;
-- select max(_count) from ing_freq_ext where itype = 'grain' group by itype;

create or replace view Q6(beer)
as

select b.name
from beers b
inner join (
  select b_id from b_ids_w_pop_hop
  intersect
  select b_id from b_ids_w_pop_grain
) as p 
on p.b_id = b.id
;

-- Q7: Breweries that make no beer

-- put any Q7 helper views/functions here

create or replace view Q7(brewery)
as
select b.name
from breweries b
left join brewed_by by
on by.brewery = b.id
where by.brewery is null-- replace this with your SQL code
;

-- Q8: Function to give "full name" of beer

-- put any Q8 helper views/functions here

create or replace view brewery_name_by_beer(beer, brewery_name) as
select by.beer, string_agg(b.name, ' + ')
from brewed_by as by
inner join (
  select id, name
  from breweries
) as b
on by.brewery = b.id
group by by.beer
;

create or replace view beer_breweries(b_id, beer, brewery) as
select b.id, b.name, br.brewery_name
from beers b
inner join (
  select * 
  from brewery_name_by_beer
) as br
on br.beer = b.id;

-- given a beer id
-- obtain brewery: brewed by -> brewery.name, can use a helper view
-- process name
-- append beer name
-- select substring('Mountain Culture Beer Co' from '^(.*?)(Beer|Brew)')
create or replace function
        Q8(beer_id integer) returns text
as
$$
declare
  result text;
  beer text;
  brewery text;
begin
  select b.brewery, b.beer into brewery, beer
  from beer_breweries as b
  where beer_id = b.b_id;

  if beer is null then
    return 'No such beer';
  end if;

  result := REGEXP_REPLACE(brewery, ' (Beer|Brew).*$', '');

  if result like '' then
    result := brewery;
  end if;

  result := result || ' ' || beer;

  return result;


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

