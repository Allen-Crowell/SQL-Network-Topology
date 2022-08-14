/**
Created by: Douglas Allen Crowell
Custom Database: This database is designed using fundamental network topology and addressing concepts.
Domain names, IPv4 addresses, and MAC address already serve as unique identifiers on a network and therefore served as excellent primary and foreign keys.
Network devices also operate at different layers with a natural cascade into finer details, this synergises well with the core concepts of a relational database, getting further into detail with each layer.
The insert statements themselves are not intended to represent a full network topology, it is an extreme barebones example strictly created to provide a proof of concept.
**/

IF DB_ID('CampusNetwork') IS NOT NULL
	DROP DATABASE CampusNetwork
GO

CREATE DATABASE CampusNetwork
GO 

USE [CampusNetwork]
GO

-- The Networks table is intended to hold all information about each individual subnet on the overall network.
-- Using the default gateway as the PK will connect it to each router port since the IP address assigned to a router port is the default gateway for that subnet.
CREATE TABLE Networks (
		DefaultGateway			CHAR(15) PRIMARY KEY NOT NULL,-- Default Gateway PK - FK from RouterPorts ip address of port (use first usable host)
		NetworkAddress			CHAR(15) NOT NULL, -- network address unique
		SubnetMask				CHAR(15) NOT NULL,-- subnet mask
		Broadcast				CHAR(15) NOT NULL,-- broadcast address
		UsableHosts				TINYINT NULL,-- # of usable hosts
)

INSERT INTO Networks VALUES
		('192.168.0.1','192.168.0.0','255.255.255.0','192.168.0.254','254'),
		('192.168.1.1','192.168.1.0','255.255.255.0','192.168.1.254','254'),
		('192.168.2.1','192.168.2.0','255.255.255.0','192.168.2.254','254'),
		('192.168.3.1','192.168.3.0','255.255.255.0','192.168.3.254','254'),
		('192.168.4.1','192.168.4.0','255.255.255.0','192.168.4.254','254'),
		('192.168.5.1','192.168.5.0','255.255.255.0','192.168.5.254','254'),
		('192.168.6.1','192.168.6.0','255.255.255.0','192.168.6.254','254'),
		('192.168.7.1','192.168.7.0','255.255.255.0','192.168.7.254','254'),
		('192.168.8.1','192.168.8.0','255.255.255.0','192.168.8.254','254'),
		('192.168.9.1','192.168.9.0','255.255.255.0','192.168.9.254','254');

-- The RouterPorts table will contain all information about each individual router port on the network.
-- Identified by the MAC address as PK, it will connect to the FK MAC address of each port attached to a given router in NetworkRouterConfigs
CREATE TABLE RouterPorts (
		PortMAC			CHAR(12) PRIMARY KEY NOT NULL,-- mac address for each port PK
		IPv4			CHAR(15) NOT NULL, -- ip address of port is FK to Networks/default gateway
		Interface		CHAR(6) NOT NULL,  -- interface identifier (example: G0/0/0)
		IntStatus		BIT NOT NULL,  -- 1 for up, 0 for down
		CONSTRAINT FK_RouterPorts_IPv4 FOREIGN KEY (IPv4) REFERENCES Networks(DefaultGateway)
)

INSERT INTO RouterPorts VALUES
		('abcd12340001', '192.168.0.1', '01', 1),
		('abcd12340002', '192.168.1.1', '02', 1),
		('abcd12340003', '192.168.2.1', '03', 1),
		('abcd12340004', '192.168.3.1', '04', 1),
		('abcd12340005', '192.168.4.1', '05', 1),
		('abcd12340006', '192.168.5.1', '06', 1),
		('abcd12340007', '192.168.6.1', '07', 1),
		('abcd12340008', '192.168.7.1', '08', 1),
		('abcd12340009', '192.168.8.1', '09', 1),
		('abcd1234000a', '192.168.9.1', '10', 1);

-- The LoginCredentials table will contain the username and password information to SSH into various devices.
-- This is the only table that will contain user specific passwords
-- Username as the PK since each employee would have a unique username used to access all devices.
CREATE TABLE LoginCredentials (
		Username		CHAR(30) PRIMARY KEY NOT NULL,-- username PK - FK from usernames in router and switch config tables
		--EmployeeID - This attribute is a FK and will be included upon the addition of the Employees table
		SSHPassword		CHAR(30) NOT NULL,-- password
		PriviledgeLevel	CHAR(2) NULL,-- privilede level determines what this user can access or change
)

INSERT INTO LoginCredentials VALUES
		('User01', 'Password1', '15'),
		('User02', 'Password2', '15'),
		('User03', 'Password3', '15'),
		('User04', 'Password4', '15'),
		('User05', 'Password5', '15'),
		('User06', 'Password6', '15'),
		('User07', 'Password7', '15'),
		('User08', 'Password8', '15'),
		('User09', 'Password9', '15'),
		('User10', 'Password10', '15');

-- Since routers provide the backbone of internetwork connectivity, it is natural for this table to provide the top layer for this database.
-- From the G0/0 G0/1 G1/0 G1/1 port MAC Addresses as FKs, each will link to the PortMAC PK of the RouterPorts table and split off into each network.
-- Once each network splits off in RouterPorts, it follows the natural flow of network traffic as it uses the Layer 3 IP address and Layer 2 MAC address to move from Router>RouterPort>Switch>SwitchPort>End Device
-- Just like L3/L2 routing/switching, this theme of traffic flow is shaped in the same way a relational database uses primary and foreign keys to connect tables
-- Device specific domain names, host names, line passwords, and priviledged exec access level passwords are contained with the intention to be accessed by a python script as database objects and automatically pushed to various devices for streamlined setup and configuration.
CREATE TABLE NetworkRouterConfigs (
	FQDN			CHAR(60) PRIMARY KEY NOT NULL, -- fully qualified domain name as PK
	Hostname		CHAR(20) NOT NULL,
	/**
	within the router configs, we have various Gigabit0/0/0 and other interfaces. each of these attributes will reference the MAC address attribute PK in the RouterPorts table
	add constraint at bottom to make these FK reference the RouterPorts table PK
	**/
	G00					CHAR(12) NOT NULL, -- G0/0 FK -first value is not null
	G01					CHAR(12) NULL,     -- G0/1 FK - the remaining values can be null as not all routers will have the same amount of interfaces
	G10					CHAR(12) NULL,     -- G1/0 FK
	G11					CHAR(12) NULL,     -- G1/1 FK
	AdminUser01			CHAR(30) NOT NULL, -- ssh username FK (this is where admin profiles from loginCredentials would come into play for remote access) may be multiple usernames
	AdminUser02			CHAR(30) NOT NULL, -- listing 10 usernames so we can have room for 10 entries in the credentials table
	AdminUser03			CHAR(30) NOT NULL,
	AdminUser04			CHAR(30) NOT NULL,
	AdminUser05			CHAR(30) NOT NULL,
	AdminUser06			CHAR(30) NOT NULL,
	AdminUser07			CHAR(30) NOT NULL,
	AdminUser08			CHAR(30) NOT NULL,
	AdminUser09			CHAR(30) NOT NULL,
	AdminUser10			CHAR(30) NOT NULL,
	ConsolePass			CHAR(30) NULL,		-- console login password
	PrivExecPass		CHAR(30) NULL,		-- enable/priv exec password

	CONSTRAINT FK_G00_MAC FOREIGN KEY (G00) REFERENCES RouterPorts(PortMAC), --FK constraints to router ports 
	CONSTRAINT FK_G01_MAC FOREIGN KEY (G01) REFERENCES RouterPorts(PortMAC),
	CONSTRAINT FK_G10_MAC FOREIGN KEY (G10) REFERENCES RouterPorts(PortMAC),
	CONSTRAINT FK_G11_MAC FOREIGN KEY (G11) REFERENCES RouterPorts(PortMAC),
	CONSTRAINT FK_NetworkRouterConfigs_AdminUser01 FOREIGN KEY (AdminUser01) REFERENCES LoginCredentials (Username), -- constraints for admin usernames as FK to login credentials
	CONSTRAINT FK_NetworkRouterConfigs_AdminUser02 FOREIGN KEY (AdminUser02) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkRouterConfigs_AdminUser03 FOREIGN KEY (AdminUser03) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkRouterConfigs_AdminUser04 FOREIGN KEY (AdminUser04) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkRouterConfigs_AdminUser05 FOREIGN KEY (AdminUser05) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkRouterConfigs_AdminUser06 FOREIGN KEY (AdminUser06) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkRouterConfigs_AdminUser07 FOREIGN KEY (AdminUser07) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkRouterConfigs_AdminUser08 FOREIGN KEY (AdminUser08) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkRouterConfigs_AdminUser09 FOREIGN KEY (AdminUser09) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkRouterConfigs_AdminUser10 FOREIGN KEY (AdminUser10) REFERENCES LoginCredentials (Username)
)

INSERT INTO NetworkRouterConfigs (FQDN, Hostname, G00, AdminUser01, AdminUser02, AdminUser03, AdminUser04, AdminUser05,
									AdminUser06, AdminUser07, AdminUser08, AdminUser09, AdminUser10, ConsolePass, PrivExecPass)
VALUES
		('Router1.CCNA.com', 'Router1', 'abcd12340001', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Router2.CCNA.com', 'Router2', 'abcd12340002', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Router3.CCNA.com', 'Router3', 'abcd12340003', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Router4.CCNA.com', 'Router4', 'abcd12340004', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Router5.CCNA.com', 'Router5', 'abcd12340005', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Router6.CCNA.com', 'Router6', 'abcd12340006', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Router7.CCNA.com', 'Router7', 'abcd12340007', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Router8.CCNA.com', 'Router8', 'abcd12340008', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Router9.CCNA.com', 'Router9', 'abcd12340009', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Router10.CCNA.com', 'Router10', 'abcd1234000a', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass');

-- Switchports table with PortMAC as PK, from the Switchconfig table port mac addresses FKs
CREATE TABLE SwitchPorts (
		PortMAC			CHAR(12) PRIMARY KEY NOT NULL,-- mac address for each port PK - FK from NetworkSwitcheConfigs
		--ConnectedMAC	CHAR(12) NULL,- Placeholder for connected device mac address FK - the table this would reference is not included in this build (EndDevices)
		PortNumber		TINYINT NOT NULL,-- port numbers
		IntStatus		BIT NOT NULL,  -- 1 for up, 0 for down
		SwitchportMode	CHAR(30) NOT NULL,-- switchport mode, access port or trunk port
		PortType		CHAR(30) NOT NULL,-- type of port (ethernet/fiber)
		--CONSTRAINT FK_ConnectedMAC FOREIGN KEY (ConnectedMAC) REFERENCES enddevices(MACAddress)
)

INSERT INTO SwitchPorts VALUES
		('aaaabbbb0001', 1, 1, 'ExtraSwitchy', '01'),
		('aaaabbbb0002', 2, 1, 'ExtraSwitchy', '01'),
		('aaaabbbb0003', 3, 1, 'ExtraSwitchy', '01'),
		('aaaabbbb0004', 4, 1, 'ExtraSwitchy', '01'),
		('aaaabbbb0005', 5, 1, 'ExtraSwitchy', '01'),
		('aaaabbbb0006', 6, 1, 'ExtraSwitchy', '01'),
		('aaaabbbb0007', 7, 1, 'ExtraSwitchy', '01'),
		('aaaabbbb0008', 8, 1, 'ExtraSwitchy', '01'),
		('aaaabbbb0009', 9, 1, 'ExtraSwitchy', '01'),
		('aaaabbbb000a', 10, 1, 'ExtraSwitchy', '01');

--The NetworkSwitchConfigs table uses the fully qualified domain name as the PK, all ports in the switch are listed to be referenced by the switchports table.
CREATE TABLE NetworkSwitchConfigs (
	FQDN				CHAR(60) PRIMARY KEY NOT NULL,					-- domain name as PK, use char for now, might need to use nvarchar instead
	Hostname			CHAR(60) NOT NULL,
	Port01				CHAR(12) NOT NULL,								-- Port MAC Addresses as FK
	Port02				CHAR(12) NULL,									-- MAC addresses of each port on the switch FK (for simplicity, limit to 10)
	Port03				CHAR(12) NULL,									-- MAC address line will be repeated for each port on the switch
	Port04				CHAR(12) NULL,									-- constraint at the bottom to reference each line to SwitchPorts
	Port05				CHAR(12) NULL,									-- leaving all ports after 01 as null for simplicity
	Port06				CHAR(12) NULL,
	Port07				CHAR(12) NULL,
	Port08				CHAR(12) NULL,
	Port09				CHAR(12) NULL,
	Port10				CHAR(12) NULL,
	DefaultGateway		CHAR(15) NOT NULL,	-- default gateway/IP address FK - PK to Networks
	AdminUser01			CHAR(30) NOT NULL,	-- ssh username FK (this is where admin profiles from loginCredentials would come into play for remote access) may be multiple usernames
	AdminUser02			CHAR(30) NOT NULL,	-- listing 10 usernames so we can have room for 10 entries in the credentials table
	AdminUser03			CHAR(30) NOT NULL,
	AdminUser04			CHAR(30) NOT NULL,
	AdminUser05			CHAR(30) NOT NULL,
	AdminUser06			CHAR(30) NOT NULL,
	AdminUser07			CHAR(30) NOT NULL,
	AdminUser08			CHAR(30) NOT NULL,
	AdminUser09			CHAR(30) NOT NULL,
	AdminUser10			CHAR(30) NOT NULL,
	ConsolePass			CHAR(30) NULL,	-- console login password
	PrivExecPass		CHAR(30) NULL,	-- enable/priv exec password

	CONSTRAINT FK_Port01_MAC FOREIGN KEY (Port01) REFERENCES SwitchPorts(PortMAC),
	CONSTRAINT FK_Port02_MAC FOREIGN KEY (Port02) REFERENCES SwitchPorts(PortMAC),
	CONSTRAINT FK_Port03_MAC FOREIGN KEY (Port03) REFERENCES SwitchPorts(PortMAC),
	CONSTRAINT FK_Port04_MAC FOREIGN KEY (Port04) REFERENCES SwitchPorts(PortMAC),
	CONSTRAINT FK_Port05_MAC FOREIGN KEY (Port05) REFERENCES SwitchPorts(PortMAC),
	CONSTRAINT FK_Port06_MAC FOREIGN KEY (Port06) REFERENCES SwitchPorts(PortMAC),
	CONSTRAINT FK_Port07_MAC FOREIGN KEY (Port07) REFERENCES SwitchPorts(PortMAC),
	CONSTRAINT FK_Port08_MAC FOREIGN KEY (Port08) REFERENCES SwitchPorts(PortMAC),
	CONSTRAINT FK_Port09_MAC FOREIGN KEY (Port09) REFERENCES SwitchPorts(PortMAC),
	CONSTRAINT FK_Port10_MAC FOREIGN KEY (Port10) REFERENCES SwitchPorts(PortMAC),
	CONSTRAINT FK_NetworkSwitcheConfigs_AdminUser01 FOREIGN KEY (AdminUser01) REFERENCES LoginCredentials (Username), -- constraints for admin usernames as FK to login credentials
	CONSTRAINT FK_NetworkSwitcheConfigs_AdminUser02 FOREIGN KEY (AdminUser02) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkSwitcheConfigs_AdminUser03 FOREIGN KEY (AdminUser03) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkSwitcheConfigs_AdminUser04 FOREIGN KEY (AdminUser04) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkSwitcheConfigs_AdminUser05 FOREIGN KEY (AdminUser05) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkSwitcheConfigs_AdminUser06 FOREIGN KEY (AdminUser06) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkSwitcheConfigs_AdminUser07 FOREIGN KEY (AdminUser07) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkSwitcheConfigs_AdminUser08 FOREIGN KEY (AdminUser08) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkSwitcheConfigs_AdminUser09 FOREIGN KEY (AdminUser09) REFERENCES LoginCredentials (Username),
	CONSTRAINT FK_NetworkSwitcheConfigs_AdminUser10 FOREIGN KEY (AdminUser10) REFERENCES LoginCredentials (Username)
)

INSERT INTO NetworkSwitchConfigs (FQDN, Hostname, Port01, DefaultGateway, AdminUser01, AdminUser02, AdminUser03, AdminUser04, AdminUser05,
									AdminUser06, AdminUser07, AdminUser08, AdminUser09, AdminUser10, ConsolePass, PrivExecPass)
VALUES
		('Switch1.CCNA.com', 'Switch1', 'aaaabbbb0001', '192.168.0.1', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Switch2.CCNA.com', 'Switch2', 'aaaabbbb0002', '192.168.1.1', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Switch3.CCNA.com', 'Switch3', 'aaaabbbb0003', '192.168.2.1', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Switch4.CCNA.com', 'Switch4', 'aaaabbbb0004', '192.168.3.1', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Switch5.CCNA.com', 'Switch5', 'aaaabbbb0005', '192.168.4.1', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Switch6.CCNA.com', 'Switch6', 'aaaabbbb0006', '192.168.5.1', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Switch7.CCNA.com', 'Switch7', 'aaaabbbb0007', '192.168.6.1', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Switch8.CCNA.com', 'Switch8', 'aaaabbbb0008', '192.168.7.1', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Switch9.CCNA.com', 'Switch9', 'aaaabbbb0009', '192.168.8.1', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass'),
		('Switch10.CCNA.com', 'Switch10', 'aaaabbbb000a', '192.168.9.1', 'User01', 'User02', 'User03', 'User04', 'User05', 'User06', 'User07', 'User08', 'User09', 'User10', 'ConPass', 'EnablePass');