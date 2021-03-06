private _isJip = false;
if isNull player then {
    _isJip = true;
};

if _isJip then {
    diag_log "[AS] client: JIP: waiting for player";
    waitUntil {!isNull player and {player == player}};
};
diag_log "[AS] client: starting";

call compile preprocessFileLineNumbers "briefing.sqf";

if not isServer then {
    call compile preprocessFileLineNumbers "debug\init.sqf";
    call compile preprocessFileLineNumbers "initFuncs.sqf";
    call compile preprocessFileLineNumbers "initVar.sqf";
} else {
    waitUntil {(!isNil "serverInitVarsDone")};
};

private _introShot = 0 spawn {};
private _titulo = 0 spawn {};

// the fancy starting script, called outside debug mode
if not AS_DEBUG_flag then {
    private _colorWest = west call BIS_fnc_sideColor;
    private _colorEast = east call BIS_fnc_sideColor;
    {
    _x set [3, 0.33]
    } forEach [_colorWest, _colorEast];

    _introShot =
    	[
        getMarkerPos "FIA_HQ", // Target position
        worldName + " Island", // SITREP text
        50, //  altitude
        50, //  radius
        90, //  degrees viewing angle
        0, // clockwise movement
        [
        	["\a3\ui_f\data\map\markers\nato\o_inf.paa", _colorWest, markerPos "insertMrk", 1, 1, 0, "Insertion Point", 0],
            ["\a3\ui_f\data\map\markers\nato\o_inf.paa", _colorEast, markerPos "towerBaseMrk", 1, 1, 0, "Radio Towers", 0]
        ]
        ] spawn BIS_fnc_establishingShot;

    _titulo = ["Antistasi", "by Golias"] spawn BIS_fnc_infoText;
};

waitUntil {scriptdone _introshot and scriptDone _titulo};

if (isNil "serverInitDone") then {
    disableUserInput true;
    cutText ["Waiting for Players and Server Init","BLACK",0];
    diag_log "[AS] client: waiting for serverInitDone";
    waitUntil {(!isNil "serverInitDone")};
    cutText ["Starting Mission","BLACK IN",0];
    disableUserInput false;
};
diag_log "[AS] client: initialized";

musicON = true;
[] execVM "musica.sqf";

[player] call AS_fnc_emptyUnit;
if isMultiplayer then {
	diag_log format ["[AS] client: isJIP: %1", _isJip];
} else {
	AS_commander = player;
	private _group = group player;
	_group setGroupId ["Stavros","GroupColor4"];
	player setIdentity "protagonista";
	player setUnitRank "COLONEL";
	player hcSetGroup [_group];
};

if not hayACE then {
	tags = [] execVM "tags.sqf";
	if ((cadetMode) and (isMultiplayer)) then {
        [] execVM "playerMarkers.sqf"
    };
} else {
	[] execVM "playerMarkers.sqf";
};

autoHeal = true;

MIASquadUnits = creategroup WEST;  // units that are not in the squad because they lost communication with the player (no radio).
player setvariable ["compromised", 0];  // Used by undercover mechanics
player setVariable ["punish",0,true];  // punish time for Team kill
player setVariable ["money",100,true];  // initial money
player setVariable ["BLUFORSpawn",true,true];  // means that the unit triggers spawn of zones.
player setUnitRank (AS_ranks select 0);
player setVariable ["rank", (AS_ranks select 0), true];
private _score = 0;
if (player == AS_commander) then {_score = 25}; // so the commander does not lose the position immediately.
player setVariable ["score", _score, true];

if isMultiplayer then {
    musicON = false;
    player setVariable ["elegible",true,true];
	["InitializePlayer", [player]] call BIS_fnc_dynamicGroups;//Exec on client

    personalGarage = [];
};

call AS_fnc_loadLocalPlayer;
call AS_fnc_initPlayer;

player addEventHandler ["GetInMan", {
	private _unit = _this select 0;
	private _veh = _this select 2;
	private _exit = false;
	if (isMultiplayer) then {
		private _owner = _veh getVariable "duenyo";
		if (!isNil "_owner") then {
			if (_owner isEqualType "") then {
				if ({getPlayerUID _x == _owner} count (units group player) == 0) then {
					hint "You cannot board other player vehicle if you are not in the same group";
					moveOut _unit;
					_exit = true;
				};
			};
		};
	};
	if (!_exit) then {
		if (((typeOf _veh) in arrayCivVeh) or ((typeOf _veh) == civHeli)) then {
			if (!(_veh in reportedVehs)) then {
				[] spawn undercover;
			};
		};
		if (_veh isKindOf "Truck_F") then {
			if ((not (_veh isKindOf "C_Van_01_fuel_F")) and (not (_veh isKindOf "I_Truck_02_fuel_F")) and (not (_veh isKindOf "B_G_Van_01_fuel_F"))) then {
				if (_this select 1 == "driver") then {
					private _EHid = _unit addAction [localize "STR_act_loadAmmobox", "Municion\transfer.sqf",nil,0,false,true];
					_unit setVariable ["transferID", _EHid, true];
				};
			};
		};
	};
}];

player addEventHandler ["GetOutMan", {
	if !((player getVariable ["transferID", -1]) == -1) then {
		player removeaction (player getVariable "transferID");
		player setVariable ["transferID", nil, true];
	};
}];

if (_isJip) then {
	[] execVM "modBlacklist.sqf";

	if (not([player] call isMember)) then {
		if (serverCommandAvailable "#logout") then {
			miembros pushBack (getPlayerUID player);
			publicVariable "miembros";
			hint "You are not in the member's list, but as you are Server Admin, you have been added up. Welcome!"
		}
		else {
			hint "Welcome Guest\n\nYou have joined this server as guest";
			//if ((count playableUnits == maxPlayers) and (({[_x] call isMember} count playableUnits) < count miembros) and (serverName in servidoresOficiales)) then {["serverFull",false,1,false,false] call BIS_fnc_endMission};
		};
	}
	else {
		hint format ["Welcome back %1", name player];

		if (serverName in servidoresOficiales) then {
			if ((count playableUnits == maxPlayers) and (({[_x] call isMember} count playableUnits) < count miembros)) then {
				{
				if (not([_x] call isMember)) exitWith {["serverFull",false,1,false,false] remoteExec ["BIS_fnc_endMission",_x]};
				} forEach playableUnits;
			};
		};
		if ({[_x] call isMember} count playableUnits == 1) then {
			[] remoteExec ["AS_fnc_chooseCommander", 2];
		};
	};

	{
	if (_x isKindOf "FlagCarrier") then {
		private _location = [call AS_fnc_locations, getPos _x] call BIS_fnc_nearestPosition;
		if !((_location call AS_fnc_location_type) in ["hill", "roadblock"]) then {
			if (_location call AS_fnc_location_side == "FIA") then {
				_x addAction [localize "STR_act_recruitUnit", {call AS_fncUI_RecruitUnitMenu;},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"];
				_x addAction [localize "STR_act_buyVehicle", {call AS_fncUI_buyVehicleMenu;},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"];
				_x addAction [localize "STR_act_persGarage", {nul = [true] spawn garage},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"];
			};
		};
	};
	} forEach vehicles - [bandera,fuego,caja,cajaVeh];

	{
	if ([_x] call AS_fnc_getFIAUnitType == "Survivor") then {
		if (!isPlayer (leader group _x)) then {
			_x addAction [localize "STR_act_orderRefugee", "AI\liberaterefugee.sqf",nil,0,false,true];
		};
	};
	} forEach allUnits;

	if ((player == AS_commander) and (isNil "placementDone")) then {
        [] spawn AS_fncUI_LoadSaveMenu;
	};

	// sync the inventory content to the JIP.
	remoteExec ["fnc_MAINT_refillArsenal", 2];
};

private _texto = "";

if (hayTFAR) then {
	_texto = "TFAR Detected\n\nAntistasi detects TFAR in the server config.\nAll players will start with TFAR default radios.\nDefault revive system will shut down radios while players are inconscious.\n\n";
};
if (hayACE) then {
	_texto = _texto + "ACE 3 Detected\n
                       \nACE items added.
                       \nDefault AI control disabled.";
    if (hayACEMedical) then {
        _texto = _texto + "\nACE Medical being used: default revive system disabled.";
    };
    if (hayACEhearing) then {
        _texto = _texto + "\nACE Hearing being used: default earplugs disabled.";
    };
};
if (hayRHS) then {
	_texto = _texto + "\n\nRHS Detected:\n\nAAF -> VDV\nCSAT -> VMF\nNATO -> USMC";
};

if (hayTFAR or hayACE or hayRHS) then {
	hint format ["%1",_texto];
};

removeAllActions caja;
[caja,"arsenal"] call AS_fnc_addAction;
[caja,"emptyCrate"] call AS_fnc_addAction;

removeAllActions mapa;
mapa addAction [localize "str_act_gameOptions", {CreateDialog "game_options_commander";},nil,0,false,true,"","(isPlayer _this) and (_this == AS_commander) and (_this == _this getVariable ['owner',_this])"];
mapa addAction [localize "str_act_gameOptions", {CreateDialog "game_options_player";},nil,0,false,true,"","(isPlayer _this) and !(_this == AS_commander) and (_this == _this getVariable ['owner',_this])"];
mapa addAction [localize "str_act_mapInfo", "actions\fnc_location_mapInfo.sqf",nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',_this])"];
mapa addAction [localize "str_act_tfar", {CreateDialog "tfar_menu";},nil,0,false,true,"","(isClass (configFile >> ""CfgPatches"" >> ""task_force_radio""))", 5];

removeAllActions bandera;
[bandera,"unit"] call AS_fnc_addAction;
[bandera,"vehicle"] call AS_fnc_addAction;
[bandera,"garage"] call AS_fnc_addAction;

bandera addAction [localize "str_act_hqOptions",{call AS_fncUI_openHQmenu;},nil,0,false,true,"","(isPlayer _this) and (player == AS_commander) and (_this == _this getVariable ['owner',_this]) and (petros == leader group petros)"];

removeAllActions cajaVeh;
cajaVeh addAction [localize "str_act_healRepair", "actions\healandrepair.sqf",nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',_this])"];

removeAllActions fuego;
fuego addAction [localize "str_act_rest", "actions\skiptime.sqf",nil,0,false,true,"","(_this == AS_commander)"];

{
    [_x,"moveObject"] call AS_fnc_addAction;
} forEach [caja, mapa, bandera, cajaVeh, fuego];

if (isNil "placementDone") then {
    waitUntil {!isNil "AS_commander"};
    if (player == AS_commander) then {
        HC_comandante synchronizeObjectsAdd [player];
        player synchronizeObjectsAdd [HC_comandante];
        if not AS_DEBUG_flag then {
            [] spawn AS_fncUI_LoadSaveMenu;
        } else {
            [getMarkerPos "FIA_HQ"] remoteExec ["AS_fnc_HQplace", 2];
        };
    };
};

diag_log "[AS] client: ready";
