CREATE TABLE IF NOT EXISTS `gang_turfs` (
	`ID` INT NOT NULL AUTO_INCREMENT,
	`scriptID` VARCHAR(50) NOT NULL DEFAULT "",
	`controlledBy` VARCHAR(50) NOT NULL DEFAULT "",
    `lockedAtTime` INT NOT NULL DEFAULT 0,
    `lockExpirationTime` INT NOT NULL DEFAULT 0,
    `warStage` VARCHAR(50) NOT NULL DEFAULT "idle",
	PRIMARY KEY (`id`),
	UNIQUE KEY `scriptID`(`scriptID`),
    KEY `controlledBy`(`controlledBy`)
);

INSERT INTO `gang_turfs` (`scriptID`, `controlledBy`) VALUES
	('turf1', 'ballas'),
	('turf2', 'vagos'),
	('turf3', 'vagos')
	