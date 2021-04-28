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
CALL Exploration_Scenario_04.BuildDateLookup('2020-01-01','2020-12-31');
SELECT * FROM Exploration_Scenario_04.DateLookupTable_loop;
--
-- *********************************************************
--
