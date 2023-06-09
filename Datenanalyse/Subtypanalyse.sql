			with matching_points as (
				select m.type, m.subtype, o.uuid
				from mapping_merge m, osm_merge o
				where o.cid=m.cid
					and o.aid=m.aid
			), correct_points(type, subtype, tp) as (
				select mp.type, mp.subtype, count(*)::numeric
				from matching_points mp
				group by mp.type, mp.subtype
				order by mp.type
			), missing_points(type, subtype, fn) as (
				select m1.type, m1.subtype, count(m2.uuid)::numeric
				from mapping_merge m1
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.uuid not in (
							select mp.uuid
							from matching_points mp
						)
				group by m1.type, m1.subtype
			), false_points(type, subtype, fp) as (
				select o1.type, o1.subtype, count(o2.uuid)::numeric
				from osm_merge o1
				left join osm_merge o2
					on o1.uuid=o2.uuid
						and o2.uuid not in (
							select mp.uuid
							from matching_points mp
						)
				group by o1.type, o1.subtype
			), osm_import (type, subtype, osmimp) as (				
				select m1.type, m1.subtype, count(m2.source)
				from mapping_merge m1
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.source='osmimp'
				group by m1.type, m1.subtype
			), premapping (type, subtype, premap) as (		
				select m1.type, m1.subtype, count(m2.source)
				from mapping_merge m1
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.source='premap'
				group by m1.type, m1.subtype
			), fieldmapping (type, subtype, field) as (
				select m1.type, m1.subtype, count(m2.source)
				from mapping_merge m1
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.source='field'
				group by m1.type, m1.subtype
			)
			select cp.type,
				cp.subtype,
				tp as "TP",
				fn as "FN",
				fp as "FP",
				tp+fn as "#mapped_points",
				osmimp as "-> #osmimp",
				premap as "-> #premap",
				field as "-> #field",
				tp+fp as "#osm_points",
				tp+fn+fp as "#all_points",
				round(tp/(tp+fn),2) as "Com", 
				round(tp/(tp+fp),2) as "Cor", 	
				round(2*tp/(2*tp+fn+fp),2) as "F1",
				round(1.25*tp/(1.25*tp+0.25*fn+fp),2) as "F0,5", 	
				round(tp/(tp+fn+fp),2) as "CSI"
			from correct_points cp, missing_points mp, false_points fp, osm_import oi, premapping pm, fieldmapping fm
			where cp.subtype=mp.subtype
				and mp.subtype=fp.subtype
				and fp.subtype=oi.subtype
				and oi.subtype=pm.subtype
				and pm.subtype=fm.subtype
			order by cp.type, cp.subtype;