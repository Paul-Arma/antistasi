_jugador = player getVariable ["owner",player];

if (_jugador getVariable ["elegible",true]) then
	{
	_jugador setVariable ["elegible",false,true];
	if (_jugador == AS_commander) then
		{
		hint "You resign of being Commander. Other will take the command if there is someone suitable for it.";
		sleep 3;
		[] remoteExec ["assignStavros",2];
		}
	else
		{
		hint "You decided not to be elegible for Commander.";
		};
	}
else
	{
	hint "You are now elegible to be Commander of the FIA forces.";
	_jugador setVariable ["elegible",true,true];
	};