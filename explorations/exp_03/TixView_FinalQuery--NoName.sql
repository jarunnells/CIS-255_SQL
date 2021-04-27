DROP PROCEDURE IF EXISTS SupportServices.ticket_activity;
DELIMITER $$
CREATE PROCEDURE SupportServices.ticket_activity(IN tix_num INT)
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
         , TIMEDIFF(timestamp, (SELECT timestamp FROM ticket_activity_view_ranked t2 WHERE t2.rnk = t1.rnk-1 LIMIT 1)) elapsed
         , t1.elapsed_total
    FROM ticket_activity_view_ranked t1
    ORDER BY timestamp;
END $$
DELIMITER ;

SET @tix_num = 2;
CALL SupportServices.ticket_activity(@tix_num);