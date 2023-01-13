(SELECT 'Composer', 'Dates', 'Works', 'Links', 'Cmps', 'Cat', 'Author', 'Description', 'Revue', 'Date', 'ComposerId', 'Id')
UNION
(SELECT p.full_name, p.life_dates, count(*) as 'works', 
    (SELECT count(*) FROM works as w2, works_to_publications as wpb2 
        where w2.person_id = w.person_id 
        and w2.id = wpb2.work_id
        and wpb2.publication_id = pb.id
        and link_status > 0) as 'links',
    (SELECT count(distinct w3.person_id) FROM works as w3, works_to_publications as wpb3
        where w3.id = wpb3.work_id
        and wpb3.publication_id = pb.id
        group by pb.id) as cmps,
    pb.short_name, pb.author, pb.description, pb.revue_title, pb.date, p.id, pb.id
    from works as w, people as p, publications as pb, works_to_publications as wpb
    where w.person_id = p.id 
    and w.id = wpb.work_id
    and wpb.publication_id = pb.id
    group by w.person_id, pb.id order by pb.id)
INTO OUTFILE '/Users/laurent/tmp/works-cat-stats.csv' 
FIELDS ENCLOSED BY '"'
TERMINATED BY '\t' 
LINES TERMINATED BY '\r\n';