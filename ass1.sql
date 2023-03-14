-- COMP3311 23T1 Assignment 1
-- Luis Vicente De La Paz Reyes (z5206766)


-- Q1: amount of alcohol in the best beers
-- put any Q1 helper views/functions here
CREATE OR REPLACE VIEW Q1(beer, "sold in", alcohol)
AS
  SELECT 
    name,
    volume || 'ml ' || sold_in, 
    (volume * ABV / 100)::numeric(5, 1) || 'ml'
  FROM Beers
  WHERE rating > 9
;


-- Q2: beers that don't fit the ABV style guidelines
-- put any Q2 helper views/functions here
-- Beers (and their listed ABV's) mapped to the abv details of their styles.
CREATE OR REPLACE VIEW Beer_ABV_details(name, style, max_abv, min_abv, abv)
AS
  SELECT b.name, s.name, s.max_abv, s.min_abv, b.abv
  FROM Beers AS b
  FULL OUTER JOIN (
    SELECT *
    FROM Styles) AS s
  ON b.style = s.id
;

-- Formats the reason for an inacurate style into the required text for q2.
CREATE OR REPLACE FUNCTION generate_reason(
  max_abv ABVvalue, 
  min_abv ABVvalue, 
  abv ABVvalue
) RETURNS text AS 
  $$
    BEGIN
      IF (abv < min_abv) THEN
        RETURN 'too weak by ' || (min_abv - abv)::NUMERIC(3,1) || '%';
      ELSE
        RETURN 'too strong by ' || (abv - max_abv)::NUMERIC(3,1) || '%';
      END IF;
    END
  $$ LANGUAGE plpgsql
;

CREATE OR REPLACE VIEW Q2(beer, style, abv, reason)
AS
  SELECT name, style, abv, generate_reason(max_abv, min_abv, abv)
  FROM Beer_ABV_details
  WHERE abv > max_abv OR abv < min_abv
;

-- Q3: Number of beers brewed in each country
-- -- put any Q3 helper views/functions here
-- Beers (ids) by their Brewery + that Breweries Location (id).
CREATE OR REPLACE VIEW Beers_by_location(beer_id, brewery, location_id)
AS 
  SELECT _by.beer, br.name, br.located_in 
  FROM Brewed_by AS _by
  INNER JOIN (
    SELECT id, name, located_in
    FROM Breweries
  ) AS br
  ON _by.brewery = br.id
;

-- Beers (ids) and their Brewery + that Breweries Country (id).
CREATE OR REPLACE VIEW Beers_by_country(beer_id, brewery, country_id)
AS
  SELECT b.beer_id, b.brewery, l.within 
  FROM Beers_by_location AS b 
  INNER JOIN (
    SELECT id, within
    FROM Locations
  ) AS l
  ON l.id = b.location_id
;

CREATE OR REPLACE VIEW Q3(country, "#beers")
AS
  SELECT c.name, COALESCE(SUM(b.count), 0)::bigint
  FROM Countries AS c 
  LEFT JOIN (
    SELECT country_id, COUNT(beer_id)
    FROM Beers_by_country 
    GROUP BY country_id
  ) AS b
  ON b.country_id = c.id
  GROUP BY c.name
  ;

-- Q4: Countries where the worst beers are brewed
-- put any Q4 helper views/functions here
-- Beers (ids) and their countries (ids) filtered by rating < 3.
CREATE OR REPLACE VIEW Worst_beers_by_country (beer, brewery, country_id)
AS
  SELECT b.name, c.brewery, c.country_id
  FROM Beers_by_country AS c
  INNER JOIN (
    SELECT id, name
    FROM Beers
    WHERE rating < 3
  ) AS b
  ON b.id = c.beer_id
  ;

CREATE OR REPLACE VIEW Q4(beer, brewery, country)
AS
  SELECT q.beer, q.brewery, c.name
  FROM Worst_beers_by_country AS q
  INNER JOIN (
    SELECT id, name
    FROM Countries
  ) AS c
  ON c.id = q.country_id
;

-- Q5: Beers that use ingredients from the Czech Republic
-- put any Q5 helper views/functions here
-- ingredients and some details from CZE.
CREATE OR REPLACE VIEW Ingredients_CZE(ingredient_id, name, itype, country_id)
AS
  SELECT i.id, i.name, i.itype, i.origin
  FROM Ingredients AS i
  INNER JOIN (
    SELECT id
    FROM Countries
    WHERE Countries.code = 'CZE'
  ) AS c
  ON c.id = i.origin
;

-- Beers (ids) made with the ingredients from CZE
CREATE OR REPLACE VIEW Beers_CZE(beer_id, ingredient, itype)
AS
  SELECT c.beer, i.name, i.itype
  FROM Contains AS c
  INNER JOIN (
    SELECT * FROM Ingredients_CZE
  ) AS i
  ON i.ingredient_id = c.ingredient
;

CREATE OR REPLACE VIEW Q5(beer, ingredient, "type")
AS
  SELECT b.name, i.ingredient, i.itype::IngredientType
  FROM Beers_CZE AS i
  INNER JOIN (
    SELECT name, id
    FROM Beers
  ) b 
  ON b.id = i.beer_id
;

-- Q6: Beers containing the most used hop and the most used grain
-- put any Q6 helper views/functions here
-- frequency of beers that use an ingredient.
CREATE OR REPLACE VIEW Ingredient_frequency(_count, ingredient)
AS
  SELECT COUNT(c.beer), c.ingredient
  FROM Contains AS c
  GROUP BY c.ingredient
;

-- extended details of the ingredients from Ingredient_frequency.
CREATE OR REPLACE VIEW Ingredient_frequency_ext(
  _count,
  ingredient_id,
  name,
  itype
) AS
  SELECT f._count, f.ingredient, i.name, i.itype
  FROM Ingredient_frequency AS f
  INNER JOIN (
    SELECT i.name, i.itype, i.id
    FROM Ingredients i
  ) AS i
  ON f.ingredient = i.id
;

-- most popular ingredient of each type.
CREATE OR REPLACE VIEW Most_popular_by_type(id, itype)
AS
  SELECT i.ingredient_id, i.itype
  FROM Ingredient_frequency_ext AS i
  RIGHT JOIN (
    SELECT MAX(_count), itype
    FROM Ingredient_frequency_ext
    GROUP BY itype
  ) AS g 
  ON g.max = i._count AND g.itype = i.itype
;

-- function to return beers that contain the ingredient given.
CREATE OR REPLACE FUNCTION Beers_with_ingredient(ingredient_id integer) 
  RETURNS setof integer -- beer ids of relevant beers
AS
  $$
  BEGIN
      RETURN QUERY
      SELECT c.beer
      FROM Contains c
      WHERE c.ingredient = ingredient_id;
  END;
  $$ LANGUAGE plpgsql
;

CREATE OR REPLACE VIEW Q6(beer)
AS
  SELECT b.name
  FROM Beers b
  INNER JOIN (
    ( SELECT Beers_with_ingredient(id)
      FROM Most_popular_by_type 
      WHERE itype = 'hop'
    ) INTERSECT (
      SELECT Beers_with_ingredient(id) 
      FROM Most_popular_by_type 
      WHERE itype = 'grain' )
  ) AS p 
  ON p.Beers_with_ingredient = b.id
;

-- Q7: Breweries that make no beer
-- put any Q7 helper views/functions here
CREATE OR REPLACE VIEW Q7(brewery)
AS
  SELECT b.name
  FROM Breweries b
  LEFT JOIN brewed_by _by
  ON _by.brewery = b.id
  WHERE by.brewery IS NULL;

-- Q8: Function to give "full name" of beer
-- put any Q8 helper views/functions here
-- beers and their corresponding brewery
CREATE OR REPLACE VIEW Beers_by_brewery(beer_id, beer, brewery) AS
SELECT b.id, b.name, br.brewery
  FROM beers b
  INNER JOIN (
    SELECT * 
    FROM Beers_by_location
  ) AS br
  ON br.beer_id = b.id;

CREATE OR REPLACE FUNCTION
        Q8(beer_id integer) RETURNS text
AS
  $$
  DECLARE
    result text;
    beer text;
    brewery text;
  BEGIN
    SELECT 
      STRING_AGG(REGEXP_REPLACE(b.brewery, ' (Beer|Brew).*$', ''), ' + '), 
      b.beer 
      INTO brewery, beer
    FROM Beers_by_brewery AS b
    WHERE beer_id = b.beer_id
    GROUP BY b.beer;

    IF beer IS NULL THEN
      RETURN 'No such beer';
    END IF;

    result := brewery;

    IF result LIKE '' THEN
      result := b.brewery;
    END IF;

    result := result || ' ' || beer;

    RETURN result;
  END;
  $$ LANGUAGE plpgsql
;

-- Q9: Beer data based on partial match of beer name
DROP TYPE IF EXISTS BeerData CASCADE;
CREATE TYPE BeerData AS (beer text, brewer text, info text);
-- put any Q9 helper views/functions here
-- beers and matching ingredients (essentially extended contains table).
CREATE OR REPLACE VIEW Contains_ext(beer_id, ingredient_id, ingredient, itype) AS
  SELECT c.beer, c.ingredient, i.name, i.itype
  FROM Contains AS c
  INNER JOIN (
    SELECT *
    FROM Ingredients
  ) AS i
  ON i.id = c.ingredient
;

CREATE OR REPLACE FUNCTION Q9(partial_name text) returns setof BeerData
AS
  $$
  DECLARE
    m record;
    breweries text;
    itypes text[] := ARRAY['hop', 'grain', 'adjunct'];
    labels text[] := ARRAY['Hops: ', 'Grain: ', 'Extras: '];
    result text;
    temp text;
  BEGIN
    FOR m IN SELECT b.name, b.id
    FROM Beers b
    WHERE b.name ~ ('(?i).*' || partial_name || '*')
    LOOP
      SELECT STRING_AGG(brewery, ' + ' order by brewery)
      FROM Beers_by_brewery
      WHERE beer_id = m.id
      INTO breweries;

      result := '';

      FOR i IN 1..ARRAY_LENGTH(itypes, 1) LOOP
        temp := NULL;

        SELECT STRING_AGG(i_name, ',' ORDER BY ingredient)
        FROM Contains_ext
        WHERE beer_id = m.id AND itype::text = itypes[i] 
        INTO temp;

        IF temp IS NOT NULL THEN
          result := result || E'\n' || labels[i] || temp;
        END IF;
      END LOOP;

      IF SUBSTRING(result, 1, 1) = E'\n' THEN
        result := SUBSTRING(result, 2);
      END IF;

      RETURN NEXT (m.name, breweries, result)::BeerData;
    END LOOP;
  END;
  $$ LANGUAGE plpgsql
;

