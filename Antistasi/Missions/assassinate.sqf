params ["_mission"];
private _location = _mission call AS_fnc_mission_location;
private _position = _location call AS_fnc_location_position;

private _missionType = _mission call AS_fnc_mission_type;

private _tiempolim = 120;
private _fechalim = [date select 0, date select 1, date select 2, date select 3, (date select 4) + _tiempolim];
private _fechalimnum = dateToNumber _fechalim;

private _tskTitle = _mission call AS_fnc_mission_title;
private _tskDesc = "";
call {
	if (_missionType == "kill_officer") exitWith {
		_tskDesc = localize "STR_tskDesc_ASOfficer"
	};
	if (_missionType == "kill_specops") exitWith {
		_tskDesc = localize "STR_tskDesc_ASSpecOp";
	};
};
_tskDesc = format [_tskDesc,[_location] call localizar,numberToDate [2035,_fechalimnum] select 3,numberToDate [2035,_fechalimnum] select 4];

private _task = [_mission,[side_blue,civilian],[_tskDesc,_tskTitle,_location],_position,"CREATED",5,true,true,"Kill"] call BIS_fnc_setTask;

private _resources = [[],[],[]];
private _target = objNull; // target: unit or group

call {
	if (_missionType == "kill_officer") exitWith {
		private _group = createGroup side_red;

		_target = ([_position, 0, opI_OFF, _group] call bis_fnc_spawnvehicle) select 0;
        ([_position, 0, opI_PIL, _group] call bis_fnc_spawnvehicle) select 0;

		_group selectLeader _target;
		[leader _group, _location, "SAFE", "SPAWNED", "NOVEH", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";

		{_x call AS_fnc_initUnitCSAT; _x allowFleeing 0} forEach units _group;

		_resources = [[_group]];
	};
	if (_missionType == "kill_specops") exitWith {
		private _mrkfin = createMarkerLocal [_mission,_position];
		_mrkfin setMarkerShapeLocal "RECTANGLE";
		_mrkfin setMarkerSizeLocal [500,500];
		_mrkfin setMarkerTypeLocal "hd_warning";
		_mrkfin setMarkerColorLocal "ColorRed";
		_mrkfin setMarkerBrushLocal "DiagGrid";
		_mrkfin setMarkerAlphaLocal 0;

		private _group = [_position, side_red, [opGroup_SpecOps, "CSAT"] call fnc_pickGroup] call BIS_Fnc_spawnGroup;
		private _uav = createVehicle [opUAVsmall, _position, [], 0, "FLY"];
		createVehicleCrew _uav;
		[leader _group, _mrkfin, "RANDOM", "SPAWNED", "NOVEH2", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";
		{_x call AS_fnc_initUnitCSAT; _x allowFleeing 0} forEach units _group;

		private _groupUAV = group (crew _uav select 1);
		[leader _groupUAV, _mrkfin, "SAFE", "SPAWNED","NOVEH", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";

		_resources = [[_group, _groupUAV], [_uav], [_mrkfin]];
        _target = _group;
	};
};

private _fnc_clean = {
	_resources call AS_fnc_cleanResources;
	sleep 30;
    [_task] call BIS_fnc_deleteTask;
    _mission call AS_fnc_mission_completed;
};

private _fnc_missionFailedCondition = {dateToNumber date > _fechalimnum};

private _fnc_missionFailed = {
	_task = [_mission,[side_blue,civilian],[_tskDesc,_tskTitle,_location],_position,"FAILED",5,true,true,"Kill"] call BIS_fnc_setTask;
	_mission remoteExec ["AS_fnc_mission_fail", 2];

	call _fnc_clean;
};

private _fnc_missionSuccessfulCondition = {not alive _target};
if (typeName _target == "GROUP") then {
    _fnc_missionSuccessfulCondition = {{alive _x} count units _target == 0};
};

private _fnc_missionSuccessful = {
	_task = [_mission,[side_blue,civilian],[_tskDesc,_tskTitle,_location],_position,"SUCCEEDED",5,true,true,"Kill"] call BIS_fnc_setTask;
	_mission remoteExec ["AS_fnc_mission_success", 2];

	call _fnc_clean;
};

[_fnc_missionFailedCondition, _fnc_missionFailed, _fnc_missionSuccessfulCondition, _fnc_missionSuccessful] call AS_fnc_oneStepMission;
