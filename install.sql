-- ================================================
--   Advanced Job System — Database Install
-- ================================================

CREATE TABLE IF NOT EXISTS `advanced_job_duty` (
    `identifier` VARCHAR(60)  NOT NULL,
    `onduty`     TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
