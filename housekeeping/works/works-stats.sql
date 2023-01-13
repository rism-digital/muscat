(SELECT 'Composers','Dates','Works', 'GND', 'BNF', 'MBZ', 'all')
UNION 
(SELECT p.full_name, p.life_dates, count(*) as 'works', 
(SELECT count(*) FROM works as w2 where w2.person_id = w.person_id and link_status & 1) as 'gnd',
(SELECT count(*) FROM works as w2 where w2.person_id = w.person_id and link_status & 2) as 'bnf',
(SELECT count(*) FROM works as w2 where w2.person_id = w.person_id and link_status & 4) as 'mbz',
(SELECT count(*) FROM works as w2 where w2.person_id = w.person_id and link_status = 7) as 'all'
from works as w, people as p 
where w.person_id = p.id group by w.person_id order by works desc)
INTO OUTFILE '/Users/laurent/tmp/works-stats.csv' 
FIELDS ENCLOSED BY '"'
TERMINATED BY '\t' 
LINES TERMINATED BY '\r\n';