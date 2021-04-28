--
-- DB :: Exploration -> 04
--
CREATE DATABASE IF NOT EXISTS Exploration_Scenario_04;
--
-- TABLE :: Dimension -> init
--
DROP TABLE IF EXISTS Exploration_Scenario_04.DateLookupTable_loop;
CREATE TABLE IF NOT EXISTS Exploration_Scenario_04.DateLookupTable_loop (
    `dateID` BIGINT AUTO_INCREMENT,
    `date` DATE NOT NULL,
    `month_day_int` TINYINT NOT NULL,
    `month_day_str` VARCHAR(9) NOT NULL,
    `week` TINYINT NOT NULL,
    `month_int` TINYINT NOT NULL,
    `month_str` VARCHAR(9) NOT NULL,
    `quarter` TINYINT NOT NULL,
    `year` SMALLINT NOT NULL,
    `year_day_int` SMALLINT NOT NULL,
    `date_str_abr` VARCHAR(18) NOT NULL,  -- WED 31ST SEPT 2021 '%a %D %b %Y'
    `date_str_full` VARCHAR(29) NOT NULL,  -- WEDNESDAY 31ST SEPTEMBER 2021 '%W %D %M %Y'
    `unix_ts` BIGINT NOT NULL,
    PRIMARY KEY (`dateID`)
    -- PRIMARY KEY (`date`)
) ENGINE=INNODB;
--
-- PROCEDURE :: Loop -> while
--
DROP PROCEDURE IF EXISTS Exploration_Scenario_04.BuildDateLookup;
DELIMITER $$
CREATE PROCEDURE Exploration_Scenario_04.BuildDateLookup(
    IN startDate DATE,
    IN endDate DATE
)
BEGIN
    DECLARE loopDate DATE;
    SET loopDate = startDate;
    WHILE loopDate <= endDate DO
        INSERT INTO Exploration_Scenario_04.DateLookupTable_loop
        VALUES (
                NULL,
                loopDate,
                DAY(loopDate),
                DAYNAME(loopDate),
                WEEK(loopDate),
                MONTH(loopDate),
                MONTHNAME(loopDate),
                QUARTER(loopDate),
                YEAR(loopDate),
                DAYOFYEAR(loopDate),
                DATE_FORMAT(loopDate, '%a %D %b %Y'),
                DATE_FORMAT(loopDate, '%W %D %M %Y'),
                UNIX_TIMESTAMP(loopDate)
        );
        SET loopDate = DATE_ADD(loopDate, INTERVAL 1 DAY);
    END WHILE;
END $$
DELIMITER ;
CALL Exploration_Scenario_04.BuildDateLookup('2021-01-01','2021-12-31');
SELECT * FROM Exploration_Scenario_04.DateLookupTable_loop;
--
-- *********************************************************
--
--
-- CTE :: NO Loop -> recursion used
--
DROP TABLE IF EXISTS Exploration_Scenario_04.DateLookupTable_CTE;
CREATE TABLE IF NOT EXISTS Exploration_Scenario_04.DateLookupTable_CTE (
    `dateID` BIGINT AUTO_INCREMENT,
    `date` DATE NOT NULL,
    `month_day_int` TINYINT NOT NULL,
    `month_day_str` VARCHAR(9) NOT NULL,
    `week` TINYINT NOT NULL,
    `month_int` TINYINT NOT NULL,
    `month_str` VARCHAR(9) NOT NULL,
    `quarter` TINYINT NOT NULL,
    `year` SMALLINT NOT NULL,
    `year_day_int` SMALLINT NOT NULL,
    `is_leap_year` TINYINT(1) NOT NULL,
    `date_str_abr` VARCHAR(18) NOT NULL,  -- WED 31ST SEPT 2021 '%a %D %b %Y'
    `date_str_full` VARCHAR(29) NOT NULL,  -- WEDNESDAY 31ST SEPTEMBER 2021 '%W %D %M %Y'
    `unix_ts` BIGINT NOT NULL,
    PRIMARY KEY (`dateID`)
    -- PRIMARY KEY (`date`)
) ENGINE=INNODB;

SET @startDate = '2020-01-01';
SET @endDate = '2020-12-31';
-- SET @endDateYears = DATE_ADD(DATE_ADD(@startDate, INTERVAL 100 YEAR), INTERVAL -1 DAY);

-- SELECT DATEDIFF('2020-12-31','2000-01-01') diff;
-- SET @@cte_max_recursion_depth = 10000;
WITH RECURSIVE day_seq(num) AS (
    SELECT 0
    UNION ALL
    SELECT num+1
    FROM day_seq
    WHERE num < DATEDIFF('2021-12-31','2021-01-01')
),
-- SELECT num FROM day_seq ORDER BY num;
date_seq(`date`) AS (
    SELECT DATE_ADD('2021-01-01', INTERVAL num DAY) FROM day_seq
),
-- SELECT `date` FROM date_seq ORDER BY `date`;
date_dim AS (
    SELECT
        NULL,
        `date`,
        DAY(`date`),
        DAYNAME(`date`),
        WEEK(`date`),
        MONTH(`date`),
        MONTHNAME(`date`),
        QUARTER(`date`),
        YEAR(`date`),
        DAYOFYEAR(`date`),
        IF(YEAR(`date`) % 400 = 0
               OR YEAR(`date`) % 4 = 0
               AND YEAR(`date`) % 100 != 0, TRUE, FALSE),
        DATE_FORMAT(`date`, '%a %D %b %Y'),
        DATE_FORMAT(`date`, '%W %D %M %Y'),
        UNIX_TIMESTAMP(`date`)
    FROM date_seq
)
SELECT * FROM date_dim ORDER BY `date`;
