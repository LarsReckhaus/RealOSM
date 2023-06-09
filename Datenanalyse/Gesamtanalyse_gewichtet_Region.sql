		with matching_points as (
			select a.region, o.uuid
			from mapping_merge m, osm_merge o, areas a
			where o.cid=m.cid
				and o.aid=m.aid
				and m.aid=a.aid
		), correct_points(region, tp) as (
			select mp.region, count(*)::numeric
			from matching_points mp
			group by mp.region
		), missing_points(region, fn) as (
			select a.region, count(m2.uuid)::numeric
			from mapping_merge m1
			inner join areas a
				on m1.aid=a.aid
			left join mapping_merge m2
				on m1.uuid=m2.uuid
					and m2.uuid not in (
						select mp.uuid
						from matching_points mp
					)
			group by a.region
		), false_points(region, fp) as (
			select a.region, count(o2.uuid)::numeric
			from osm_merge o1
			inner join areas a
				on o1.aid=a.aid
			left join osm_merge o2
				on o1.uuid=o2.uuid
					and o2.uuid not in (
						select mp.uuid
						from matching_points mp
					)
			group by a.region
		), osm_import (region, osmimp) as (	
			select a.region, count(m2.source)
			from mapping_merge m1
			inner join areas a
				on m1.aid=a.aid
			left join mapping_merge m2
				on m1.uuid=m2.uuid
					and m2.source='osmimp'
			group by a.region
		), premapping (region, premap) as (		
			select a.region, count(m2.source)
			from mapping_merge m1
			inner join areas a
				on m1.aid=a.aid
			left join mapping_merge m2
				on m1.uuid=m2.uuid
					and m2.source='premap'
			group by a.region
		), fieldmapping (region, field) as (
			select a.region, count(m2.source)
			from mapping_merge m1
			inner join areas a
				on m1.aid=a.aid
			left join mapping_merge m2
				on m1.uuid=m2.uuid
					and m2.source='field'
			group by a.region	
		)
		select round(avg(tp/(tp+fn)),2) as "Com (rw)", -- rw=region-weighted -> Gleichgewichtung (arith. Mittel): jede Region 1/2 Einfluss
			round(avg(tp/(tp+fp)),2) as "Cor (rw)", 	
			round(avg(2*tp/(2*tp+fn+fp)),2) as "F1 (rw)",
			round(avg(1.25*tp/(1.25*tp+0.25*fn+fp)),2) as "F0,5 (rw)", 	
			round(avg(tp/(tp+fn+fp)),2) as "CSI (rw)"
		from correct_points cp, missing_points mp, false_points fp, osm_import oi, premapping pm, fieldmapping fm
		where cp.region=mp.region
			and mp.region=fp.region
			and fp.region=oi.region
			and oi.region=pm.region
			and pm.region=fm.region;