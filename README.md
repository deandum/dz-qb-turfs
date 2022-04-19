# dz-qb-turfs - V1.0.0

Gang turf war script. Each whitelisted gang in `config.lua` will be given HQ zones and as many different turfs as you want. Gang wars can't be started on any HQ zones.<br>
After a war, the turf will be locked down for a specific amount of time that can be changed in `config.lua`. During this time, another war can't be started on the same turf. The lockdown is automatically released when a gang member attempts to start a new war if it is expired.<br>
This resource is governed by the server and the client code is used just for display purposes. It currenlty runs at 0.02ms for players that are members of a whitelisted gang and 0.00ms for everyone else.

## Dependencies
Check each resource listed below for any other dependencies they might have to run. This resource assumes that you have all of these installed and working correctly using the latest versions.
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [qb-management](https://github.com/qbcore-framework/qb-management)
- [qb-inventory](https://github.com/qbcore-framework/qb-inventory)
- [oxmysql](https://github.com/overextended/oxmysql)
- [PolyZone](https://github.com/mkafrin/PolyZone)

## Installation
- Download the script and put it in the `[qb]` directory.
- Set your DB by importing `init.sql`.
- Edit config.lua with coords or other custom fields.
- Restart Script / Server.

## ATTENTION
Do not modify the `WarStages` in `config.lua` unless you changed both the client and server script to match. This table controls the process of a turf war.<br>
Do not set `Debug` to `true` in `config.lua` if this resource is running on a live server. This field will make the cirle zones arround each turf visible. It should only be used for development.<br>
The `scriptID` in the DB has to match the equivalent element it the `Turfs` table in `config.lua`. Whenever a new turf is created, an equivalent record has to be manually inserted in the DB.

## User Commands
- `/challengeTurf` - used to trigger a war on a turf. The player that uses it must be inside the trageted turf and must have a certain rank that can be set in `config.lua`. The war will not start if the gang is not whitelisted, if there are not enough other gang members online, or if the turf is locked.

## Admin Commands
- `/reloadTurfs` - used to trigger a reload of the available turfs for all the clients.
- `/lockTurf` - used to lock down a turf. You must provide a turf ID. To lock down a turf forever, set the `lockExpirationTime` to `-1` in the DB.
- `/unlockTurf` - used to unlock a turf. You must provide a turf ID.
- `/updateTurfControlledBy` - used to update which gang controls a turf. You must provide a turf ID and a whitelisted gang name.