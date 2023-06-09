			with matching_points as (
				select m.type, a.rough_structure, o.uuid
				from mapping_merge m, osm_merge o, areas a
				where o.cid=m.cid
					and o.aid=m.aid
					and m.aid=a.aid
			), correct_points(type, rough_structure, tp) as (
				select ts.type, ts.rough_structure, count(mp.uuid)::numeric
				from
					(select distinct m1.type, a1.rough_structure
					from mapping_merge m1, areas a1
					) as ts
				left join matching_points mp
					on ts.type=mp.type
						and ts.rough_structure=mp.rough_structure
				group by ts.type, ts.rough_structure
			), missing_points(type, rough_structure, fn) as (
				select ts.type, ts.rough_structure, count(fn.uuid)::numeric
				from
					(select distinct m1.type, a1.rough_structure
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.rough_structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.uuid not in (
						select mp.uuid
						from matching_points mp
						)
				) as fn
					on ts.type=fn.type
						and ts.rough_structure=fn.rough_structure
				group by ts.type, ts.rough_structure
			), false_points(type, rough_structure, fp) as (
				select ts.type, ts.rough_structure, count(fp.uuid)::numeric
				from
					(select distinct o1.type, a1.rough_structure
					from osm_merge o1, areas a1
					) as ts
				left join
				(select o2.type, a2.rough_structure, o2.uuid
				from osm_merge o2, areas a2
				where o2.aid=a2.aid
					and o2.uuid not in (
						select mp.uuid
						from matching_points mp
						)
				) as fp
					on ts.type=fp.type
						and ts.rough_structure=fp.rough_structure
				group by ts.type, ts.rough_structure
			), osm_import (type, rough_structure, osmimp) as (	
				select ts.type, ts.rough_structure, count(oi.uuid)::numeric
				from
					(select distinct m1.type, a1.rough_structure
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.rough_structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='osmimp'
				) as oi
					on ts.type=oi.type
						and ts.rough_structure=oi.rough_structure
				group by ts.type, ts.rough_structure
			), premapping (type, rough_structure, premap) as (		
				select ts.type, ts.rough_structure, count(pm.uuid)::numeric
				from
					(select distinct m1.type, a1.rough_structure
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.rough_structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='premap'
				) as pm
					on ts.type=pm.type
						and ts.rough_structure=pm.rough_structure
				group by ts.type, ts.rough_structure
			), fieldmapping (type, rough_structure, field) as (
				select ts.type, ts.rough_structure, count(fm.uuid)::numeric
				from
					(select distinct m1.type, a1.rough_structure
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.rough_structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='field'
				) as fm
					on ts.type=fm.type
						and ts.rough_structure=fm.rough_structure
				group by ts.type, ts.rough_structure
			)
			select cp.rough_structure,
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
				and cp.rough_structure=mp.rough_structure
				and mp.rough_structure=fp.rough_structure
				and fp.rough_structure=oi.rough_structure
				and oi.rough_structure=pm.rough_structure
				and pm.rough_structure=fm.rough_structure
			group by cp.rough_structure;