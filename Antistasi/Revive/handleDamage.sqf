params ["_unit", "_part", "_dam", "_injurer"];

if (isPlayer _unit) then {
	private _owner = player getVariable ["owner",player];
	if (_owner != player) then {
		if ((isNull _injurer) and (_unit distance fuego < 10)) then {
			_dam = 0;
		} else {
			removeAllActions _unit;
			selectPlayer _owner;
			_unit setVariable ["owner",_owner,true];
			{[_x] joinsilent group player} forEach units group player;
			group player selectLeader player;
			hint "Returned to original Unit as controlled AI received damage";
		};
	};
} else {
	if (local _unit) then {
		private _owner = _unit getVariable "owner";
		if (!isNil "_owner") then {
			if (_owner==_unit) then {
				if ((isNull _injurer) and (_unit distance fuego < 10)) then {
					_dam = 0;
				} else {
					removeAllActions player;
					selectPlayer _owner;
					{[_x] joinsilent group player} forEach units group player;
					group player selectLeader player;
					hint "Returned to original Unit as it received damage";
				};
			};
		};
	};
};

private _currentTime = [time, serverTime] select isMultiplayer;
if ((_part == "head") and not (_unit call AS_fnc_isUnconscious)) then {
	_unit setVariable ["firstHitTime", _currentTime, false];
};

if not (_part in ["hand_l","hand_r","leg_l","leg_r","arms"]) then {
	if (_dam > 0.95) exitWith {
		private _sameHit = (_unit getVariable ["firstHitTime", _currentTime]) + 0.5 >= _currentTime;
		if (_sameHit and _dam < 10) then {
			_dam = 0.9;
			if not (_unit call AS_fnc_isUnconscious) then {
				[_unit,true] call AS_fnc_setUnconscious;
			};
		} else {
			if (isPlayer _unit) then {
				_dam = 0;
				[_unit] spawn respawn;
				if (isPlayer _injurer and {_injurer != _unit}) then {
					// a player killed another unconcious player
					[_injurer,60] remoteExec ["castigo",_injurer]
				};
			};
		};
	};
	if ((not (_unit call AS_fnc_isUnconscious)) and _dam > 0.2) then {
		[_unit,_unit] spawn cubrirConHumo;
	};
	if ((not (_unit call AS_fnc_isUnconscious)) and _dam > 0.25) then {
		if (isPlayer (leader group _unit)) then {
			if autoheal then {
				if (_unit getVariable ["ayudado", false]) then {
					[_unit] call pedirAyuda;
				};
			};
		};
	};
};
_dam
