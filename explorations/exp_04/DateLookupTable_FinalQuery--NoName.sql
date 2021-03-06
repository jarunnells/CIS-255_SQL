--
-- BEGIN DEPENDENCIES
-- *************************************************************
-- For easy removal...
DROP DATABASE IF EXISTS Exploration_Scenario_04;
CREATE DATABASE IF NOT EXISTS Exploration_Scenario_04;
--
-- Easter Sunday (and dependent holidays) calculation
DROP FUNCTION IF EXISTS Exploration_Scenario_04.EasterSunday;
DELIMITER $$
CREATE FUNCTION Exploration_Scenario_04.EasterSunday(yr YEAR)
RETURNS DATE DETERMINISTIC
BEGIN
    -- temp vars -> calculations
    DECLARE a,b,c,d,e,f,g,h,i,k,l,m INT;
    DECLARE EasterDay DATE;
    -- calc DATE -> Easter Sunday
    SET a = yr % 19,
        b = FLOOR(yr / 100),
        c = yr % 100,
        d = FLOOR(b / 4),
        e = b % 4,
        f = FLOOR((b + 8) / 25),
        g = FLOOR((b - f + 1) / 3),
        h = ((19 * a + b - d - g + 15) % 30),
        i = FLOOR(c / 4),
        k = c % 4,
        l = (32 + 2 * e + 2 * i - h - k) % 7,
        m = FLOOR((a + 11 * h + 22 * l) / 451),
        EasterDay =
            CONCAT_WS(
                '-', yr,
                FLOOR((h + l - 7 * m + 114) / 31),
                ((h + l - 7 * m + 114) % 31) + 1);
    RETURN (EasterDay);
END $$
DELIMITER ;
--
-- EasterSunday() -> dev test
SELECT Exploration_Scenario_04.EasterSunday('2022');
--
-- BEGIN SETUP INIT
-- *************************************************************
-- Easier Dev Testing...DATE RANGE LOOKUP TBL
DROP TABLE IF EXISTS Exploration_Scenario_04.DateRange;
CREATE TABLE IF NOT EXISTS Exploration_Scenario_04.DateRange(
    `dateMIN` DATE NOT NULL,
    `dateMAX` DATE NOT NULL
) ENGINE=INNODB;
--
-- DATE RANGE -> DIMENSION DEPTH
INSERT INTO Exploration_Scenario_04.DateRange SELECT '2021-01-01', '2022-12-31';
-- INSERT INTO Exploration_Scenario_04.DateRange SELECT '1970-01-01', '2038-01-19';  -- !Y2K38! => 1901-12-13 20:45:52 UTC
--
-- DATE DIM -> INIT
DROP TABLE IF EXISTS Exploration_Scenario_04.DateLookupTable;
CREATE TABLE IF NOT EXISTS Exploration_Scenario_04.DateLookupTable (
    `dateID` BIGINT AUTO_INCREMENT,        -- [01]
    `date` DATE NOT NULL,                  -- [02]
    `month_weekday_int` TINYINT NOT NULL,  -- [03]
    `day_str` VARCHAR(9) NOT NULL,         -- [04]
    `week_weekday_int` TINYINT NOT NULL,   -- [05]
    `week` TINYINT NOT NULL,               -- [06]
    `month_int` TINYINT NOT NULL,          -- [07]
    `month_str` VARCHAR(9) NOT NULL,       -- [08]
    `month_firstOf` DATE NOT NULL,         -- [09]
    `quarter` TINYINT NOT NULL,            -- [10]
    `year` SMALLINT NOT NULL,              -- [11]
    `year_day_int` SMALLINT NOT NULL,      -- [12]
    `is_leap_year` TINYINT(1) NOT NULL,    -- [13]
    `date_str_abr` VARCHAR(18) NOT NULL,   -- [14]  -- WED 31ST SEPT 2021 '%a %D %b %Y'
    `date_str_full` VARCHAR(29) NOT NULL,  -- [15]  -- WEDNESDAY 31ST SEPTEMBER 2021 '%W %D %M %Y'
    `unix_ts` BIGINT NOT NULL,             -- [16]
    PRIMARY KEY (`dateID`),
    INDEX (`date`)
) ENGINE=INNODB;
--
-- HOLIDAY DIM -> INIT
DROP TABLE IF EXISTS Exploration_Scenario_04.HolidayLookupTable;
CREATE TABLE IF NOT EXISTS Exploration_Scenario_04.HolidayLookupTable (
    `holidayID` BIGINT AUTO_INCREMENT,  -- [01]
    `date` DATE NOT NULL,               -- [02]
    `holiday` VARCHAR(50) NOT NULL,     -- [03]
    CONSTRAINT fk_date
        FOREIGN KEY (`date`)
        REFERENCES Exploration_Scenario_04.DateLookupTable(`date`),
    PRIMARY KEY (`holidayID`),
    INDEX (`date`)
) ENGINE=INNODB;
--
-- BEGIN DIMENSION BUILD
-- *************************************************************
-- CALCULATE && SET -> CTE MAX RECURSION DEPTH [SESSION]
SET @startDate = (SELECT `dateMIN` FROM Exploration_Scenario_04.DateRange);
SET @endDate = (SELECT `dateMAX` FROM Exploration_Scenario_04.DateRange);
-- SET @endDate = DATE_ADD(DATE_ADD(@startDate, INTERVAL 100 YEAR), INTERVAL -1 DAY);
-- SELECT DATEDIFF('2038-01-19','1970-01-01') diff;  -- !Y2K38! => 25000
--
-- SET recursion depth for large dims (or !Y2K38! demo), ELSE use 1000 for smaller demo dim
SET @@cte_max_recursion_depth = IF(DATEDIFF(@endDate,@startDate)>1000, 25000, 1000);
--
-- COMPILE DATE DIMENSION
INSERT INTO Exploration_Scenario_04.DateLookupTable (
    `dateID`,             -- [01::dateID->BIGINT]
    `date`,               -- [02::date->DATE]
    `month_weekday_int`,  -- [03::month_weekday_int->TINYINT (day of week month (1-28[-31])]
    `day_str`,            -- [04::day_str->VARCHAR(9)]
    `week_weekday_int`,   -- [05::week_weekday_int->TINYINT]
    `week`,               -- [06::week->TINYINT]
    `month_int`,          -- [07::month_int->TINYINT]
    `month_str`,          -- [08::month_str->VARCHAR(9)]
    `month_firstOf`,      -- [09::month_firstOf->DATE]
    `quarter`,            -- [10::quarter->TINYINT]
    `year`,               -- [11::year->SMALLINT]
    `year_day_int`,       -- [12::year_day_int->SMALLINT]
    `is_leap_year`,       -- [13::is_leap_year->TINYINT(1)]
    `date_str_abr`,       -- [14::date_str_abr->VARCHAR(18)]
    `date_str_full`,      -- [15::date_str_full->VARCHAR(29)]
    `unix_ts`             -- [16::unix_ts->BIGINT]
)
WITH RECURSIVE day_counter(num) AS (
    SELECT 0
    UNION ALL
    SELECT num+1
    FROM day_counter
    WHERE num < DATEDIFF(
        (SELECT `dateMAX` FROM Exploration_Scenario_04.DateRange),
        (SELECT `dateMIN` FROM Exploration_Scenario_04.DateRange))
),
date_seq(`date`) AS (
    SELECT DATE_ADD(
        (SELECT `dateMIN`FROM Exploration_Scenario_04.DateRange),
        INTERVAL num DAY)
    FROM day_counter
),
date_dim AS (
    SELECT
        NULL,                                              -- [01::dateID->BIGINT]
        `date`,                                            -- [02::date->DATE]
        DAYOFMONTH(`date`),                                -- [03::month_weekday_int->TINYINT (day of week month (1-28[-31])]
        DAYNAME(`date`),                                   -- [04::day_str->VARCHAR(9)]
        DAYOFWEEK(`date`),                                 -- [05::week_weekday_int->TINYINT]
        WEEK(`date`),                                      -- [06::week->TINYINT]
        MONTH(`date`),                                     -- [07::month_int->TINYINT]
        MONTHNAME(`date`),                                 -- [08::month_str->VARCHAR(9)]
        DATE_FORMAT(
            CONCAT_WS('-',YEAR(`date`),MONTH(`date`),'01'),
            '%Y-%m-%d'),                                   -- [09::month_firstOf->DATE]
        QUARTER(`date`),                                   -- [10::quarter->TINYINT]
        YEAR(`date`),                                      -- [11::year->SMALLINT]
        DAYOFYEAR(`date`),                                 -- [12::year_day_int->SMALLINT]
        IF(YEAR(`date`) % 400 = 0
               OR YEAR(`date`) % 4 = 0
               AND YEAR(`date`) % 100 != 0, TRUE, FALSE),  -- [13::is_leap_year->TINYINT(1)]
        DATE_FORMAT(`date`, '%a %D %b %Y'),                -- [14::date_str_abr->VARCHAR(18)]
        DATE_FORMAT(`date`, '%W %D %M %Y'),                -- [15::date_str_full->VARCHAR(29)]
        CAST(UNIX_TIMESTAMP(`date`) AS UNSIGNED)           -- [16::unix_ts->BIGINT]
    FROM date_seq
) SELECT * FROM date_dim;
--
-- COMPILE HOLIDAY DIMENSION
INSERT INTO Exploration_Scenario_04.HolidayLookupTable(
    `holidayID`,  -- [01::dateID->BIGINT]
    `date`,       -- [02::date->DATE]
    `holiday`     -- [03::holiday->VARCHAR(50)]
)
WITH holiday_init AS (
    SELECT
           `date`,
           `month_firstOf`,
           DATE_FORMAT(
               CONCAT_WS('-',YEAR(`date`),'01','01'),
               '%Y-%m-%d') AS `year_firstOf`,
           `year`,
           `week_weekday_int`,
           `month_weekday_int`,
           `month_int`,
           `day_str`,
           ROW_NUMBER() OVER (
               PARTITION BY `month_firstOf`, `week_weekday_int`
               ORDER BY `date` DESC
           ) AS `month_weekday_last`
    FROM Exploration_Scenario_04.DateLookupTable
),
holidays_compiled AS (
    SELECT NULL,
           `date`,
           CASE
               WHEN (`date` = `year_firstOf`)
                   THEN 'New Year''s Day'
               WHEN (`month_int` = 1 AND `month_weekday_int` = 3 AND `week_weekday_int` = 2)
                   THEN 'Martin Luther King, Jr. Day'
               WHEN (`month_int` = 2 AND `month_weekday_int` = 3 AND `week_weekday_int` = 2)
                   THEN 'President''s Day'
               WHEN (`month_int` = 5 AND `month_weekday_last` = 1 AND `week_weekday_int` = 2)
                   THEN 'Memorial Day'
               WHEN (`month_int` = 5 AND (WEEK(`date`) - WEEK(`month_firstOf`)) = 2 AND `week_weekday_int` = 1)
                   THEN 'Mother''s Day'  -- 2022 bug ... ?!?!? -> switch to PARTITION BY 'sunday'
               WHEN (`month_int` = 6 AND (WEEK(`date`) - WEEK(`month_firstOf`)) = 3 AND `week_weekday_int` = 1)
                   THEN 'Father''s Day'
               WHEN (`month_int` = 7 AND `month_weekday_int` = 4)
                   THEN 'Independence Day'
               WHEN (`month_int` = 9 AND `month_weekday_int` = 1 AND `week_weekday_int` = 2)
                   THEN 'Labor Day'
               WHEN (`month_int` = 10 AND `month_weekday_int` = 2 AND `week_weekday_int` = 2)
                   THEN 'Columbus Day'
               WHEN (`month_int` = 11 AND `month_weekday_int` = 11)
                   THEN 'Veteran''s Day'
               WHEN (`month_int` = 11 AND `month_weekday_int` = 24 AND `week_weekday_int` = 4)
                   THEN 'Thanksgiving Day'
               WHEN (`month_int` = 12 AND `month_weekday_int` = 24)
                   THEN 'Christmas Eve Day'
               WHEN (`month_int` = 12 AND `month_weekday_int` = 25)
                   THEN 'Christmas Day'
               WHEN (`month_int` = 12 AND `month_weekday_int` = 31)
                   THEN 'New Year''s Eve Day'
               WHEN (`date` = Exploration_Scenario_04.EasterSunday(YEAR(`date`)))
                   THEN 'Easter Sunday'
               WHEN (`date` = DATE_ADD(Exploration_Scenario_04.EasterSunday(YEAR(`date`)), INTERVAL -2 DAY))
                   THEN 'Good Friday'
               WHEN (`date` = DATE_ADD(Exploration_Scenario_04.EasterSunday(YEAR(`date`)), INTERVAL -47 DAY))
                   THEN 'Mardi Gras'
           END AS `holiday`
    FROM holiday_init
    WHERE (`date` = `year_firstOf`)
       OR (`month_int` = 1 AND `month_weekday_int` = 3 AND `week_weekday_int` = 2)
       OR (`month_int` = 2 AND `month_weekday_int` = 3 AND `week_weekday_int` = 2)
       OR (`month_int` = 5 AND `month_weekday_last` = 1 AND `week_weekday_int` = 2)
       OR (`month_int` = 5 AND (WEEK(`date`)-WEEK(`month_firstOf`)) = 2 AND `week_weekday_int` = 1)
       OR (`month_int` = 6 AND (WEEK(`date`)-WEEK(`month_firstOf`)) = 3 AND `week_weekday_int` = 1)
       OR (`month_int` = 7 AND `month_weekday_int` = 4)
       OR (`month_int` = 9 AND `month_weekday_int` = 1 AND `week_weekday_int` = 2)
       OR (`month_int` = 10 AND `month_weekday_int` = 2 AND `week_weekday_int` = 2)
       OR (`month_int` = 11 AND `month_weekday_int` = 11)
       OR (`month_int` = 11 AND `month_weekday_int` = 24 AND `week_weekday_int` = 4)
       OR (`month_int` = 12 AND `month_weekday_int` = 24)
       OR (`month_int` = 12 AND `month_weekday_int` = 25)
       OR (`month_int` = 12 AND `month_weekday_int` = 31)
       OR (`date` = Exploration_Scenario_04.EasterSunday(YEAR(`date`)))
       OR (`date` = DATE_ADD(Exploration_Scenario_04.EasterSunday(YEAR(`date`)), INTERVAL -2 DAY))
       OR (`date` = DATE_ADD(Exploration_Scenario_04.EasterSunday(YEAR(`date`)), INTERVAL -47 DAY))
)
SELECT * FROM holidays_compiled
UNION ALL
SELECT NULL,
       DATE_ADD(`date`, INTERVAL 1 DAY),
       'Black Friday'  -- DEPENDENCY :: Thanksgiving Day -> week 4|5
FROM holidays_compiled
WHERE `holiday` = 'Thanksgiving Day'
ORDER BY `date`;
--
-- VERIFY DATE && HOLIDAY DIMENSIONS
-- SELECT * FROM Exploration_Scenario_04.DateLookupTable ORDER BY `date`;
-- SELECT * FROM Exploration_Scenario_04.HolidayLookupTable ORDER BY `date`;
--
-- VIEW :: DATE DIMENSION => WITH HOLIDAYS
CREATE OR REPLACE VIEW Exploration_Scenario_04.DateDimHolidays AS
    SELECT dlt.*,
           IF(hlt.`date` IS NOT NULL, 1, 0) AS `isHoliday`,
           hlt.`holiday`
    FROM Exploration_Scenario_04.DateLookupTable AS dlt
    LEFT OUTER JOIN Exploration_Scenario_04.HolidayLookupTable AS hlt USING (`date`);
SELECT * FROM Exploration_Scenario_04.DateDimHolidays ORDER BY `date`;
