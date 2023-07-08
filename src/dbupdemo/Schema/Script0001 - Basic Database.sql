USE `dbupdemo`

CREATE TABLE IF NOT EXISTS `dbupdemo`.`Contacts` (
    Id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    GivenName VARCHAR(100),
    Surname VARCHAR(100),
    ContactType INT,
    CreatedDate DATETIME NOT NULL,
    LastModifiedDate DATETIME NOT NULL,
    Notes VARCHAR(500),
  PRIMARY KEY (Id)
)
ENGINE = InnoDB;