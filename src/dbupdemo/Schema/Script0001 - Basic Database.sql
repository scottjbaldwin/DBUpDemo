USE `dbupdemo`

CREATE TABLE IF NOT EXISTS `Contacts` (
    `ContactId` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `GivenName` VARCHAR(100),
    `Surname` VARCHAR(100),
    `ContactType` varchar(20),
    `CreatedDate` DATETIME NOT NULL,
    `LastModifiedDate` DATETIME NOT NULL,
    `Notes` VARCHAR(500),
  PRIMARY KEY (`ContactId`)
)
ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `Address` (
	`AddressId` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`Street` nvarchar(100),
	`City` nvarchar(50),
	`State` nvarchar(50),
	`Country` nvarchar(50),
	`Postcode` nvarchar(5),
	PRIMARY KEY (`AddressId`)
)
ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `ContactAddress` (
	`ContactAddressId` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`ContactId` uniqueidentifier,
	`AddressId` uniqueidentifier,
	`AddressType` int, -- 1 = postal, 2 = billing
  PRIMARY KEY (`ContactAddressId`)
)
ENGINE = InnoDB;