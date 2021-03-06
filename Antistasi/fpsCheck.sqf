#include "macros.hpp"
AS_SERVER_ONLY("fpsCheck.sqf");

private ["_cuentaFail","_texto"];

fpsTotal = 0;
fpsCuenta = 0;
_cuentaFail = 0;


while {true} do
	{
	sleep 5;
	if (fpsCuenta > 12) then
		{
		fpsTotal = diag_fps;
		fpsCuenta = 1;
		}
	else
		{
		fpsTotal = fpsTotal + diag_fps;
		fpsCuenta = fpsCuenta + 1;
		};

	if (diag_fps < AS_P("minimumFPS")) then
		{
		{if ((alive _x) and (side _x == civilian) and (diag_fps < AS_P("minimumFPS")) and (typeOf _x in arrayCivs) && !(typeOf _x in CIV_specialUnits)) then {deleteVehicle _x; sleep 1}} forEach allUnits;
		_cuentaFail = _cuentaFail + 1;
		if (_cuentaFail > 11) then
			{
			if (AS_P("spawnDistance") > 1000) then
				{
				AS_Pset("spawnDistance", AS_P("spawnDistance") - 100);
				};
            _civPerc = AS_P("civPerc");
			if (_civPerc > 0.05) then
				{
                AS_Pset("civPerc",_civPerc - 0.01);
				};
            if (AS_P("minimumFPS") > 25) then {
                AS_Pset("minimumFPS",25);
                };
			_cuentaFail = 0;
			{if (!alive _x) then {deleteVehicle _x}} forEach vehicles;
			{deleteVehicle _x} forEach allDead;
			_texto = format ["Server has a low FPS average:\n%1\n\nGame settings changed to:\nSpawn Distance: %2 mts\nCiv. Percentage: %3 percent\nFPS Limit established at %4\n\nAll wrecked vehicles and corpses have been deleted",round (fpsTotal/fpsCuenta), AS_P("spawnDistance"),AS_P("civPerc") * 100, AS_P("minimumFPS")];
			[[petros,"hint",_texto],"commsMP"] call BIS_fnc_MP;
			allowPlayerRecruit = false; publicVariable "allowPlayerRecruit";
			};
		}
	else
		{
		_cuentaFail = 0;
		if (!allowPlayerRecruit) then {allowPlayerRecruit = true; publicVariable "allowPlayerRecruit"};
		};
	};
