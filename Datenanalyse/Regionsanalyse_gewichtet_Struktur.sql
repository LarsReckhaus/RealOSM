			with matching_points as (
				select a.region, a.structure, o.uuid
				from mapping_merge m, osm_merge o, areas a
				where o.cid=m.cid
					and o.aid=m.aid
					and m.aid=a.aid
			), correct_points(region, structure, tp) as (
				select ts.region, ts.structure, count(mp.uuid)::numeric
				from
					(select distinct a1.region, a1.structure
					from areas a1
					) as ts
				left join matching_points mp
					on ts.region=mp.region
						and ts.structure=mp.structure
				group by ts.region, ts.structure
			), missing_points(region, structure, fn) as (
				select ts.region, ts.structure, count(fn.uuid)::numeric
				from
					(select distinct a1.region, a1.structure
					from areas a1
					) as ts
				left join
				(select a2.region, a2.structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.uuid not in (
						select mp.uuid
						from matching_points mp
						)
				) as fn
					on ts.region=fn.region
						and ts.structure=fn.structure
				group by ts.region, ts.structure
			), false_points(region, structure, fp) as (
				select ts.region, ts.structure, count(fp.uuid)::numeric
				from
					(select distinct a1.region, a1.structure
					from areas a1
					) as ts
				left join
				(select a2.region, a2.structure, o2.uuid
				from osm_merge o2, areas a2
				where o2.aid=a2.aid
					and o2.uuid not in (
						select mp.uuid
						from matching_points mp
						)
				) as fp
					on ts.region=fp.region
						and ts.structure=fp.structure
				group by ts.region, ts.structure
			), osm_import (region, structure, osmimp) as (	
				select ts.region, ts.structure, count(oi.uuid)::numeric
				from
					(select distinct a1.region, a1.structure
					from areas a1
					) as ts
				left join
				(select a2.region, a2.structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='osmimp'
				) as oi
					on ts.region=oi.region
						and ts.structure=oi.structure
				group by ts.region, ts.structure
			), premapping (region, structure, premap) as (		
				select ts.region, ts.structure, count(pm.uuid)::numeric
				from
					(select distinct a1.region, a1.structure
					from areas a1
					) as ts
				left join
				(select a2.region, a2.structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='premap'
				) as pm
					on ts.region=pm.region
						and ts.structure=pm.structure
				group by ts.region, ts.structure
			), fieldmapping (region, structure, field) as (
				select ts.region, ts.structure, count(fm.uuid)::numeric
				from
					(select distinct a1.region, a1.structure
					from areas a1
					) as ts
				left join
				(select a2.region, a2.structure, m2.uuid
				from mapping_merge m2, areas a2
				where m2.aid=a2.aid
					and m2.source='field'
				) as fm
					on ts.region=fm.region
						and ts.structure=fm.structure
				group by ts.region, ts.structure
			)
			select cp.region,
				round(avg(tp/(tp+fn)),2) as "Com (sw)",
				round(avg(tp/(tp+fp)),2) as "Cor (sw)", 	
				round(avg(2*tp/(2*tp+fn+fp)),2) as "F1 (sw)",
				round(avg(1.25*tp/(1.25*tp+0.25*fn+fp)),2) as "F0,5 (sw)", 	
				round(avg(tp/(tp+fn+fp)),2) as "CSI (sw)"
			from correct_points cp, missing_points mp, false_points fp, osm_import oi, premapping pm, fieldmapping fm
			where cp.region=mp.region
				and mp.region=fp.region
				and fp.region=oi.region
				and oi.region=pm.region
				and pm.region=fm.region
				and cp.structure=mp.structure
				and mp.structure=fp.structure
				and fp.structure=oi.structure
				and oi.structure=pm.structure
				and pm.structure=fm.structure
			group by cp.region;