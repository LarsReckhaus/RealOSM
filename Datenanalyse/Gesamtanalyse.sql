		with matching_points as (
			select o.uuid
			from mapping_merge m, osm_merge o
			where o.cid=m.cid
				and o.aid=m.aid
		), correct_points(tp) as (
			select count(*)::numeric
			from matching_points mp
		), missing_points(fn) as (
			select count(*)::numeric
			from mapping_merge m
			where m.uuid not in (
				select mp.uuid
				from matching_points mp
			)
		), false_points(fp) as (
			select count(*)::numeric
			from osm_merge o
			where o.uuid not in (
				select mp.uuid
				from matching_points mp
			)
		), osm_import (osmimp) as (
			select count(*)
			from mapping_merge m
			where m.source='osmimp'
		), premapping (premap) as (
			select count(*)
			from mapping_merge m
			where m.source='premap'
		), fieldmapping (field) as (
			select count(*)
			from mapping_merge m
			where m.source='field'
		)
		select tp as "TP",
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
		from correct_points, missing_points, false_points, osm_import, premapping, fieldmapping;