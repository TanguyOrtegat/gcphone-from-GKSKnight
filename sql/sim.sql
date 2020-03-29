
CREATE TABLE IF NOT EXISTS `sim` (
  `identifier` varchar(50) NOT NULL,
  `phone_number` varchar(10) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


INSERT INTO `items` (`name`, `label`, `limit`, `rare`, `can_remove`) VALUES
	('sim', 'Sim', -1, 0, 1)
;


INSERT INTO `shops` (`store`, `item`, `price`) VALUES
	('TwentyFourSeven', 'sim', 50),
	('RobsLiquor', 'sim', 50),
	('LTDgasoline', 'sim', 50)
;
