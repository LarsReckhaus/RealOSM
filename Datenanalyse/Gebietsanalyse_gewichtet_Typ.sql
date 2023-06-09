			with matching_points as (
				select m.type, a.name, o.uuid
				from mapping_merge m, osm_merge o, areas a
				where o.cid=m.cid
					and o.aid=m.aid
					and m.aid=a.aid
			), correct_points(type, name, tp) as (
				select ts.type, ts.name, count(mp.uuid)::numeric
				from
					(select distinct m1.type, a1.name
					from mapping_merge m1, areas a1
					) as ts
				left join matching_points mp
					on ts.type=mp.type
						and ts.name=mp.name
				group by ts.type, ts.name
			), missing_points(type, name, fn) as (
				select ts.type, ts.name, count(fn.uuid)::numeric
				from
					(select distinct m1.type, a1.name
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.name, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.uuid not in (
						select mp.uuid
						from matching_points mp
						)
				) as fn
					on ts.type=fn.type
						and ts.name=fn.name
				group by ts.type, ts.name
			), false_points(type, name, fp) as (
				select ts.type, ts.name, count(fp.uuid)::numeric
				from
					(select distinct o1.type, a1.name
					from osm_merge o1, areas a1
					) as ts
				left join
				(select o2.type, a2.name, o2.uuid
				from osm_merge o2, areas a2
				where o2.aid=a2.aid
					and o2.uuid not in (
						select mp.uuid
						from matching_points mp
						)
				) as fp
					on ts.type=fp.type
						and ts.name=fp.name
				group by ts.type, ts.name
			), osm_import (type, name, osmimp) as (	
				select ts.type, ts.name, count(oi.uuid)::numeric
				from
					(select distinct m1.type, a1.name
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.name, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='osmimp'
				) as oi
					on ts.type=oi.type
						and ts.name=oi.name
				group by ts.type, ts.name
			), premapping (type, name, premap) as (		
				select ts.type, ts.name, count(pm.uuid)::numeric
				from
					(select distinct m1.type, a1.name
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.name, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='premap'
				) as pm
					on ts.type=pm.type
						and ts.name=pm.name
				group by ts.type, ts.name
			), fieldmapping (type, name, field) as (
				select ts.type, ts.name, count(fm.uuid)::numeric
				from
					(select distinct m1.type, a1.name
					from mapping_merge m1, areas a1
					) as ts
				left join
				(select m2.type, a2.name, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='field'
				) as fm
					on ts.type=fm.type
						and ts.name=fm.name
				group by ts.type, ts.name
			)
			select cp.name,
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
				and cp.name=mp.name
				and mp.name=fp.name
				and fp.name=oi.name
				and oi.name=pm.name
				and pm.name=fm.name
			group by cp.name
			order by "CSI (tw)" desc, cp.name;