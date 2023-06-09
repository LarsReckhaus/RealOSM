		with matching_points as (
			select m.type, o.uuid
			from mapping_merge m, osm_merge o
			where o.cid=m.cid
				and o.aid=m.aid
		), correct_points(type, tp) as (
			select mp.type, count(*)::numeric
			from matching_points mp
			group by mp.type
		), missing_points(type, fn) as (
			select m1.type, count(m2.uuid)::numeric
			from mapping_merge m1
			left join mapping_merge m2
				on m1.uuid=m2.uuid
					and m2.uuid not in (
						select mp.uuid
						from matching_points mp
					)
			group by m1.type
		), false_points(type, fp) as (
			select o1.type, count(o2.uuid)::numeric
			from osm_merge o1
			left join osm_merge o2
				on o1.uuid=o2.uuid
					and o2.uuid not in (
						select mp.uuid
						from matching_points mp
					)
			group by o1.type
		), osm_import (type, osmimp) as (				
			select m1.type, count(m2.source)
			from mapping_merge m1
			left join mapping_merge m2
				on m1.uuid=m2.uuid
					and m2.source='osmimp'
			group by m1.type
		), premapping (type, premap) as (		
			select m1.type, count(m2.source)
			from mapping_merge m1
			left join mapping_merge m2
				on m1.uuid=m2.uuid
					and m2.source='premap'
			group by m1.type
		), fieldmapping (type, field) as (
			select m1.type, count(m2.source)
			from mapping_merge m1
			left join mapping_merge m2
				on m1.uuid=m2.uuid
					and m2.source='field'
			group by m1.type	
		)
		select round(avg(tp/(tp+fn)),2) as "Com (tw)", -- tw=type-weighted -> Gleichgewichtung (arith. Mittel): jeder Typ 1/11 Einfluss
			round(avg(tp/(tp+fp)),2) as "Cor (tw)", 	
			round(avg(2*tp/(2*tp+fn+fp)),2) as "F1 (tw)",
			round(avg(1.25*tp/(1.25*tp+0.25*fn+fp)),2) as "F0,5 (tw)", 	
			round(avg(tp/(tp+fn+fp)),2) as "CSI (tw)"
		from correct_points cp, missing_points mp, false_points fp, osm_import oi, premapping pm, fieldmapping fm
		where cp.type=mp.type
			and mp.type=fp.type
			and fp.type=oi.type
			and oi.type=pm.type
			and pm.type=fm.type;