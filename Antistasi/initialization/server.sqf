#include "..\macros.hpp"
AS_SERVER_ONLY("server.sqf");

call compile preprocessFileLineNumbers "debug\init.sqf";

diag_log "[AS] Server: starting";
call compile preprocessFileLineNumbers "initialization\server_functions.sqf";
call compile preprocessFileLineNumbers "initFuncs.sqf";
diag_log "[AS] Server: initFuncs done";
call compile preprocessFileLineNumbers "initLocations.sqf";
diag_log "[AS] Server: initLocations done";
call compile preprocessFileLineNumbers "initVar.sqf";
diag_log "[AS] Server: initVar done";

["Initialize"] call BIS_fnc_dynamicGroups;

// tell every client that the server is ready to receive players (see initPlayerLocal.sqf)X
serverInitVarsDone = true;
publicVariable "serverInitVarsDone";
diag_log "[AS] Server: serverInitVarsDone";

if isMultiplayer then {
    call compile preProcessFileLineNumbers "initialization\serverMP.sqf";
} else {
    call compile preProcessFileLineNumbers "initialization\serverSP.sqf";
};

serverInitDone = true;
publicVariable "serverInitDone";
diag_log "[AS] Server: serverInitDone";

{if (not isPlayer _x and side _x == side_blue) then {deleteVehicle _x}} forEach allUnits;

miembros = [];
publicVariable "miembros";

waitUntil {!isNil "AS_commander" and {isPlayer AS_commander}};

fpsCheck = [] execVM "fpsCheck.sqf";
waitUntil {!(isNil "placementDone")};
[] spawn AS_fnc_spawnLoop;
resourcecheck = [] execVM "resourcecheck.sqf";
if (serverName in servidoresOficiales) then {
    [] execVM "orgPlayers\mList.sqf";
};
