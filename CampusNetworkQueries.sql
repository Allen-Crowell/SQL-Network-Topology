/**
Created by Douglas Allen Crowell
This file conttains various stored procedures, views, triggers, and test cases.
Reference to CampusNetwork.sql
**/

use CampusNetwork
go

--This view will show all employees Names, Usernames, and Passwords

CREATE VIEW EmployeePasswords														--Creating a view with this name
AS
SELECT employees.Username, Firstname as 'First Name', Lastname as 'Last Name', SSHPassword		--The criteria for this view - it will show each employee's username, full name, and password
FROM employees JOIN LoginCredentials ON Employees.Username = LoginCredentials.Username;


--updateable view to show router configs and allow updates to the router hostname
create view RouterHostnames
as
select *
from NetworkRouterConfigs;

--test for updateable view
update RouterHostnames --this will search by FQDN PK and update the hostname accordingly
set Hostname = 'Router100'
where FQDN = 'Router1.CCNA.com';

-- stored procedure to calculate the remaining usable hosts on a given network. User will input the network default gateway in order to select devices only on that network.
CREATE PROCEDURE RemainingUsableHosts (
		@Network as Char(15), --this is promted to the user, enter the default gateway of the network you are querying
		@RemainingHosts	tinyint output,
		@TotalHosts		TINYINT = NULL,
		@UsedHosts		Tinyint = null		
) AS
BEGIN --begin to allow multiple select statements to be run as a batch.
	SELECT @TotalHosts = UsableHosts FROM Networks WHERE DefaultGateway = @Network; --pull the usable hosts from the networks table as assign to a variable. the 2^n-2 subnetting concept is already calculated in the table
	SELECT @UsedHosts = COUNT(IPv4) FROM EndDevices WHERE DefaultGateway = @Network; --count the number of devices by IP address since each end device will have a unique IP. Filter by the default gateway provided by the variable passed into the procedure
	SELECT @RemainingHosts = @TotalHosts - @UsedHosts --subtract the used hosts from the previous statement from the total hosts from the first statement and store into the variable that will provide output.
end --end the batch statement


--test case for SP passing through the first network and returning the remaining usable hosts, which should be 254 originally, minus 2 for the 2 end devices on that network.
declare @Hosts int;
exec RemainingUsableHosts '192.168.0.1', @RemainingHosts = @Hosts output;
print @hosts;


-- SP to count all routers, switches, and end devices on the entire network across all subnets.
create procedure CountAllNetworkDevices
		@TotalDevices tinyint output,
		@NumberofRouters tinyint = null,
		@numberofswtiches	tinyint = null,
		@numberofenddevices tinyint = null
as
begin
select @NumberofRouters = count(FQDN) from NetworkRouterConfigs; --count all routers
select @numberofswtiches = count(FQDN) from NetworkSwitchConfigs; --count all switches
select @numberofenddevices = count(NIC_MAC) from EndDevices; --count all end devices
select @NumberofRouters as 'TotalRouters', @numberofswtiches as 'TotalSwitches', @numberofenddevices as 'TotalEndDevices'; --dislay these numbers in separate columns
select @TotalDevices = @NumberofRouters + @numberofswtiches + @numberofenddevices;
end

-- test exec of the SP, this will show total devices of each type in separate columns
declare @TotalNetworkDevices int;
exec CountAllNetworkDevices @TotalDevices = @TotalNetworkDevices output;
print @TotalNetworkDevices;

--These will delete this trigger and its assets so we can quickly create them again
IF OBJECT_ID('UpdateChangelog') IS NOT NULL
	DROP Trigger UpdateChangelog
IF OBJECT_ID('EndDevicesChangelog') IS NOT NULL
	DROP TABLE EndDevicesChangelog

--Trigger that puts everything that gets updated or deleted into a table - basically an archive
GO
CREATE TRIGGER UpdateChangelog
ON EndDevices
AFTER UPDATE, DELETE			--This trigger is going to do something after deletion occurs
AS
	IF OBJECT_ID('EndDevicesChangelog') IS NULL		--This will prevent SQL from trying to create this table every single time an item is updated from EndDevices. It is saying 'if this table already exists, do not try to create it again'
		CREATE TABLE EndDevicesChangelog (			--This will create the EndDevicesChangelog table which is where any old rows from EndDevices will be transported to after they are updated. This table will only be created once an item from EndDevices is updated, and only if EndDevicesChangelog does not already exist
		NIC_MAC				CHAR(12) PRIMARY KEY NOT NULL,
		DefaultGateway		CHAR(15) NOT NULL,
		IPv4				CHAR(15) NOT NULL,
		OS					CHAR(75) NOT NULL,
		Manufacturer		CHAR(30) NOT NULL,
		)
	INSERT INTO EndDevicesChangelog (								--Insert all old items that have since been updated into the newly created EndDevicesChangelog table. Insert them into the changelog table in the order of these columns
		NIC_MAC, DefaultGateway, IPv4, OS, Manufacturer)
		SELECT NIC_MAC, DefaultGateway, IPv4, OS, Manufacturer
		FROM deleted				

--Commands to test the trigger
	UPDATE EndDevices											--Editing an entry in EndDevices. This will set off the trigger
	SET OS = 'Windows 7' WHERE defaultgateway = '192.168.5.1' 

	DELETE FROM EndDevices WHERE NIC_MAC = 'ccccdddd0001'		


--This trigger will tell you how many networks there are in the CampusNetwork DB after you modify the Networks table in any way
GO
CREATE TRIGGER ShowNetworkCount
ON Networks
AFTER UPDATE, INSERT, DELETE			--This trigger is going to do something after an update, insertion, or deletion occurs
AS
	SELECT COUNT(*) 
	AS 'Number of Networks' 
	FROM Networks


--Commands to test the trigger--
	UPDATE Networks											--Editing an entry in Networks. This will set off the trigger
	SET NetworkAddress = '192.168.0.99' WHERE NetworkAddress = '192.168.0.0'

	INSERT INTO Networks (
		DefaultGateway			
		,NetworkAddress			
		,SubnetMask				
		,Broadcast				
		,UsableHosts				
		) VALUES ('192.168.10.1', '192.168.10.0', '255.255.255.0', '192.168.10.254', '254')

	DELETE FROM Networks WHERE NetworkAddress = '192.168.10.0'	

	--drop trigger ShowNetworkCount