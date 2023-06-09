			with matching_points as (
				select a.structure, o.uuid
				from mapping_merge m, osm_merge o, areas a
				where o.cid=m.cid
					and o.aid=m.aid
					and m.aid=a.aid
			), correct_points(structure, tp) as (
				select mp.structure, count(*)::numeric
				from matching_points mp
				group by mp.structure
			), missing_points(structure, fn) as (
				select a.structure, count(m2.uuid)::numeric
				from mapping_merge m1
				inner join areas a
					on m1.aid=a.aid
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.uuid not in (
							select mp.uuid
							from matching_points mp
						)
				group by a.structure
			), false_points(structure, fp) as (
				select a.structure, count(o2.uuid)::numeric
				from osm_merge o1
				inner join areas a
					on o1.aid=a.aid
				left join osm_merge o2
					on o1.uuid=o2.uuid
						and o2.uuid not in (
							select mp.uuid
							from matching_points mp
						)
				group by a.structure
			), osm_import (structure, osmimp) as (	
				select a.structure, count(m2.source)
				from mapping_merge m1
				inner join areas a
					on m1.aid=a.aid
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.source='osmimp'
				group by a.structure
			), premapping (structure, premap) as (		
				select a.structure, count(m2.source)
				from mapping_merge m1
				inner join areas a
					on m1.aid=a.aid
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.source='premap'
				group by a.structure
			), fieldmapping (structure, field) as (
				select a.structure, count(m2.source)
				from mapping_merge m1
				inner join areas a
					on m1.aid=a.aid
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.source='field'
				group by a.structure
			)
			select cp.structure,
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
			where cp.structure=mp.structure
				and mp.structure=fp.structure
				and fp.structure=oi.structure
				and oi.structure=pm.structure
				and pm.structure=fm.structure
			order by tp+fn;