params ["_mission"];
private _location = _mission call AS_fnc_mission_location;
private _position = [AS_antenasPos_alive,_location call AS_fnc_location_position] call BIS_fnc_nearestPosition;

private _antenna = nearestBuilding _position;
private _nombredest = [_location] call localizar;

private _tiempolim = 120;
private _fechalim = [date select 0, date select 1, date select 2, date select 3, (date select 4) + _tiempolim];
private _fechalimnum = dateToNumber _fechalim;

private _tskTitle = _mission call AS_fnc_mission_title;
private _tskDesc = format [localize "STR_tskDesc_DesAntenna",_nombredest,numberToDate [2035,_fechalimnum] select 3,numberToDate [2035,_fechalimnum] select 4, A3_STR_INDEP];

private _mrkfin = createMarker [format ["DES%1", random 100], _position];
_mrkfin setMarkerShape "ICON";

private _task = [_mission,[side_blue,civilian],[_tskDesc,_tskTitle,_mrkfin],_position,"CREATED",5,true,true,"Destroy"] call BIS_fnc_setTask;

private _fnc_clean = {
	[[], [], [_mrkfin]] call AS_fnc_cleanResources;

	sleep 30;
    [_task] call BIS_fnc_deleteTask;
    _mission call AS_fnc_mission_completed;
};

private _fnc_missionFailedCondition = {dateToNumber date > _fechalimnum};

private _fnc_missionFailed = {
	_task = [_mission,[side_blue,civilian],[_tskDesc,_tskTitle,_mrkfin],_position,"FAILED",5,true,true,"Destroy"] call BIS_fnc_setTask;
	[_mission] remoteExec ["AS_fnc_mission_fail", 2];
};

private _fnc_missionSuccessfulCondition = {(not alive _antenna) or (_location call AS_fnc_location_side == "FIA")};

private _fnc_missionSuccessful = {
	_task = [_mission,[side_blue,civilian],[_tskDesc,_tskTitle,_mrkfin],_position,"SUCCEEDED",5,true,true,"Destroy"] call BIS_fnc_setTask;
	[_mission, _position] remoteExec ["AS_fnc_mission_success", 2];
};

[_fnc_missionFailedCondition, _fnc_missionFailed, _fnc_missionSuccessfulCondition, _fnc_missionSuccessful] call AS_fnc_oneStepMission;
call _fnc_clean;
