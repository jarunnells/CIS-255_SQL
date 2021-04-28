--
-- console :: Recursion
--
-- SELECT * FROM ScenarioTwo.ConsumerComplaintsImport;
SELECT * FROM ScenarioTwo.consumercomplaintssanitized;
SELECT * FROM ScenarioTwo.TakataRecallImport;

--
-- **************************************************************************************************
--
SET @local_path = '/Users/jason-adm/Documents/OneDrive/Documents/AIMS/2021.SPRING/sql/assignments/scenarios/problem_03/localdata/';
SET @filename = 'file_system.csv';
SET @infile_str = CONCAT(@local_path,@filename); -- '/Users/jason-adm/Documents/OneDrive/Documents/AIMS/2021.SPRING/sql/assignments/scenarios/problem_03/localdata/file_system.csv'
SET @schema = 'ScenarioThree';
SET @tbl_name = 'TempTableIMP';

-- DROP DATABASE IF EXISTS ScenarioThree;
-- CREATE DATABASE IF NOT EXISTS ScenarioThree;

-- DROP TABLE IF EXISTS ScenarioThree.TempTableIMP;
CREATE TABLE IF NOT EXISTS ScenarioThree.TempTableIMP
(filedirid CHAR(4) UNIQUE
,filedirname VARCHAR(25)
,parentdir CHAR(4)
-- ,PRIMARY KEY (filedirid)
);

-- TRUNCATE TABLE ScenarioThree.TempTableIMP;
LOAD DATA LOCAL
INFILE 'path/to/file.csv'
INTO TABLE ScenarioThree.TempTableIMP
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

UPDATE ScenarioThree.TempTableIMP
SET parentdir = IF(parentdir LIKE '', NULL, parentdir);

SELECT * FROM ScenarioThree.TempTableIMP;
SELECT * FROM SSIExtra.ProdData;
SELECT * FROM SSIExtra.ProdPatch;

CREATE OR REPLACE VIEW ScenarioThree.path_list AS
(
    SELECT DISTINCT SUBSTRING(sourcefile, 1, LENGTH(sourcefile) - INSTR(REVERSE(sourcefile), '/')) AS FilePath
    FROM SSIExtra.ProdData
    UNION ALL
    SELECT DISTINCT SUBSTRING(patchfile, 1, LENGTH(patchfile) - INSTR(REVERSE(patchfile), '/')) AS FilePath
    FROM SSIExtra.ProdPatch
    ORDER BY FilePath
);
SELECT FilePath FROM ScenarioThree.path_list;

WITH RECURSIVE filedirs (filedirid, filedirname, parentdir, pathlevel, dir_str) AS
  (
    SELECT filedirid, filedirname, parentdir, 1 pathlevel, CAST(filedirname as CHAR(75)) dir_str
    FROM ScenarioThree.TempTableIMP
    WHERE parentdir IS NOT NULL
    UNION ALL
    SELECT tt.filedirid, tt.filedirname, tt.parentdir, fd.pathlevel+1, CONCAT_WS('/',tt.filedirname,dir_str)
    FROM ScenarioThree.TempTableIMP tt JOIN filedirs fd ON fd.parentdir = tt.filedirid
  )
SELECT DISTINCT SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  ) AS dir_path
FROM filedirs
WHERE dir_str IN (SELECT FilePath FROM ScenarioThree.path_list pl WHERE pl.FilePath = filedirs.dir_str)
# WHERE dir_str RLIKE '^[A-Z]:+' AND dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list pl WHERE pl.FilePath != filedirs.filedirname)
# WHERE dir_str RLIKE '^[A-Z]:+' AND dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list)
ORDER BY dir_path
;




WITH RECURSIVE filedirs (filedirid, filedirname, parentdir, pathlevel, dir_str) AS
  (
    SELECT filedirid, filedirname, parentdir, 1 pathlevel, CAST(filedirname as CHAR(75)) dir_str
    FROM ScenarioThree.TempTableIMP
    WHERE parentdir IS NOT NULL
    UNION ALL
    SELECT tt.filedirid, tt.filedirname, tt.parentdir, fd.pathlevel+1, CONCAT_WS('/',tt.filedirname,dir_str)
    FROM ScenarioThree.TempTableIMP tt JOIN filedirs fd ON fd.parentdir = tt.filedirid
  )
SELECT DISTINCT SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  ) AS dir_path
FROM filedirs
# WHERE dir_str RLIKE '^[A-Z]:+' AND dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list pl WHERE pl.FilePath != filedirs.filedirname)
WHERE dir_str RLIKE '^[A-Z]:+' AND dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list) or dir_str NOT IN (SELECT MAX(pathlevel) FROM filedirs)
ORDER BY dir_path
;




WITH RECURSIVE filedirs (filedirid, filedirname, parentdir, pathlevel, dir_str) AS
  (
    SELECT filedirid, filedirname, parentdir, 1 pathlevel, CAST(filedirname as CHAR(75)) dir_str
    FROM ScenarioThree.TempTableIMP
    WHERE parentdir IS NOT NULL
    UNION ALL
    SELECT tt.filedirid, tt.filedirname, tt.parentdir, fd.pathlevel+1, CONCAT_WS('/',tt.filedirname,dir_str)
    FROM ScenarioThree.TempTableIMP tt JOIN filedirs fd ON fd.parentdir = tt.filedirid
  )
SELECT DISTINCT SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  ) AS dir_path
FROM filedirs
WHERE dir_str RLIKE '^[A-Z]:+'
# ORDER BY dir_path
UNION DISTINCT
SELECT * FROM ScenarioThree.path_list
WHERE FilePath NOT IN (SELECT dir_str FROM filedirs)
ORDER BY dir_path
;

WITH RECURSIVE filedirs (filedirid, filedirname, parentdir, pathlevel, dir_str) AS
  (
    SELECT filedirid, filedirname, parentdir, 1 pathlevel, CAST(filedirname as CHAR(75)) dir_str
    FROM ScenarioThree.TempTableIMP
    WHERE parentdir IS NOT NULL
    UNION ALL
    SELECT tt.filedirid, tt.filedirname, tt.parentdir, fd.pathlevel+1, CONCAT_WS('/',tt.filedirname,dir_str)
    FROM ScenarioThree.TempTableIMP tt JOIN filedirs fd ON fd.parentdir = tt.filedirid
  )
SELECT DISTINCT SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  ) AS dir_path
FROM filedirs
WHERE dir_str RLIKE '^[A-Z]:+'
# WHERE dir_str IN (SELECT FilePath FROM ScenarioThree.path_list pl WHERE pl.FilePath != filedirs.filedirname)
# WHERE dir_str RLIKE '^[A-Z]:+' AND dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list pl WHERE pl.FilePath != filedirs.filedirname)
# WHERE dir_str RLIKE '^[A-Z]:+' AND dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list)
ORDER BY dir_path
;

WITH RECURSIVE filedirs (filedirid, filedirname, parentdir, pathlevel, dir_str) AS
  (
    SELECT filedirid, filedirname, parentdir, 1 pathlevel, CAST(filedirname as CHAR(75)) dir_str
    FROM ScenarioThree.TempTableIMP
    WHERE parentdir IS NOT NULL
    UNION ALL
    SELECT tt.filedirname, tt.filedirid, tt.parentdir, fd.pathlevel+1, CONCAT_WS('/',tt.filedirname,dir_str)
    FROM ScenarioThree.TempTableIMP tt JOIN filedirs fd ON fd.parentdir = tt.filedirid
  )
SELECT DISTINCT SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  ) AS dir_path
FROM filedirs
WHERE dir_str IN (SELECT MAX(pathlevel) FROM filedirs)
# WHERE dir_str RLIKE '^[A-Z]:+'
# WHERE dir_str IN (SELECT FilePath FROM ScenarioThree.path_list pl WHERE pl.FilePath != filedirs.filedirname)
# WHERE dir_str RLIKE '^[A-Z]:+' AND dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list pl WHERE pl.FilePath != filedirs.filedirname)
# WHERE dir_str RLIKE '^[A-Z]:+' AND dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list)
ORDER BY dir_path
;


WITH RECURSIVE filedirs (filedirid, filedirname, parentdir, pathlevel, dir_str) AS
  (
    SELECT filedirid, filedirname, parentdir, 1 pathlevel, CAST(filedirname as CHAR(75)) dir_str
    FROM ScenarioThree.TempTableIMP
    WHERE parentdir IS NOT NULL
    UNION ALL
    SELECT tt.filedirid, tt.filedirname, tt.parentdir, fd.pathlevel+1, CONCAT_WS('/',tt.filedirname,dir_str)
    FROM ScenarioThree.TempTableIMP tt JOIN filedirs fd ON fd.parentdir = tt.filedirid
  )
SELECT DISTINCT SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  ) AS dir_path
FROM filedirs
RIGHT JOIN ScenarioThree.path_list pl ON pl.FilePath = filedirs.dir_str
# WHERE dir_str RLIKE '^[A-Z]:+' AND dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list pl WHERE pl.FilePath != filedirs.filedirname)
WHERE dir_str RLIKE '^[A-Z]:+'
;

WITH RECURSIVE filedirs (filedirid, filedirname, parentdir, pathlevel, dir_str) AS
  (
    SELECT filedirid, filedirname, parentdir, 1 pathlevel, CAST(filedirname as CHAR(75)) dir_str
    FROM ScenarioThree.TempTableIMP
    WHERE parentdir IS NOT NULL
    UNION ALL
    SELECT tt.filedirid, tt.filedirname, tt.parentdir, fd.pathlevel+1, CONCAT_WS('/',tt.filedirname,dir_str)
    FROM ScenarioThree.TempTableIMP tt JOIN filedirs fd ON fd.parentdir = tt.filedirid
  )
SELECT DISTINCT @dir_str:=SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  ) AS dir_path
FROM filedirs
WHERE @dir_str RLIKE '^[A-Z]:+' AND @dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list pl WHERE pl.FilePath != filedirs.filedirname)
    UNION DISTINCT
SELECT * FROM ScenarioThree.path_list
# WHERE dir_str RLIKE '^[A-Z]:+' AND dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list pl WHERE pl.FilePath != filedirs.filedirname)
# WHERE dir_str RLIKE '^[A-Z]:+'
;


WITH RECURSIVE filedirs (filedirid, filedirname, parentdir, pathlevel, dir_str) AS
  (
    SELECT filedirid, filedirname, parentdir, 1 pathlevel, CAST(filedirname as CHAR(75)) dir_str
    FROM ScenarioThree.TempTableIMP
    WHERE parentdir IS NOT NULL
    UNION ALL
    SELECT tt.filedirid, tt.filedirname, tt.parentdir, fd.pathlevel+1, CONCAT_WS('/',tt.filedirname,dir_str)
    FROM ScenarioThree.TempTableIMP tt JOIN filedirs fd ON fd.parentdir = tt.filedirid
  )
SELECT DISTINCT SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  ) AS dir_path
FROM filedirs
WHERE (SELECT DISTINCT SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  )) RLIKE '^[A-Z]:+' AND (SELECT DISTINCT SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  )) NOT IN (SELECT FilePath FROM ScenarioThree.path_list)
ORDER BY dir_path;

WITH RECURSIVE filedirs (filedirid, filedirname, parentdir, pathlevel, dir_str) AS
  (
    SELECT filedirid, filedirname, parentdir, 1 pathlevel, CAST(filedirname as CHAR(75)) dir_str
    FROM ScenarioThree.TempTableIMP
    WHERE parentdir IS NOT NULL
    UNION ALL
    SELECT tt.filedirid, tt.filedirname, tt.parentdir, fd.pathlevel+1, CONCAT_WS('/',tt.filedirname,dir_str)
    FROM ScenarioThree.TempTableIMP tt JOIN filedirs fd ON fd.parentdir = tt.filedirid
  )
SELECT DISTINCT @dir_str:=SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  ) AS dir_path
FROM filedirs
WHERE @dir_str RLIKE '^[A-Z]:+' AND @dir_str NOT IN (SELECT FilePath FROM ScenarioThree.path_list pl WHERE pl.FilePath != filedirs.filedirname)
    UNION DISTINCT
SELECT * FROM ScenarioThree.path_list;



WITH RECURSIVE filedirs (filedirid, filedirname, parentdir, pathlevel, dir_str) AS
  (
    SELECT filedirid, filedirname, parentdir, 1 pathlevel, CAST(filedirname as CHAR(75)) dir_str
    FROM ScenarioThree.TempTableIMP
    WHERE parentdir IS NOT NULL
    UNION ALL
    SELECT tt.filedirid, tt.filedirname, tt.parentdir, fd.pathlevel+1, CONCAT_WS('/',tt.filedirname,dir_str)
    FROM ScenarioThree.TempTableIMP tt JOIN filedirs fd ON fd.parentdir = tt.filedirid
  )
SELECT DISTINCT @dir_str:=SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  ) AS dir_path
FROM filedirs
WHERE (SELECT DISTINCT SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  )) RLIKE '^[A-Z]:+' AND (SELECT DISTINCT SUBSTRING(dir_str, 1,
    LENGTH(dir_str) - INSTR(REVERSE(dir_str), '/')
  )) NOT IN (SELECT FilePath FROM ScenarioThree.path_list)
ORDER BY dir_path;

--
-- **************************************************************************************************************
--

--
-- console_1 ::
--
SELECT report_date, manufacturer, campaign, net_affected, net_remaining, completion_rate, cat_code
FROM ScenarioTwo.TakataRecallGraded
WHERE completion_rate <> 100 AND completion_rate >
  CASE cat_code
    WHEN 'NEAR COMPLETE' THEN 99
    WHEN 'UNDERWAY' THEN 89
    WHEN 'UNDERWAY' THEN 79
    WHEN 'UNDERWAY' THEN 69
    WHEN 'BEHIND' THEN 59
  END
ORDER BY report_date, manufacturer, campaign, completion_rate;

--
-- **************************************************************************************************************
--

--
-- console_4 :: Ranks...
--
-- ****************************************************************************
# -- ***** DEV-FINAL
# SELECT
#   prodcode AS ProdCode,
#   prodname AS ProdName,
#   COUNT(ticketnum) AS TotalTix,
#   GROUP_CONCAT(opendatetime ORDER BY opendatetime DESC SEPARATOR ', ') AS TixDates
# FROM SupportServices.Product
#   INNER JOIN SupportServices.TicketProduct USING (prodcode)
#   INNER JOIN SupportServices.Ticket USING (ticketnum)
# GROUP BY prodcode
# ;
#
-- ***** DEV-TEST
# WITH RecentTickets_3 AS (
#   SELECT
#     prodcode AS ProdCode,
#     prodname AS ProdName,
#     COUNT(ticketnum) AS TotalTix,
#     GROUP_CONCAT(left(opendatetime, 10) ORDER BY opendatetime DESC SEPARATOR ', ') AS TixDates,
#     GROUP_CONCAT(right(opendatetime, 8) ORDER BY opendatetime DESC SEPARATOR ', ') AS TixTimes,
#     GROUP_CONCAT(opendatetime ORDER BY opendatetime DESC SEPARATOR ', ') AS TixDateTime
#   FROM SupportServices.Product
#     INNER JOIN SupportServices.TicketProduct USING (prodcode)
#     INNER JOIN SupportServices.Ticket USING (ticketnum)
#   GROUP BY prodcode
# ) SELECT * FROM RecentTickets_3;

-- ****************************************************************************
-- ***** 1
# WITH RecentTickets_3 AS (
# SELECT prodcode, prodname, opendatetime
# FROM SupportServices.Product
#     INNER JOIN SupportServices.TicketProduct USING (prodcode)
#     INNER JOIN SupportServices.Ticket USING (ticketnum)
# )
# SELECT
#   DENSE_RANK() OVER
#     (PARTITION BY prodcode ORDER BY opendatetime DESC) AS rnk,
#   prodcode, prodname, opendatetime
# FROM RecentTickets_3
# ORDER BY prodcode ASC, opendatetime DESC
# ;
# -- ***** 2
# WITH RecentTickets_3 AS (
# SELECT prodcode, prodname, opendatetime
# FROM SupportServices.Product
#     INNER JOIN SupportServices.TicketProduct USING (prodcode)
#     INNER JOIN SupportServices.Ticket USING (ticketnum)
# )
# SELECT
#   DENSE_RANK() OVER
#     (PARTITION BY prodcode ORDER BY opendatetime DESC) AS rnk,
#   prodcode, prodname, opendatetime
# FROM RecentTickets_3
# ORDER BY prodcode ASC, opendatetime DESC
# ;
--
# WITH RecentTickets_3 AS (
# SELECT prodcode, prodname, opendatetime
# FROM SupportServices.Product
#     INNER JOIN SupportServices.TicketProduct USING (prodcode)
#     INNER JOIN SupportServices.Ticket USING (ticketnum)
# )
# SELECT
#   prodcode, prodname,
#   GROUP_CONCAT(opendatetime ORDER BY opendatetime DESC SEPARATOR ', ') AS TixDateTime
# FROM (
#     SELECT
#         DENSE_RANK() OVER
#             (PARTITION BY prodcode ORDER BY opendatetime DESC) AS rnk,
#         prodcode, prodname, opendatetime
#     FROM RecentTickets_3
#     ) t1
# WHERE rnk <= 3
# GROUP BY prodcode, opendatetime
# ORDER BY prodcode ASC, opendatetime DESC
# ;

-- CHECK-IT!!
WITH RecentTickets_3 AS (
SELECT prodcode, prodname, opendatetime
FROM SupportServices.Product
    INNER JOIN SupportServices.TicketProduct USING (prodcode)
    INNER JOIN SupportServices.Ticket USING (ticketnum)
)
SELECT
  prodcode, prodname,
  GROUP_CONCAT(LEFT(opendatetime,10) ORDER BY opendatetime DESC SEPARATOR ', ') AS TixDateTime
FROM (
    SELECT
        DENSE_RANK() OVER
            (PARTITION BY prodcode ORDER BY opendatetime DESC) AS rnk,
        prodcode, prodname, opendatetime
    FROM RecentTickets_3
    ) t1
WHERE rnk <= 3
GROUP BY prodcode
ORDER BY prodcode
;

-- ***** DEV-WORK
SELECT COUNT(ticketnum) AS TotalTix FROM SupportServices.TicketProduct GROUP BY prodcode

--
-- **************************************************************************************************************
--

--
-- console_5 ::
--
-- SET secure_file_priv := '/tmp/';
SET @TS := DATE_FORMAT(NOW(),'_%Y_%m_%d_%H_%i_%s');
SET @FLDR := './tmp/';
SET @PRFX := 'recent_ticekts';
SET @EXT := '.csv';
SET @FILE_PATH = concat(@FLDR,@PRFX,@TS,@EXT);

-- SELECT
--   @TS AS 'Time Stamp',
--   @FLDR AS Folder,
--   @PRFX AS Prefix,
--   @EXT AS Extension,
--   @FILE_PATH AS 'File Path'
-- ;

WITH recent_tix_3 AS (
  SELECT
    prodcode AS ProdCode,
    prodname AS ProdName,
    COUNT(ticketnum) AS TotalTix,
    GROUP_CONCAT(opendatetime ORDER BY opendatetime DESC SEPARATOR ', ') AS TixDates
  FROM SupportServices.Product
    INNER JOIN SupportServices.TicketProduct USING (prodcode)
    INNER JOIN SupportServices.Ticket USING (ticketnum)
  GROUP BY prodcode
) SELECT * FROM recent_tix_3;
-- (SELECT 'Product Code', 'Product Name', 'Total Tix', 'Opened On')
--   UNION
-- (SELECT * FROM recent_tix_3)
-- INTO OUTFILE "@FILE_PATH"
-- FIELDS ENCLOSED BY '"'
-- TERMINATED BY ';'
-- ESCAPED BY '"'
-- LINES TERMINATED BY '\r\n'
-- ;

--
-- **************************************************************************************************************
--

--
-- console_6 ::
--
-- ***** DEV-OUTPUT-TEMPLATE
WITH recent_tix_3 AS (
  SELECT
    prodcode AS ProdCode,
    prodname AS ProdName,
    COUNT(ticketnum) AS TotalTix,
    GROUP_CONCAT(opendatetime ORDER BY opendatetime DESC SEPARATOR ', ') AS TixDates
  FROM SupportServices.Product
    INNER JOIN SupportServices.TicketProduct USING (prodcode)
    INNER JOIN SupportServices.Ticket USING (ticketnum)
  GROUP BY prodcode
) SELECT * FROM recent_tix_3;

-- ALL-TIX-DATES
WITH TicketDates AS (
    SELECT
      ticketnum AS TicketNum,
      prodcode AS ProdCode,
      prodname AS ProdName,
      opendatetime AS OpenDate
    FROM SupportServices.Product
      INNER JOIN SupportServices.TicketProduct USING (prodcode)
      INNER JOIN SupportServices.Ticket USING (ticketnum)
    ORDER BY prodcode, ticketnum
) SELECT * FROM TicketDates;

-- RANK-DATES-TEST
WITH TicketDates AS (
    SELECT
        ticketnum AS TicketNum,
        prodcode AS ProdCode,
        prodname AS ProdName,
        t.opendatetime AS OpenDate
    FROM SupportServices.Product
        INNER JOIN SupportServices.TicketProduct USING (prodcode)
        INNER JOIN SupportServices.Ticket t USING (ticketnum)
    -- ORDER BY prodcode, ticketnum
)
SELECT
	dense_rank() OVER
		(PARTITION BY ticketnum, prodcode ORDER BY opendatetime DESC) DateRank,
    ticketnum AS TicketNum,
    prodcode AS ProdCode,
    prodname AS ProdName,
    opendatetime AS OpenDate
FROM TicketDates
INNER JOIN SupportServices.Ticket USING (ticketnum)
ORDER BY opendatetime
;

SELECT prodcode, prodname, opendatetime
FROM SupportServices.Product
    INNER JOIN SupportServices.TicketProduct USING (prodcode)
    INNER JOIN SupportServices.Ticket USING (ticketnum)
WHERE opendatetime IN
      (SELECT opendatetime
      FROM SupportServices.Ticket AS T2
      WHERE T2.opendatetime = SupportServices.Ticket.opendatetime
      ORDER BY opendatetime DESC
      LIMIT 3)
;

# =====


--
-- **************************************************************************************************************
--

--
-- console_8 ::
--
USE SupportServices;

# UPDATE SSIExtra.TEMP_RepCredential t_rc
# SET repid =
#     (SELECT repid
#     FROM SupportRep
#     WHERE CONCAT(SUBSTRING(repid FROM 1 FOR 1), SUBSTRING(repid, -4)) = t_rc.repid
#     );
#
SELECT * FROM SSIExtra.RepCredential;

-- ****************************************************************************************************
-- ****************************************************************************************************
-- ****************************************************************************************************

# SELECT IF(repid = 'DEVTEAM1', 'DEV01', CONCAT(SUBSTRING(repid FROM 1 FOR 1), SUBSTRING(repid, -4))) `repid`, repid
# FROM SupportServices.SupportRep
# ORDER BY repid
# ;
#
# SELECT
#        CASE repid
#        WHEN 'DEVTEAM1'
#           THEN 'DEV01'
#        ELSE CONCAT(SUBSTRING(repid FROM 1 FOR 1), SUBSTRING(repid, -4))
#        END `repid`, repid
# FROM SupportServices.SupportRep
# ORDER BY repid
# ;
#
# SELECT repid FROM SupportServices.SupportRep;
# SELECT * FROM SSIExtra.TEMP_RepCredential;
#
# SELECT
#        CASE repid
#        WHEN 'DEVTEAM1'
#           THEN 'DEV01'
#        ELSE CONCAT(SUBSTRING(repid FROM 1 FOR 1), SUBSTRING(repid, -4))
#        END `repid`, repid
# FROM SupportServices.SupportRep
# ORDER BY repid
# ;

# --------------------------------------------------------------------------------
# CREATE TABLE IF NOT EXISTS
#   SSIExtra.RepCredential_TEMP (repid char(8) PRIMARY KEY, reppw char(8));
# TRUNCATE TABLE SSIExtra.RepCredential_TEMP;

UPDATE SSIExtra.RepCredential_TEMP rc_t
JOIN SupportServices.SupportRep sr
  ON CONCAT(SUBSTRING(sr.repid FROM 1 FOR 1), SUBSTRING(sr.repid, -4)) = rc_t.repid
SET rc_t.repid = IF(rc_t.repid = 'DEV01', 'DEVTEAM1', sr.repid);

SELECT * FROM SSIExtra.RepCredential_TEMP;

UPDATE SSIExtra.RepCredential_TEMP rc_t
JOIN SupportServices.SupportRep sr
  ON CONCAT(SUBSTRING(sr.repid FROM 1 FOR 1), SUBSTRING(sr.repid, -4)) = rc_t.repid
SET rc_t.repid = IF(RPAD(rc_t.repid,3,'') = 'DEV01', 'DEVTEAM1', sr.repid);

SELECT * FROM SSIExtra.RepCredential_TEMP;

UPDATE SSIExtra.RepCredential_TEMP
SET repid = REGEXP_REPLACE(repid, 'DEV01 ?', 'DEVTEAM1');

SELECT * FROM SSIExtra.RepCredential_TEMP;




UPDATE SSIExtra.RepCredential_TEMP rc_t
SET repid =
    (SELECT repid
    FROM SupportServices.SupportRep sr
    WHERE CASE repid
            WHEN CONCAT(SUBSTRING(repid FROM 1 FOR 1), SUBSTRING(repid, -4)) THEN rc_t.repid
            ELSE REGEXP_REPLACE(repid, 'DEV01 ?', 'DEVTEAM1')
        END
    );

SELECT * FROM SSIExtra.RepCredential_TEMP;



UPDATE SSIExtra.RepCredential_TEMP rc_t
SET repid =
    (SELECT repid
    FROM SupportServices.SupportRep
    WHERE CONCAT(SUBSTRING(repid FROM 1 FOR 1), SUBSTRING(repid, -4)) = rc_t.repid
    );

UPDATE SSIExtra.RepCredential_TEMP rc_t
JOIN SupportServices.SupportRep sr
  ON CONCAT(SUBSTRING(sr.repid FROM 1 FOR 1), SUBSTRING(sr.repid, -4)) = rc_t.repid
SET rc_t.repid = sr.repid;
SELECT * FROM SSIExtra.RepCredential_TEMP;

# SELECT
       CASE repid
       WHEN 'DEVTEAM1'
          THEN 'DEV01'
       ELSE CONCAT(SUBSTRING(repid FROM 1 FOR 1), SUBSTRING(repid, -4))
       END `repid`, repid

UPDATE SSIExtra.RepCredential_TEMP rc_t
SET repid =
    (SELECT IF(repid = 'DEV01', REGEXP_REPLACE(repid, 'DEV01 ?', 'DEVTEAM1'),
               CONCAT(SUBSTRING(repid FROM 1 FOR 1), SUBSTRING(repid, -4)))
    FROM SupportServices.SupportRep sr
    );

SELECT * FROM SSIExtra.RepCredential_TEMP;

UPDATE SSIExtra.RepCredential_TEMP rc_t
JOIN SupportServices.SupportRep sr
  ON CONCAT(SUBSTRING(sr.repid FROM 1 FOR 1), SUBSTRING(sr.repid, -4)) = rc_t.repid
JOIN SupportServices.SupportRep sr ON IF(rc_t.repid = 'DEV01', 'DEVTEAM1', sr.repid)
SET rc_t.repid = sr.repid;

SELECT * FROM SSIExtra.RepCredential_TEMP;

--
-- **************************************************************************************************************
--

--
-- console_9 ::
--
-- USE SupportServices;

SELECT * FROM ScenarioTwo.ConsumerComplaintsImport;
SELECT * FROM ScenarioTwo.TakataRecallImport;

-- '^[A-Z]{2} [0-9]{5} [(]-?[0-9]+.[0-9]+, -?[0-9]+.[0-9]+[)]$' MATCHES -> 'CA 91423 (34.150612, -118.432469)'

SELECT ticket_id, -- not
       ticket_created, -- not
       date_created, -- not
       IF(date_of_issue IN ('None',''), NULL, date_of_issue) AS date_of_issue,
       IF(time_of_issue NOT RLIKE
          '^\d{1,2}:\d{1,2}[:space:]?|[:space:]?\d{2}[:space:]|[:space:]+[aApP].?[mM].?|[aApP].?[mM].?$',
           NULL,
           REGEXP_REPLACE(REGEXP_REPLACE(time_of_issue,' +',' '), 'am|a.m.|A.M.','')
           ) AS time_of_issue,
       form,
       IF(method IN ('None',''), NULL, method) AS method,
       IF(issue IN ('None',''), NULL, issue) AS issue,
       IF(caller_id_number IN ('None','') , NULL, caller_id_number) AS caller_id_number,
       IF(type_of_call_or_message IN ('None',''), NULL, type_of_call_or_message) AS type_of_call_or_message,
       IF(advertiser_business_number IN ('None',''), NULL, advertiser_business_number) AS advertiser_business_number,
       IF(city IN ('None',''), NULL, city) AS city,
       IF(state IN ('None',''), NULL, state) AS state,
       IF(zip IN ('None',''), NULL, zip) AS zip,
       IF(location IN ('None',''), NULL, REPLACE(location,'\n',' ')) AS location
FROM ScenarioTwo.ConsumerComplaintsImport
WHERE ticket_id IN (15737,18012,18097,18067,31977,93405,94591,68063,1624423,16965,43200,166059,364920,365462,395044,420604,395032,1266186,1448567,105789,106983,111886,113216)
# WHERE ticket_id IN (68063,1624423,16965,43200,166059,364920,365462,1266186,1448567,105789,106983,111886,113216)
# WHERE time_of_issue NOT IN ('None','')
ORDER BY ticket_id ASC
# LIMIT 1000
;

-- IF(form IN ('None',''), NULL, form) AS
--


# SELECT RIGHT(time_of_issue,INSTR(time_of_issue,' '))
# FROM ScenarioTwo.ConsumerComplaintsImport
# WHERE ticket_id = 1624423;

# SELECT * FROM ScenarioTwo.ConsumerComplaintsImport
# WHERE
#       ticket_id IN ('None','') OR
#       ticket_created IN ('None','') OR
#       date_created IN ('None','') OR
#       date_of_issue IN ('None','') OR
#       time_of_issue IN ('None','') #OR
#       form IN ('None','') OR
#       method IN ('None','') OR
#       issue IN ('None','') OR
#       caller_id_number IN ('None','') OR
#       type_of_call_or_message IN ('None','') OR
#       advertiser_business_number IN ('None','') OR
#       city IN ('None','') OR
#       state IN ('None','') OR
#       zip IN ('None','') OR
#       location IN ('None','')
# ;

SELECT ticket_id, time_of_issue FROM ScenarioTwo.ConsumerComplaintsImport
WHERE time_of_issue NOT RLIKE '^\d{1,2}:\d{2}[ ]+[aApP]\.[mM]\.$'
; -- MATCHES -> ( 3:24 P.M. | 10:45 A.M. )

SELECT ticket_id, time_of_issue FROM ScenarioTwo.ConsumerComplaintsImport
WHERE time_of_issue NOT RLIKE '^\d{1,2}:\d{2}[ ]+[aApP][mM]$'
; -- MATCHES -> ( 4:57 PM | 12:36 AM )

SELECT ticket_id, time_of_issue FROM ScenarioTwo.ConsumerComplaintsImport
WHERE time_of_issue NOT RLIKE '^\d{1,2}:\d{2}[ ]+\d{2}[ ]+[aApP]\.[mM]\.$'
; -- MATCHES -> ( 10:45 00 A.M. | 11:39 00 P.M. )

SELECT ticket_id, time_of_issue FROM ScenarioTwo.ConsumerComplaintsImport
WHERE time_of_issue NOT RLIKE '^\d{1,2}:\d{2}[ ][aApP][,\.][mM][,\.]$'
; -- MATCHES -> ( 3:43 p,m. | 10:45 A.M. )

-- '^\d{1,2}:\d{1,2}[ ]{2,}[aApP].[mM].$' :: MATCHES -> ( 8:56                p.m. )

SELECT ticket_id,
#        time_of_issue,
       IF(time_of_issue = time_of_issue REGEXP '^[:space:]+$', NULL, time_of_issue) AS time_of_issue
FROM ScenarioTwo.ConsumerComplaintsImport
;

SELECT ticket_id,
       IF(time_of_issue IN ('None','',' '), NULL,
           CONCAT_WS(' ',
               SUBSTR(time_of_issue FROM 1 FOR INSTR(time_of_issue,' ')-1),
               RIGHT(time_of_issue,INSTR(time_of_issue,' ')-1)
               )
           ) AS time_of_issue
FROM ScenarioTwo.ConsumerComplaintsImport
WHERE ticket_id IN (68063,1624423,16965,43200,166059,364920,365462,1266186,1448567,105789,106983,111886,113216)
;

SELECT ticket_id,
       IF(caller_id_number IN ('None','') , NULL, caller_id_number) AS caller_id_number
FROM ScenarioTwo.ConsumerComplaintsImport
WHERE ticket_id IN (68063,1624423,16965,43200,166059,364920,365462,1266186,1448567,105789,106983,111886,113216)
;

SELECT ticket_id,
        caller_id_number,
       time_of_issue
FROM ScenarioTwo.ConsumerComplaintsImport WHERE ticket_id IN (68063)
;

-- '^\d{1,2}:\d{1,2}([ ]+[aApP].?[mM].?|[ ]\d{2}[ ][aApP].?[mM].?|[ ]?[aApP].?[mM].?)$'
-- '^\d{1,2}:\d{1,2}([ ]+|[ ]\d{2}[ ]|[aApP].?[mM].?)?([aApP].?[mM].?)$'
-- '^(\d{1,2}:\d{1,2})([ ]+|[ ]\d{2}[ ]|[aApP].?[mM].?)?([aApP].?[mM].?)$'
-- '^\d{1,2}:\d{1,2}[ ]?|[ ]?\d{2}[ ]|[ ]+[aApP].?[mM].?|[aApP].?[mM].?$'

SELECT ticket_id,
       caller_id_number,
       time_of_issue,
       REGEXP_SUBSTR(time_of_issue,'^\d{1,2}:\d{1,2}[:space:]?|[:space:]?\d{2}[:space:]|[:space:]+[aApP].?[mM].?|[aApP].?[mM].?$') time_of_issue
FROM ScenarioTwo.ConsumerComplaintsImport
WHERE ticket_id IN (31977,31982,32463,33215,34693,34742,35075);

SELECT ticket_id,
       caller_id_number,
       time_of_issue,
       REGEXP_SUBSTR(time_of_issue,'^\d{1,2}:\d{1,2}')
FROM ScenarioTwo.ConsumerComplaintsImport
# WHERE ticket_id IN (31977,31982,32463,33215,34693,34742,35075)
;

SELECT ticket_id,
       caller_id_number,
       time_of_issue
FROM ScenarioTwo.ConsumerComplaintsImport
WHERE time_of_issue RLIKE '^\d{1,2}:\d{1,2}[:space:]?|[:space:]?\d{2}[:space:]|[:space:]+[aApP].?[mM].?|[aApP].?[mM].?$'
AND ticket_id IN (15737,18012,18097,18067,31977,93405,94591,68063,1624423,16965,43200,166059,364920,365462,395044,420604,395032,1266186,1448567,105789,106983,111886,113216)
# WHERE ticket_id IN (15737,18012,18097,18067,31977,93405,94591,68063,1624423,16965,43200,166059,364920,365462,395044,420604,395032,1266186,1448567,105789,106983,111886,113216)
;


SELECT ticket_id,
       caller_id_number,
       time_of_issue
FROM ScenarioTwo.ConsumerComplaintsImport
WHERE ticket_id = 1624423
;


SELECT ticket_id,
       -- time_of_issue,
       IF(time_of_issue NOT RLIKE '^\d{1,2}:\d{1,2}[:space:]?|[:space:]?\d{2}[:space:]|[:space:]+[aApP].?[mM].?|[aApP].?[mM].?$', NULL,
           REGEXP_REPLACE(
               REGEXP_REPLACE(
                   REGEXP_REPLACE(
                       time_of_issue,' +',' ')
                   , ' ?[aA].?[mM].?', ' AM')
               , ' ?[pP].?[mM].?',' PM')
#            time_of_issue
           ) AS time_of_issue,
       IF(method IN ('None',''), NULL, method) AS method,
       REPLACE(location,'\n',' ') AS location
FROM ScenarioTwo.ConsumerComplaintsImport
WHERE ticket_id IN (15737,18012,18097,18067,31977,93405,94591,68063,1624423,16965,43200,166059,364920,365462,395044,420604,395032,1266186,1448567,105789,106983,111886,113216)
# ORDER BY ticket_id LIMIT 25
;

--
-- **************************************************************************************************************
--

--
-- console_Assignment ::
--
-- ASSIGNMENT 06
-- USE SupportServices;

-- APPEND CONFIRM NUMS
-- ALTER TABLE SupportServices.Customer ADD confirmationnum VARCHAR(10);
-- UPDATE SupportServices.Customer SET Customer.confirmationnum = TRUNCATE(RAND()*10000000000,0);
-- SELECT custnum, confirmationnum FROM SupportServices.Customer;


-- TEST TABLE
-- CREATE TABLE SupportServices.CustomerDataEncrypted LIKE SupportServices.Customer;
-- INSERT SupportServices.CustomerDataEncrypted SELECT * FROM SupportServices.Customer;
-- SELECT * FROM SupportServices.CustomerDataEncrypted;
-- RECOVERY
-- DROP TABLE SupportServices.CustomerDataEncrypted;
-- SETUP -> LECTURE
# ALTER TABLE SupportServices.CustomerDataEncrypted MODIFY contactphone BLOB, MODIFY contactemail BLOB;
# UPDATE SupportServices.CustomerDataEncrypted SET contactphone = AES_ENCRYPT(contactphone,custname);
# SELECT custnum,
#        CAST(contactphone AS CHAR) encphone,
#        CAST(AES_DECRYPT(contactphone,custname) AS CHAR) phonenum
# FROM SupportServices.CustomerDataEncrypted;

-- #1 [ x ]
-- SETUP -> BLOB
ALTER TABLE SupportServices.CustomerDataEncrypted MODIFY contactemail BLOB;
-- TEST ENCRYPTION | DECRYPTION
WITH test_encrypt AS ( SELECT custnum, contactemail,confirmationnum, CAST(AES_ENCRYPT(contactemail,confirmationnum) AS CHAR) AS E_contactemail FROM SupportServices.CustomerDataEncrypted )
SELECT custnum, E_contactemail,
       CAST(AES_DECRYPT(E_contactemail,confirmationnum) AS CHAR) AS D_contactemail
FROM test_encrypt;
-- APPLY ENCRYPTION
UPDATE SupportServices.CustomerDataEncrypted SET contactemail = AES_ENCRYPT(contactemail,confirmationnum);
-- VERIFY ENCRYPTION | DECRYPTION
SELECT custnum,
       CAST(contactemail AS CHAR) AS E_contactemail,
       CAST(AES_DECRYPT(contactemail,confirmationnum) AS CHAR) AS D_contactemail
FROM SupportServices.CustomerDataEncrypted;


-- #2 [ x ]
SELECT custname,
       CAST(AES_DECRYPT(contactphone,custname) AS CHAR) AS D_contactphone,
       CAST(AES_DECRYPT(contactemail,confirmationnum) AS CHAR) AS D_contactemail
FROM SupportServices.CustomerDataEncrypted
WHERE custname IN ('Dev Null, Inc.');


-- #3 [ x ]
-- ALTER TABLE SupportServices.SupportRep ADD pskslt VARCHAR(16);
-- UPDATE SupportServices.SupportRep SET SupportRep.pskslt = HEX(repid);
-- UPDATE SupportServices.SupportRep SET SupportRep.pskslt = TRUNCATE(RAND()*100000000000000,0);
ALTER TABLE SupportServices.SupportRep MODIFY pskslt VARCHAR(32);
-- UPDATE SupportServices.SupportRep SET SupportRep.pskslt = UUID_SHORT();
UPDATE SupportServices.SupportRep SET SupportRep.pskslt = REPLACE(UUID(),'-','');
SELECT repid, pskslt FROM SupportServices.SupportRep;

-- #4 [ - ]
SELECT * FROM SSIExtra.RepCredential;
ALTER TABLE SSIExtra.RepCredential ADD reppsk VARCHAR(256);
-- TEST HASH | DECRYPTION
WITH test_pw_encrypt AS (
    SELECT repid, reppw, sr.pskslt, SHA1(CONCAT(reppw, sr.pskslt)) AS pskhash
    FROM SSIExtra.RepCredential
    JOIN SupportServices.SupportRep sr USING (repid)
) SELECT repid, reppw, pskslt, pskhash
FROM test_pw_encrypt;
-- ALTER TBL
UPDATE SSIExtra.RepCredential
JOIN SupportServices.SupportRep USING(repid)
SET reppsk = SHA1(CONCAT(reppw, pskslt));
SELECT repid,reppsk FROM SSIExtra.RepCredential;

WITH _uuid AS (
    SELECT
           -- UUID() AS uuid_get
           '58eb4342-9095-11eb-a882-bbb660bb8c8c' AS uuid_,
           -- REPLACE(UUID(),'-','') AS uuid_strip
           REPLACE('58eb4342-9095-11eb-a882-bbb660bb8c8c','-','') AS uuid_strip,
           -- 58eb4342909511eba882bbb660bb8c8c
           UUID_TO_BIN('58eb4342-9095-11eb-a882-bbb660bb8c8c') AS uuid_bin
) SELECT
         uuid_,uuid_strip,uuid_bin,
         BIN_TO_UUID(uuid_bin)
FROM _uuid;

-- #5 [ x ]
SELECT repid, repfname, replname
FROM SupportServices.SupportRep
JOIN SSIExtra.RepCredential USING (repid)
WHERE reppsk = SHA1(CONCAT('B3Qgc!Ke', pskslt));


SELECT * FROM SupportServices.CustomerDataEncrypted;
SELECT * FROM SupportServices.Customer;

SELECT * FROM SupportServices.CustomerDataEncrypted;
SELECT * FROM SupportServices.CustomerDataEncrypted2;

ALTER TABLE SupportServices.CustomerDataEncrypted2 MODIFY contactphone BLOB, MODIFY contactemail BLOB;

UPDATE SupportServices.CustomerDataEncrypted2 e2
JOIN SupportServices.CustomerDataEncrypted e1 USING (custnum)
    SET e2.contactphone = e1.contactphone,
        e2.contactemail = e1.contactemail;

SELECT * FROM SupportServices.CustomerDataEncrypted;
SELECT * FROM SupportServices.CustomerDataEncrypted2;

--
-- **************************************************************************************************************
--

--
-- console_DEV ::
--

-- SupportServices.CorrectNameCaps
-- SupportServices.CommentCountByRepID

-- [2]
-- [EVEN>48]
SELECT ticketnum, custnum,
       timestampdiff(
           second, opendatetime, closedatetime) / (60 * 60) AS timeopen, -- in hours
       opendatetime, closedatetime
FROM SupportServices.Ticket
WHERE custnum BETWEEN 1 AND 17
  AND mod(custnum, 2) = 0
  AND timestampdiff(second, opendatetime, closedatetime) / (60 * 60) > 48
ORDER BY custnum;

-- [ODD>72]
SELECT ticketnum, custnum,
       timestampdiff(
           second, opendatetime, closedatetime) / (60 * 60) AS timeopen, -- in hopurs
       opendatetime, closedatetime
FROM SupportServices.Ticket
WHERE custnum BETWEEN 1 AND 17
  AND mod(custnum, 2) = 1
  AND timestampdiff(second, opendatetime, closedatetime) / (60 * 60) > 72
ORDER BY custnum;

-- [>120]
SELECT ticketnum, custnum,
       timestampdiff(
           second, opendatetime, closedatetime) / (60 * 60) AS timeopen, -- in hours
       opendatetime, closedatetime
FROM SupportServices.Ticket
WHERE timestampdiff(second, opendatetime, closedatetime) / (60 * 60) > 120
ORDER BY custnum;

-- [ALL]
SELECT ticketnum, custnum,
       timestampdiff(
           second, opendatetime, closedatetime) / (60 * 60) AS timeopen -- in hours
FROM SupportServices.Ticket
WHERE (custnum BETWEEN 1 AND 17
           AND mod(custnum, 2) = 0
           AND timestampdiff(second, opendatetime, closedatetime) / (60 * 60) > 48)
   OR (custnum BETWEEN 1 AND 17
           AND mod(custnum, 2) = 1
           AND timestampdiff(second, opendatetime, closedatetime) / (60 * 60) > 72)
   OR (timestampdiff(second, opendatetime, closedatetime) / (60 * 60) > 120)
ORDER BY ticketnum;


-- #2 [ - ]
SELECT ticketnum, custnum,
       timestampdiff(
           second, opendatetime, closedatetime) / (60 * 60) AS timeopen -- in hours
FROM SupportServices.Ticket
WHERE (custnum BETWEEN 1 AND 17
           AND mod(custnum, 2) = 0
           AND timestampdiff(second, opendatetime, closedatetime) / (60 * 60) > 48)
   OR (custnum BETWEEN 1 AND 17
           AND mod(custnum, 2) = 1
           AND timestampdiff(second, opendatetime, closedatetime) / (60 * 60) > 72)
   OR (timestampdiff(second, opendatetime, closedatetime) / (60 * 60) > 120)
ORDER BY ticketnum;

SELECT ticketnum, custnum,
       timestampdiff(
           second, opendatetime, closedatetime) / (60 * 60) AS timeopen -- in hours
FROM SupportServices.Ticket
WHERE timestampdiff(second, opendatetime, closedatetime) / (60 * 60) >
    AND custnum BETWEEN
        CASE mod(custnum, 2)
            WHEN 1 AND 17 THEN 48
            WHEN 1 AND 17 THEN 72
            ELSE 120
        END;


SELECT custnum, contactemail
FROM SupportServices.Customer
-- ORDER BY custnum
;

SELECT custnum, contactemail
FROM SupportServices.Customer
WHERE SUBSTRING(contactemail, INSTR(contactemail, '@')) LIKE '%@smail.com'
ORDER BY custnum;

SELECT a.custnum, a.contactemail,
       b.custnum, b.contactemail
FROM SupportServices.Customer a
JOIN SupportServices.Customer b
	ON a.custnum + 1 = b.custnum
WHERE SUBSTRING(a.contactemail, INSTR(a.contactemail, '@'))
          LIKE SUBSTRING(b.contactemail, INSTR(b.contactemail, '@'))
ORDER BY a.custnum;

--
-- **************************************************************************************************************
--

--
-- console_TEST ::
--
USE SupportServices;

-- [ LIKE ESCAPES ]
SELECT custname, contactemail
FROM Customer
WHERE contactemail LIKE '%_%';  -- not escaped (returns all)

SELECT custname, contactemail
FROM Customer
WHERE contactemail LIKE '%\_%';  -- escaped

SELECT custname, contactemail
FROM Customer
WHERE contactemail LIKE '%|_%' ESCAPE '|';  -- explicit ESCAPE phrase

SELECT
	ticketnum, priority,
	timestampdiff(second,opendatetime,closedatetime)/(60*60) timeopen
FROM Ticket
WHERE (timestampdiff(second,opendatetime,closedatetime)/(60*60) > 8 AND priority = 'HIGH')
   OR (timestampdiff(second,opendatetime,closedatetime)/(60*60) > 24 AND priority = 'MED')
   OR (timestampdiff(second,opendatetime,closedatetime)/(60*60) > 48 AND priority = 'LOW');

SELECT
	ticketnum, priority,
	timestampdiff(second,opendatetime,closedatetime)/(60*60) timeopen
FROM Ticket
WHERE timestampdiff(second,opendatetime,closedatetime)/(60*60) >
	CASE priority
	    WHEN 'HIGH' THEN 8
	    WHEN 'MED' THEN 24
	    WHEN 'LOW' THEN 48
	END;

-- V_1
SELECT t.ticketnum, prodcode, commenttext
FROM Ticket t
JOIN TicketRep tr
	ON t.ticketnum = tr.ticketnum
JOIN TicketRepComment trc
	ON tr.ticketrepnum = trc.ticketrepnum
JOIN TicketProduct tp
	ON t.ticketnum = tp.ticketnum
WHERE prodcode IN ('WA','UAT','EC')
  AND commenttext LIKE
      CASE prodcode
          WHEN 'WA' THEN  '%ping%'
          WHEN 'UAT' THEN '%screen shar%'
          ELSE '%'
      END;
-- V_2
SELECT ticketnum, prodcode, commenttext
FROM Ticket
JOIN TicketRep USING (ticketnum)
JOIN TicketRepComment USING (ticketrepnum)
JOIN TicketProduct USING (ticketnum)
WHERE prodcode IN ('WA','UAT','EC')
  AND commenttext LIKE
      CASE prodcode
          WHEN 'WA' THEN  '%ping%'
          WHEN 'UAT' THEN '%screen shar%'
          ELSE '%'
      END;

SELECT *
FROM Customer
WHERE IFNULL(companycontact,custname) LIKE 'A%';

-- [ REGULAR EXPRESSION LIKE ]
SELECT ticketnum, description
FROM Ticket
WHERE description RLIKE 'password|account';

SELECT ticketnum, description
FROM Ticket
WHERE description RLIKE 'password\.$|account\.$';

SELECT repfname, replname
FROM SupportRep
WHERE repfname RLIKE 'To[bn]y';

SELECT repfname, replname
FROM SupportRep
WHERE repfname RLIKE 'To(b|n)y';

SELECT ticketnum, description
FROM Ticket
WHERE description RLIKE '^Us.*the[ri][er]';

-- [ MODULO DIVISION ]
SELECT *
FROM Customer
WHERE mod(custnum,2) = 0;

SELECT *
FROM Customer
WHERE custnum%2 = 0;

SELECT *
FROM Customer
WHERE mod(custnum,5) = 0;

SELECT *
FROM Customer
WHERE custnum%5 = 0;

SELECT *
FROM Customer
WHERE mod(custnum,5) = 1;

SELECT *
FROM Customer
WHERE mod((custnum-1),5) = 0;

SELECT *
FROM Customer
WHERE custnum%5 = 1;

SELECT *
FROM Customer
WHERE (custnum-1)%5 = 0;

SELECT *
FROM
	(SELECT
		rank() OVER (ORDER BY prodcode) ranking,
		p.*
	FROM Product p) t1
WHERE mod(ranking,2) = 0;

SELECT *
FROM
	(SELECT
		find_in_set(prodcode,
			(SELECT group_concat(prodcode)
			FROM Product)
		) ranking,
		p.*
	FROM Product p) t1
WHERE mod(ranking,2) = 0;

-- [ COLUMN ADDITION ]
SELECT a.ticketnum, a.custnum, b.ticketnum, b.custnum
FROM Ticket a
JOIN Ticket b
	ON a.ticketnum+1 = b.ticketnum
WHERE a.custnum = b.custnum
ORDER BY a.ticketnum;

SELECT a.ticketnum, a.custnum, b.ticketnum, b.custnum
FROM
	(SELECT ticketnum, custnum,
		rank() OVER (ORDER BY opendatetime) ranking
	FROM Ticket) a
JOIN
	(SELECT ticketnum, custnum,
		rank() OVER (ORDER BY opendatetime) ranking
	FROM Ticket) b
ON a.ranking+1 = b.ranking
WHERE a.custnum = b.custnum
ORDER BY a.ticketnum;

SET SESSION group_concat_max_len = 2048;
SELECT a.ticketnum, a.custnum, b.ticketnum, b.custnum
FROM
	(SELECT ticketnum, custnum,
		find_in_set(opendatetime,
			(SELECT group_concat(DISTINCT opendatetime ORDER BY opendatetime)
			FROM Ticket)
		) ranking
	FROM Ticket) a
JOIN
	(SELECT ticketnum, custnum,
		find_in_set(opendatetime,
			(SELECT group_concat(DISTINCT opendatetime ORDER BY opendatetime)
			FROM Ticket)
		) ranking
	FROM Ticket) b
ON a.ranking+1 = b.ranking
WHERE a.custnum = b.custnum
ORDER BY a.ticketnum;

--
-- **************************************************************************************************************
--

--
-- assignment04 ::
--

-- /Users/jason-adm/Documents/OneDrive/Documents/AIMS/2021.SPRING/sql/assignments/assignment_practice_04/localdata/
-- repcred.csv
-- proddata.csv

SELECT * FROM SSIExtra.RepCredential;
SELECT * FROM SSIExtra.ProdImport;

-- #5-7 -> SupportServices
USE SupportServices;

-- #5 [ - ]
# UPDATE SSIExtra.RepCredential AS 'rc'
# SET repid = (SELECT rep);


SELECT * FROM SSIExtra.RepCredential;


-- #6.a [ - ]
USE SupportServices;
INSERT INTO SSIExtra.ProdPatch
SELECT prodcode, pi.patchnum, pi.patchfile
FROM Product p
INNER JOIN SSIExtra.ProdImport `pi` USING (prodname)
WHERE p.prodname = pi.prodname
  AND pi.patchnum <> '';
-- #6.b [ - ]
INSERT INTO SSIExtra.ProdData
SELECT DISTINCT prodcode, pi.sourcefile
FROM Product p
INNER JOIN SSIExtra.ProdImport `pi` USING (prodname);
ALTER TABLE SSIExtra.ProdData ADD PRIMARY KEY (prodcode);

SELECT * FROM SSIExtra.ProdPatch;
SELECT * FROM SSIExtra.ProdData;

-- #7 [ - ]
SELECT DISTINCT
    substring(sourcefile, 1,
        LENGTH(sourcefile) - INSTR(REVERSE(sourcefile), '/')
    ) AS SourcePath
FROM SSIExtra.ProdData;

-- *********************************
# DESCRIBE SSIExtra.RepCredential;
# DESCRIBE SSIExtra.ProdImport;
# DESCRIBE SSIExtra.ProdData;
# DESCRIBE SSIExtra.ProdPatch;
-- *********************************


SELECT * FROM SSIExtra.ProdImport;