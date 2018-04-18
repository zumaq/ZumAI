import("pathfinder.road", "RoadPathFinder", 4);
import("pathfinder.rail", "RailPathFinder", 1);

require("pathfinder.nut");
require("player_manager.nut");
require("road_blockade.nut");

class ZumAI extends AIController
{
  _players = null;
  counter = null;
  depoTile = null;
  firstTile = null;
  lastTile = null;
  vehicle = array(6);
  train = null;
  _path = null;

  constructor()
  {
	_players = PlayerManager();
    counter = 0;
  }
}

function ZumAI::Start()
{
  if (!AICompany.SetName("ZumAI")) {
    local i = 2;
    while (!AICompany.SetName("ZumAI #" + i)) {
      i = i + 1;
    }
  }

  findAndBuildRoad();
  BuildVehicles(3);
  _players.AssignTowns();
  while (true) {
    if (this.GetTick() % 100 == 0)AILog.Info("I am a very new AI with a ticker called ZumAI and I am at tick " + this.GetTick());
	//if (this.GetTick() % 10 == 0) AILog.Info(
	//		AIIndustry.GetDistanceSquareToTile(AIIndustry.GetIndustryID(AIMap.GetTileIndex(41,33)), AIMap.GetTileIndex(39,35)));

	//if (this.GetTick() % 200 == 0) CheckIndustry();
	//if (this.GetTick() % 200 == 0) CheckBusStops();
    //if (this.GetTick() % 500 == 0) _players.CheckForDestroyedStationTiles();
	if (this.GetTick() % 10 == 0) CheckVehicles();
	//if (this.GetTick() % 100 == 0) _players.PrintStations();
	//if(this.GetTick() % 200 == 0) _players.CheckForDestroyedBlockades();
    //if(this.GetTick() % 450 == 0) _players.PrintPoints();
	//if(this.GetTick() % 500 == 0) _players.PunishPlayersByKarmaPoints();
	//if(this.GetTick() % 500 == 0) _players.testBuildBlockade();
	//if(this.GetTick() % 400 == 0) _players.testRemoveBlockade();
	//if(this.GetTick() % 200 == 0) _players.testSurroundCity();
	//if(this.GetTick() % 300 == 0) _players.CheckForRoadBlockadeOnPath(_path);
	//if(this.GetTick() % 1500 == 0) VehicleTurnAround(3);
	//if(this.GetTick() % 200 == 0) RoadBlockade.IsBlockadeInFrontOfDepo(depoTile);
	//if(this.GetTick() % 5000 == 0) RoadBlockade.IsBlockadeOnPath(_path);
	this.Sleep(1);

	while (AIEventController.IsEventWaiting()) {
	  local e = AIEventController.GetNextEvent();
	  switch (e.GetEventType()) {
		case AIEvent.ET_VEHICLE_CRASHED:
		  local ec = AIEventVehicleCrashed.Convert(e);
		  local v  = ec.GetVehicleID();
		  AILog.Info("We have a crashed vehicle (" + v + ")");
		  /* Handle the crashed vehicle */
		  break;

		case AIEvent.ET_COMPANY_NEW:
		  local ec = AIEventCompanyNew.Convert(e);
		  local c  = ec.GetCompanyID();
		  AILog.Info("We have a new company, id: (" + c + ")");
		  break;
		}
	}

	//AILog.Warning(AIError.GetLastErrorString());
	if(AIError.GetLastError() == AIError.ERR_VEHICLE_IN_THE_WAY){
		AILog.Info("Vehicle in the way!!");
	}
  }
}

function findAndBuildRoad(){
  /* Get a list of all towns on the map. */
  local townlist = AITownList();

  /* Sort the list by population, highest population first. */
  townlist.Valuate(AITown.GetPopulation);
  townlist.Sort(AIAbstractList.SORT_BY_VALUE, false);

  /* Pick the two towns with the highest population. */
  local townid_a = townlist.Begin();
  local townid_b = townlist.Next();

  /* Printing town ratings in the town to determine how the rating work */
  AILog.Info("Town: " + AITown.GetName(townid_a) + " comp_id 0, has rating: " + AITown.GetRating(townid_a,0));
  AILog.Info("Town: " + AITown.GetName(townid_a) + " comp_id 1, has rating: " + AITown.GetRating(townid_a,1));
  AILog.Info("Town: " + AITown.GetName(townid_a) + " comp_id 2, has rating: " + AITown.GetRating(townid_a,2));


  /* Print the names of the towns we'll try to connect. */
  AILog.Info("Going to connect " + AITown.GetName(townid_a) + " to " + AITown.GetName(townid_b));

  /* Tell OpenTTD we want to build normal road (no tram tracks). */
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

  /* Create an instance of the pathfinder. */
  local pathfinder = RoadPathFinder();

  /* Set the cost for making a turn extreme high. */
  //pathfinder.cost.turn = 5000;

  /* Give the source and goal tiles to the pathfinder. */
  pathfinder.InitializePath([AITown.GetLocation(townid_a)], [AITown.GetLocation(townid_b)]);

  /* Try to find a path. */
  local path = false;
  while (path == false) {
    path = pathfinder.FindPath(100);
    this.Sleep(1);
  }

  _path = path;

  if (path == null) {
    /* No path was found. */
    AILog.Error("pathfinder.FindPath return null");
  }

  firstTile = path.GetTile();
  local firstTileNext = path.GetParent().GetTile();
  lastTile = null;
  local lastTileNext = null;
  local first = 1;
  local depoBuilt = 0;
  local i=0;

  /* If a path was found, build a road over it. */
  while (path != null) {
    local par = path.GetParent();

    if (par != null) {
      lastTile = path.GetTile();
	  //AIRoad.BuildRoadDepot(lastTile - AIMap.GetTileIndex(2,0), lastTile - AIMap.GetTileIndex(1,0));
	  if(!depoBuilt){
		if((AITile.GetSlope(lastTile) == AITile.SLOPE_FLAT) &&
			(AITile.GetSlope(lastTile - AIMap.GetTileIndex(1,0)) == AITile.SLOPE_FLAT) &&
			  AIRoad.BuildRoadDepot(lastTile - AIMap.GetTileIndex(1,0), lastTile))
		{
		  /* Better depo placement and workarounds ! */
		  AIRoad.BuildRoad(lastTile, lastTile - AIMap.GetTileIndex(1,0));
		  AIRoad.BuildRoad(lastTile, lastTile + AIMap.GetTileIndex(0,1));
		  AIRoad.BuildRoad(lastTile + AIMap.GetTileIndex(0,1), lastTile + AIMap.GetTileIndex(-1,1));
		  AIRoad.BuildRoad(lastTile + AIMap.GetTileIndex(-1,1), lastTile + AIMap.GetTileIndex(-2,1));
		  AIRoad.BuildRoad(lastTile + AIMap.GetTileIndex(-2,1), lastTile - AIMap.GetTileIndex(2,0));
	      AILog.Info("Depo was built !");
		  depoTile = lastTile - AIMap.GetTileIndex(1,0);
		  depoBuilt = 1;
		}
	  }
      if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
        if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
          AILog.Info("Problem, cant build road, maybe it is built.");
        }
		if (AIRail.IsLevelCrossingTile(par.GetTile())){
		  if (!first){
		    RoadBlockade.BuildRoadBlockade(par.GetParent().GetTile(), 1);
			first = 1;
		  }else{
		  AILog.Warning("Who did the blockade: " + RoadBlockade.WhoDidTheBlockade(par.GetTile(),0));
		  AILog.Info("We cant build here, its a road and rail tile. PUNISH!!! ownerid: " + AITile.GetOwner(path.GetTile()));
		  _players.AddKarmaPoints(AITile.GetOwner(path.GetTile()),-20);
		  local endTile = par.GetParent();
		  while (AIRail.IsRailTile(endTile.GetTile())){
			endTile = endTile.GetParent();
		  }
		  RoadBlockade.GetAroundBlockedTile(par.GetTile());
		  //RoadBlockade.GetAroundBlockade(path.GetTile(), endTile.GetTile());
		  }
		}
      } else {
        /* Build a bridge or tunnel. */
        if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
          /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
          if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
          if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
            if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
              /* An error occured while building a tunnel. TODO: handle it. */
            }
          } else {
            local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
            bridge_list.Valuate(AIBridge.GetMaxSpeed);
            bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
            if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
              /* An error occured while building a bridge. TODO: handle it. */
            }
          }
        }
      }
    }
	i++;
	lastTileNext = path.GetTile();
    path = par;
  }
  AILog.Info("Done");

  AITile.DemolishTile(firstTile);
  AITile.DemolishTile(lastTile);

  if (AIRoad.BuildDriveThroughRoadStation(firstTile, firstTileNext, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) {
	AILog.Info("Station built in town!");
  } else {
	AILog.Info("Station not built in town!");
  }

  if (AIRoad.BuildDriveThroughRoadStation(lastTile, lastTileNext, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) {
	AILog.Info("Station built in town!");
  } else {
	AILog.Info("Station not built in town!");
  }
}

function BuildVehicles(number){
	local engineList = AIEngineList(AIVehicle.VT_ROAD);
	engineList.Valuate(AIEngine.GetRoadType);
	engineList.KeepValue(AIRoad.ROADTYPE_ROAD);

	engineList.Valuate(AIEngine.GetCargoType)
	engineList.KeepValue(0);

	  engineList.Valuate(AIEngine.GetMaxSpeed);
	  engineList.Sort(AIList.SORT_BY_VALUE, true);
	  local engine = engineList.Begin();
	  for(local i = 0; i<number; ++i){
	  vehicle[i] = AIVehicle.BuildVehicle(depoTile, engine);
		  if(AIVehicle.IsValidVehicle(vehicle[i])) {
			AIOrder.AppendOrder(vehicle[i], depoTile, AIOrder.AIOF_SERVICE_IF_NEEDED);
			AIOrder.AppendOrder(vehicle[i], firstTile, AIOrder.AIOF_NON_STOP_INTERMEDIATE);
			AIOrder.AppendOrder(vehicle[i], lastTile, AIOrder.AIOF_NON_STOP_INTERMEDIATE);
			AIVehicle.StartStopVehicle(vehicle[i]);
		  }
	  }
}

function CheckBusStops(){
	local tile = AIMap.GetTileIndex(21,44);
	local stationID = AIStation.GetStationID(tile);
	AILog.Info("checking station" + stationID);
	_players.CheckForOtherTownStations(tile)
	/*if (AIStation.HasStationType(stationID, AIStation.STATION_BUS_STOP)){ // cant check this because its not mine station
		AILog.Info("Has STation TYpe");
		_players.CheckForOtherTownStations(tile)
	}*/
}

function CheckIndustry(){
	local stationID = AIStation.GetStationID(AIMap.GetTileIndex(36,22));
	local industryID = AIIndustry.GetIndustryID(AIMap.GetTileIndex(36,36));
	_players.CheckForOtherIndustryStations(AIMap.GetTileIndex(45,29));
	AILog.Info(industryID);
	//AILog.Info(AIIndustry.GetDistanceManhattanToTile(industryID, AIMap.GetTileIndex(45,36)));
	/*for(local i=0; i<11; i++){
		AILog.Info(AIStation.GetCargoWaiting(stationID,i));
		if(AIStation.GetCargoRating(stationID, i)){
			AILog.Info(AICargo.GetCargoLabel(i) + " " + AIStation.GetCargoRating(stationID, i));
		}
	}
	AILog.Info(AIStation.GetCargoWaiting(stationID,1));*/
}

function CheckVehicles(){
	for(local i = 0; i<3; ++i){
		local tile = this._players.CheckVehicleBlockade(vehicle[i]);
		if (tile != null){
			this._players.CheckForRoadBlockadeOnPath(_path, tile);
		}
	}
}

function VehicleTurnAround(number){
	for(local i = 0; i<number; ++i){
		AIVehicle.ReverseVehicle(vehicle[i]);
	}
}

function BuildWorkAround(tileIndex, parTileIndex){
	AILog.Info("WORKAROUND THE LITTLE SCUMM");
	local tmpTile = tileIndex - AIMap.GetTileIndex(0,1);
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	local pathfinder = RoadPathFinder();
	pathfinder.cost.tile=5;
	pathfinder.cost.no_existing_road=-1000;
	pathfinder.cost.turn=1;

	pathfinder.InitializePath([tmpTile], [parTileIndex]);
	  local path = false;
	  while (path == false) {
		path = pathfinder.FindPath(50);
		this.Sleep(1);
	  }

	  if (path == null) {
		AILog.Error("pathfinder.FindPath return null");
	  }

	firstTile = path.GetTile();
  local firstTileNext = path.GetParent().GetTile();
  lastTile = null;
  local lastTileNext = null;
  local depoBuilt = 0;
  local i=0;

  /* If a path was found, build a road over it. */
  while (path != null) {
    local par = path.GetParent();

    if (par != null) {
      lastTile = path.GetTile();
        if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
          AILog.Info("Problem, cant build road, maybe it is built.");
        }
	}
	i++;
	lastTileNext = path.GetTile();
    path = par;
  }
}

function ZumAI::Save()
{
  AILog.Warning("Game being saved.");
  local players = this._players.Save();
  local table = {
		player_manager = players
	};
  return table;
}

function ZumAI::Load(version, data)
{
  AILog.Warning("Loading data.");
  if (data.rawin("player_manager")) {
	_players = PlayerManager.Load(data.rawget("player_manager"));
  }
  _players.PrintStations();
}
