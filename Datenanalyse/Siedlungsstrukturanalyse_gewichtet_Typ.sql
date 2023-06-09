			with matching_points as (
				select m.type, a.structure, o.uuid
				from mapping_merge m, osm_merge o, areas a
				where o.cid=m.cid
					and o.aid=m.aid
					and m.aid=a.aid
			), correct_points(type, structure, tp) as (
				select ts.type, ts.structure, count(mp.uuid)::numeric
				from
					(select distinct m1.type, a1.structure
					from mapping_merge m1, areas a1
					) as ts
				left join matching_points mp
					on ts.type=mp.type
						and ts.structure=mp.structure
				group by ts.type, ts.structure
			), missing_points(type, structure, fn) as (
				select ts.type, ts.structure, count(fn.uuid)::numeric
				from
					(select distinct m1.type, a1.structure
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.uuid not in (
						select mp.uuid
						from matching_points mp
						)
				) as fn
					on ts.type=fn.type
						and ts.structure=fn.structure
				group by ts.type, ts.structure
			), false_points(type, structure, fp) as (
				select ts.type, ts.structure, count(fp.uuid)::numeric
				from
					(select distinct o1.type, a1.structure
					from osm_merge o1, areas a1
					) as ts
				left join
				(select o2.type, a2.structure, o2.uuid
				from osm_merge o2, areas a2
				where o2.aid=a2.aid
					and o2.uuid not in (
						select mp.uuid
						from matching_points mp
						)
				) as fp
					on ts.type=fp.type
						and ts.structure=fp.structure
				group by ts.type, ts.structure
			), osm_import (type, structure, osmimp) as (	
				select ts.type, ts.structure, count(oi.uuid)::numeric
				from
					(select distinct m1.type, a1.structure
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='osmimp'
				) as oi
					on ts.type=oi.type
						and ts.structure=oi.structure
				group by ts.type, ts.structure
			), premapping (type, structure, premap) as (		
				select ts.type, ts.structure, count(pm.uuid)::numeric
				from
					(select distinct m1.type, a1.structure
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='premap'
				) as pm
					on ts.type=pm.type
						and ts.structure=pm.structure
				group by ts.type, ts.structure
			), fieldmapping (type, structure, field) as (
				select ts.type, ts.structure, count(fm.uuid)::numeric
				from
					(select distinct m1.type, a1.structure
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='field'
				) as fm
					on ts.type=fm.type
						and ts.structure=fm.structure
				group by ts.type, ts.structure
			)
			select cp.structure,
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
				and cp.structure=mp.structure
				and mp.structure=fp.structure
				and fp.structure=oi.structure
				and oi.structure=pm.structure
				and pm.structure=fm.structure
			group by cp.structure
			order by "Cor (tw)" desc;