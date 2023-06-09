			with matching_points as (
				select m.type, a.region, o.uuid
				from mapping_merge m, osm_merge o, areas a
				where o.cid=m.cid
					and o.aid=m.aid
					and m.aid=a.aid
			), correct_points(type, region, tp) as (
				select ts.type, ts.region, count(mp.uuid)::numeric
				from
					(select distinct m1.type, a1.region
					from mapping_merge m1, areas a1
					) as ts  -- ts=table_structure
				left join matching_points mp
					on ts.type=mp.type
						and ts.region=mp.region
				group by ts.type, ts.region
			), missing_points(type, region, fn) as (
				select ts.type, ts.region, count(fn.uuid)::numeric
				from
					(select distinct m1.type, a1.region
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.region, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.uuid not in (
						select mp.uuid
						from matching_points mp
						)
				) as fn
					on ts.type=fn.type
						and ts.region=fn.region
				group by ts.type, ts.region
			), false_points(type, region, fp) as (
				select ts.type, ts.region, count(fp.uuid)::numeric
				from
					(select distinct o1.type, a1.region
					from osm_merge o1, areas a1
					) as ts
				left join
				(select o2.type, a2.region, o2.uuid
				from osm_merge o2, areas a2
				where o2.aid=a2.aid
					and o2.uuid not in (
						select mp.uuid
						from matching_points mp
						)
				) as fp
					on ts.type=fp.type
						and ts.region=fp.region
				group by ts.type, ts.region
			), osm_import (type, region, osmimp) as (	
				select ts.type, ts.region, count(oi.uuid)::numeric
				from
					(select distinct m1.type, a1.region
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.region, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='osmimp'
				) as oi  -- oi=osm_import
					on ts.type=oi.type
						and ts.region=oi.region
				group by ts.type, ts.region
			), premapping (type, region, premap) as (		
				select ts.type, ts.region, count(pm.uuid)::numeric
				from
					(select distinct m1.type, a1.region
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.region, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='premap'
				) as pm  -- pm=premapping
					on ts.type=pm.type
						and ts.region=pm.region
				group by ts.type, ts.region
			), fieldmapping (type, region, field) as (
				select ts.type, ts.region, count(fm.uuid)::numeric
				from
					(select distinct m1.type, a1.region
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.region, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='field'
				) as fm  -- fm=fieldmapping
					on ts.type=fm.type
						and ts.region=fm.region
				group by ts.type, ts.region
			)
			select cp.region, 
				round(avg(tp/nullif(tp+fn,0)),2) as "Com (tw)",
				round(avg(tp/nullif(tp+fp,0)),2) as "Cor (tw)", 	
				round(avg(2*tp/nullif(2*tp+fn+fp,0)),2) as "F1 (tw)",
				round(avg(1.25*tp/nullif(1.25*tp+0.25*fn+fp,0)),2) as "F0,5 (tw)", 	
				round(avg(tp/nullif(tp+fn+fp,0)),2) as "CSI (tw)"
			from correct_points cp, missing_points mp, false_points fp, osm_import oi, premapping pm, fieldmapping fm
			where cp.type=mp.type
				and mp.type=fp.type
				and fp.type=oi.type
				and oi.type=pm.type
				and pm.type=fm.type
				and cp.region=mp.region
				and mp.region=fp.region
				and fp.region=oi.region
				and oi.region=pm.region
				and pm.region=fm.region
			group by cp.region;