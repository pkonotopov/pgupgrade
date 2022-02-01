--
-- Before pg_upgrdae we need to drop user defined aggregates
--

\c cs

drop aggregate gdriven.array_cat_agg (anyarray);
drop aggregate public.median (anyelement);
DROP FUNCTION public._final_median(anyarray);
