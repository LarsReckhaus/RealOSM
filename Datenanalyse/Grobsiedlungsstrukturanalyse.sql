			with matching_points as (
				select a.rough_structure, o.uuid
				from mapping_merge m, osm_merge o, areas a
				where o.cid=m.cid
					and o.aid=m.aid
					and m.aid=a.aid
			), correct_points(rough_structure, tp) as (
				select mp.rough_structure, count(*)::numeric
				from matching_points mp
				group by mp.rough_structure
			), missing_points(rough_structure, fn) as (
				select a.rough_structure, count(m2.uuid)::numeric
				from mapping_merge m1
				inner join areas a
					on m1.aid=a.aid
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.uuid not in (
							select mp.uuid
							from matching_points mp
						)
				group by a.rough_structure
			), false_points(rough_structure, fp) as (
				select a.rough_structure, count(o2.uuid)::numeric
				from osm_merge o1
				inner join areas a
					on o1.aid=a.aid
				left join osm_merge o2
					on o1.uuid=o2.uuid
						and o2.uuid not in (
							select mp.uuid
							from matching_points mp
						)
				group by a.rough_structure
			), osm_import (rough_structure, osmimp) as (	
				select a.rough_structure, count(m2.source)
				from mapping_merge m1
				inner join areas a
					on m1.aid=a.aid
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.source='osmimp'
				group by a.rough_structure
			), premapping (rough_structure, premap) as (		
				select a.rough_structure, count(m2.source)
				from mapping_merge m1
				inner join areas a
					on m1.aid=a.aid
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.source='premap'
				group by a.rough_structure
			), fieldmapping (rough_structure, field) as (
				select a.rough_structure, count(m2.source)
				from mapping_merge m1
				inner join areas a
					on m1.aid=a.aid
				left join mapping_merge m2
					on m1.uuid=m2.uuid
						and m2.source='field'
				group by a.rough_structure
			)
			select cp.rough_structure,
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
			where cp.rough_structure=mp.rough_structure
				and mp.rough_structure=fp.rough_structure
				and fp.rough_structure=oi.rough_structure
				and oi.rough_structure=pm.rough_structure
				and pm.rough_structure=fm.rough_structure;