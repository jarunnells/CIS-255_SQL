--
-- Using % && CASE Statements in place of MOD() && IF logic
-- ... likely most compatible across DBMS ??
--
DROP PROCEDURE IF EXISTS SupportServices.ticket_activity_case_v2;
DELIMITER $$
CREATE PROCEDURE SupportServices.ticket_activity_case_v2(IN tix_num INT)
BEGIN
    WITH ticket_activity_view_init AS (
        SELECT ticketnum
             , statuscode
             , statusdesc
             , description
             , resolution
             , commenttext
             , opendatetime
             , assigntime
             , commentdatetime
             , closedatetime
        FROM SupportServices.TicketStatus
            JOIN SupportServices.Ticket USING (statuscode)
            JOIN SupportServices.TicketRep USING (ticketnum)
            JOIN SupportServices.TicketRepComment USING (ticketrepnum)
    ), ticket_activity_view_compiled AS (
        SELECT CONCAT('Ticket[', tix_num, ']', ' Opened By: ', '<rep>') commenttext
             , opendatetime timestamp
             , NULL elapsed_total
        FROM ticket_activity_view_init
        WHERE ticketnum = tix_num
        UNION
        SELECT CONCAT('Ticket[', tix_num, ']', ' Assigned To: ', '<rep>') commenttext
             , assigntime timestamp
             , CASE
                 WHEN EXTRACT(HOUR_MINUTE FROM TIMEDIFF(assigntime, opendatetime)) > '2359'
                     THEN CONCAT(
                         @days := FLOOR(HOUR(TIMEDIFF(assigntime, opendatetime)) / 24)
                         , IF(@days > 1, ' days, ', ' day, ')
                         , LPAD(HOUR(TIMEDIFF(assigntime, opendatetime)) % 24,2,'0')
                         , ':'
                         , LPAD(MINUTE(TIMEDIFF(assigntime, opendatetime)),2,'0')
                         , ':'
                         , LPAD(SECOND(TIMEDIFF(assigntime, opendatetime)),2,'0'))
                 ELSE DATE_FORMAT(TIMEDIFF(assigntime, opendatetime),'%H:%i:%s')
             END -- elapsed_total
        FROM ticket_activity_view_init
        WHERE ticketnum = tix_num
        UNION
        SELECT CONCAT('<rep>', ': ', commenttext) commenttext
             , commentdatetime timestamp
             , CASE
                 WHEN EXTRACT(HOUR_MINUTE FROM TIMEDIFF(commentdatetime, opendatetime)) > '2359'
                     THEN CONCAT(
                         @days := FLOOR(HOUR(TIMEDIFF(commentdatetime, opendatetime)) / 24)
                         , IF(@days > 1, ' days, ', ' day, ')
                         , LPAD(HOUR(TIMEDIFF(commentdatetime, opendatetime)) % 24,2,'0')
                         , ':'
                         , LPAD(MINUTE(TIMEDIFF(commentdatetime, opendatetime)),2,0)
                         , ':'
                         , LPAD(SECOND(TIMEDIFF(commentdatetime, opendatetime)),2,'0'))
                 ELSE DATE_FORMAT(TIMEDIFF(commentdatetime, opendatetime),'%H:%i:%s')
             END -- elapsed_total
        FROM ticket_activity_view_init
        WHERE ticketnum = tix_num
        UNION
        SELECT CONCAT('Ticket[', tix_num, ']', ' Closed By: ', '<rep>') commenttext
             , closedatetime timestamp
             , CASE
                 WHEN EXTRACT(HOUR_MINUTE FROM TIMEDIFF(closedatetime, opendatetime)) > '2359'
                     THEN CONCAT(
                         @days := FLOOR(HOUR(TIMEDIFF(closedatetime, opendatetime)) / 24)
                         , IF(@days > 1, ' days, ', ' day, ')
                         , LPAD(HOUR(TIMEDIFF(closedatetime, opendatetime)) % 24,2,'0')
                         , ':'
                         , LPAD(MINUTE(TIMEDIFF(closedatetime, opendatetime)),2,0)
                         , ':'
                         , LPAD(SECOND(TIMEDIFF(closedatetime, opendatetime)),2,'0'))
                 ELSE DATE_FORMAT(TIMEDIFF(closedatetime, opendatetime),'%H:%i:%s')
             END -- elapsed_total
        FROM ticket_activity_view_init
        WHERE ticketnum = tix_num
    ), ticket_activity_view_ranked AS (
        SELECT DENSE_RANK() OVER (PARTITION BY tix_num ORDER BY timestamp) rnk
             , commenttext
             , timestamp
             , elapsed_total
        FROM ticket_activity_view_compiled
    )
    SELECT t1.rnk
         , t1.commenttext
         , t1.timestamp
         , FormatTime(TIMEDIFF(timestamp, (SELECT timestamp FROM ticket_activity_view_ranked t2 WHERE t2.rnk = t1.rnk-1 LIMIT 1))) elapsed
#          , CASE
#                  WHEN EXTRACT(HOUR_MINUTE FROM TIMEDIFF(timestamp, (SELECT timestamp FROM ticket_activity_view_ranked t2 WHERE t2.rnk = t1.rnk-1 LIMIT 1))) > '2359'
#                      THEN CONCAT(
#                          @days := FLOOR(HOUR(TIMEDIFF(timestamp, (SELECT timestamp FROM ticket_activity_view_ranked t2 WHERE t2.rnk = t1.rnk-1 LIMIT 1))) / 24)
#                          , IF(@days > 1, ' days, ', ' day, ')
#                          , LPAD(HOUR(TIMEDIFF(timestamp, (SELECT timestamp FROM ticket_activity_view_ranked t2 WHERE t2.rnk = t1.rnk-1 LIMIT 1))) % 24,2,'0')
#                          , ':'
#                          , LPAD(MINUTE(TIMEDIFF(timestamp, (SELECT timestamp FROM ticket_activity_view_ranked t2 WHERE t2.rnk = t1.rnk-1 LIMIT 1))),2,0)
#                          , ':'
#                          , LPAD(SECOND(TIMEDIFF(timestamp, (SELECT timestamp FROM ticket_activity_view_ranked t2 WHERE t2.rnk = t1.rnk-1 LIMIT 1))),2,'0'))
#                  ELSE DATE_FORMAT(TIMEDIFF(timestamp, (SELECT timestamp FROM ticket_activity_view_ranked t2 WHERE t2.rnk = t1.rnk-1 LIMIT 1)),'%H:%i:%s')
#              END elapsed
         , t1.elapsed_total
    FROM ticket_activity_view_ranked t1
    ORDER BY timestamp;
END $$
DELIMITER ;

--
-- Using MOD() && IF Statements in place of % && case logic
-- ... Compatibility: MySQL, ... ?? TBD
--
DROP PROCEDURE IF EXISTS SupportServices.ticket_activity_if;
DELIMITER $$
CREATE PROCEDURE SupportServices.ticket_activity_if(IN tix_num INT)
BEGIN
    WITH ticket_activity_view_init AS (
        SELECT ticketnum
             , statuscode
             , statusdesc
             , description
             , resolution
             , commenttext
             , opendatetime
             , assigntime
             , commentdatetime
             , closedatetime
        FROM SupportServices.TicketStatus
            JOIN SupportServices.Ticket USING (statuscode)
            JOIN SupportServices.TicketRep USING (ticketnum)
            JOIN SupportServices.TicketRepComment USING (ticketrepnum)
    ), ticket_activity_view_compiled AS (
        SELECT CONCAT('Ticket[', tix_num, ']', ' Opened By: ', '<rep>') commenttext
             , opendatetime timestamp
             , NULL elapsed_total
        FROM ticket_activity_view_init
        WHERE ticketnum = tix_num
        UNION
        SELECT CONCAT('Ticket[', tix_num, ']', ' Assigned To: ', '<rep>') commenttext
             , assigntime timestamp
             , IF(EXTRACT(HOUR_MINUTE FROM TIMEDIFF(assigntime, opendatetime)) > '2359',
                 CONCAT(@days := FLOOR(HOUR(TIMEDIFF(assigntime, opendatetime)) / 24)
             , IF(@days > 1, ' days, ', ' day, ')
             , LPAD(MOD(HOUR(TIMEDIFF(assigntime, opendatetime)), 24), 2, '0')
             , ':'
             , LPAD(MINUTE(TIMEDIFF(assigntime, opendatetime)), 2, '0')
             , ':'
             , LPAD(SECOND(TIMEDIFF(assigntime, opendatetime)), 2, '0')),
                 DATE_FORMAT(TIMEDIFF(assigntime, opendatetime), '%H:%i:%s')) elapsed_total
        FROM ticket_activity_view_init
        WHERE ticketnum = tix_num
        UNION
        SELECT CONCAT('<rep>', ': ', commenttext) commenttext
             , commentdatetime timestamp
             , IF(EXTRACT(HOUR_MINUTE FROM TIMEDIFF(commentdatetime, opendatetime)) > '2359',
                 CONCAT(@days := FLOOR(HOUR(TIMEDIFF(commentdatetime, opendatetime)) / 24)
             , IF(@days > 1, ' days, ', ' day, ')
             , LPAD(MOD(HOUR(TIMEDIFF(commentdatetime, opendatetime)), 24), 2, '0')
             , ':'
             , LPAD(MINUTE(TIMEDIFF(commentdatetime, opendatetime)), 2, 0)
             , ':'
             , LPAD(SECOND(TIMEDIFF(commentdatetime, opendatetime)), 2, '0')),
                 DATE_FORMAT(TIMEDIFF(commentdatetime, opendatetime), '%H:%i:%s')) elapsed_total
        FROM ticket_activity_view_init
        WHERE ticketnum = tix_num
        UNION
        SELECT CONCAT('Ticket[', tix_num, ']', ' Closed By: ', '<rep>') commenttext
             , closedatetime timestamp
             , IF(EXTRACT(HOUR_MINUTE FROM TIMEDIFF(closedatetime, opendatetime)) > '2359',
                 CONCAT(@days := FLOOR(HOUR(TIMEDIFF(closedatetime, opendatetime)) / 24)
             , IF(@days > 1, ' days, ', ' day, ')
             , LPAD(MOD(HOUR(TIMEDIFF(closedatetime, opendatetime)), 24), 2, '0')
             , ':'
             , LPAD(MINUTE(TIMEDIFF(closedatetime, opendatetime)), 2, 0)
             , ':'
             , LPAD(SECOND(TIMEDIFF(closedatetime, opendatetime)), 2, '0')),
                 DATE_FORMAT(TIMEDIFF(closedatetime, opendatetime), '%H:%i:%s')) elapsed_total
        FROM ticket_activity_view_init
        WHERE ticketnum = tix_num
    ), ticket_activity_view_ranked AS (
        SELECT DENSE_RANK() OVER (PARTITION BY tix_num ORDER BY timestamp) rnk
             , commenttext
             , timestamp
             , elapsed_total
        FROM ticket_activity_view_compiled
    )
    SELECT t1.rnk
         , t1.commenttext
         , t1.timestamp
         , TIMEDIFF(timestamp, (SELECT timestamp FROM ticket_activity_view_ranked t2 WHERE t2.rnk = t1.rnk-1 LIMIT 1)) elapsed
         , t1.elapsed_total
    FROM ticket_activity_view_ranked t1
    ORDER BY timestamp;
END $$
DELIMITER ;


SET @tix_num = 2;
CALL SupportServices.ticket_activity_case(@tix_num);
SET @tix_num = 31;
CALL SupportServices.ticket_activity_if(@tix_num);
SET @tix_num = 2;
CALL SupportServices.ticket_activity_case_v2(@tix_num);

-- 
-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
-- 
-- SELECT IF(EXTRACT(HOUR_MINUTE FROM
--                   TIMEDIFF(@closedatetime := '2015-05-12 11:49:22', @opendatetime := '2015-04-16 16:16:59')) > '2359',
--           CONCAT(
--                   @days := FLOOR(HOUR(TIMEDIFF(@closedatetime, @opendatetime)) / 24)
--               , IF(@days > 1, ' days, ', ' day, ')
--               , LPAD(MOD(HOUR(TIMEDIFF(@closedatetime, @opendatetime)), 24), 2, '0')
--               , ':'
--               , LPAD(MINUTE(TIMEDIFF(@closedatetime, @opendatetime)), 2, 0)
--               , ':'
--               , LPAD(SECOND(TIMEDIFF(@closedatetime, @opendatetime)), 2, '0')),
--           DATE_FORMAT(TIMEDIFF(@closedatetime, @opendatetime), '%H:%i:%s')) elapsed
-- ;

DELIMITER $$

CREATE
    DEFINER=`student`@`localhost`
    FUNCTION SupportServices.FormatTime(time_in DATETIME)
    RETURNS varchar(25) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
    DECLARE elapsed_total VARCHAR(25);
    DECLARE days INT;
    SET days = FLOOR(HOUR(time_in) / 24);

    IF EXTRACT(HOUR_MINUTE FROM time_in) > '2359'
        THEN SET elapsed_total =
        CONCAT(
          days
          ,IF(days > 1, ' days, ', ' day, ')
          ,LPAD(HOUR(time_in) % 24,2,'0')
          ,':'
          ,LPAD(MINUTE(time_in),2,'0')
          ,':'
          ,LPAD(SECOND(time_in),2,'0'));
    ELSE SET elapsed_total = DATE_FORMAT(time_in,'%H:%i:%s');
    END IF;
    RETURN (elapsed_total);
END $$

DELIMITER ;