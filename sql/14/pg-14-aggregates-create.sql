--
-- After pg_upgrade let's recreate them
--

\c cs

CREATE FUNCTION public._final_median(anycompatible) RETURNS double precision
    LANGUAGE sql IMMUTABLE
    AS $_$ 
  WITH q AS
  (
     SELECT val
     FROM unnest($1) val
     WHERE VAL IS NOT NULL
     ORDER BY 1
  ),
  cnt AS
  (
    SELECT COUNT(*) AS c FROM q
  )
  SELECT AVG(val)::float8
  FROM 
  (
    SELECT val FROM q
    LIMIT  2 - MOD((SELECT c FROM cnt), 2)
    OFFSET GREATEST(CEIL((SELECT c FROM cnt) / 2.0) - 1,0)  
  ) q2;
$_$;

CREATE AGGREGATE public.median(anycompatible) (
    SFUNC = array_append,
    STYPE = anycompatiblearray,
    INITCOND = '{}',
    FINALFUNC = public._final_median
);

CREATE AGGREGATE gdriven.array_cat_agg(anycompatiblearray) (
    SFUNC = array_cat,
    STYPE = anycompatiblearray
);

ALTER AGGREGATE gdriven.array_cat_agg(anycompatiblearray) OWNER TO airflow_dwh;
ALTER FUNCTION public._final_median(anycompatible) OWNER TO postgres;
ALTER AGGREGATE public.median(anycompatible) OWNER TO postgres;
