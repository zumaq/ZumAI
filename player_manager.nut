/**
 * @author Michal Zopp
 * @file player_manager.nut
 */

require("player.nut");
require("road_blockade.nut");

 /** TODO: LOAD AND SAVE THE PLAYERS WITH POINTS
  *  TODO: Maybe players can be represent dynamicly with id, check it out
  * @brief class Players, don't be fooled by the name. The name just states and handles
  *  one company as a one player. But in reality you can cooperate with other players
  *  in the same company. Currently Maximum Number of companies that can be on a server is 15.
  */
class PlayerManager
{
	_player_list = null;
	_roadBlockade = null;
	static MAX_PLAYERS = 15; // The maximum that allows to join on one server is 15, but for the convenince
							 // of the for cycles, because the id goes from 1 to 15.

	constructor(){
		this._player_list = array(0);
		for(local i = 0; i < MAX_PLAYERS; i++) {
			this._player_list.push(Player(i));
		}
		this._roadBlockade = RoadBlockade();
	}

	function AddKarmaPoints(playerID, points){
		if((playerID > (MAX_PLAYERS - 1))  || playerID < 0)	{
			AILog.Info("PlayerID out of bounds.");
			return false;
		}
		this._player_list[playerID].AddKarmaPoints(points);
		return true;
	}

	function AddKarmaPointsToAll(){
		points = 20;
		for(local i = 0; i < MAX_PLAYERS; i++) {
			this._player_list[i].AddKarmaPoints(points);
		}
		return true;
	}

	function ResetPlayerPoints(playerID){
		if((playerID > (MAX_PLAYERS - 1))  || playerID < 0)	{
			AILog.Info("PlayerID out of bounds.");
			return false;
		}
		this._player_list[playerID].ResetKarmaPoints();
		return true;
	}

	function AssignTowns(){
		local townlist = AITownList();
		this.ClearAllPlayersTownsRating();
		for(local l = townlist.Begin(); !townlist.IsEnd(); l = townlist.Next()) {
			for(local i = 0; i < MAX_PLAYERS; i++) {
				if (-1 == AITown.GetRating(l, i)){
					continue;
				}
				this._player_list[i].AddTown(l);
			}
		}
	}

	function ClearAllPlayersTownsRating(){
		for(local i = 0; i < MAX_PLAYERS; i++) {
			this._player_list[i].ClearTowns();
		}
	}

	function CheckVehicleBlockade(vehicleID){
		if (AIVehicle.GetCurrentSpeed(vehicleID) == 0 && AIVehicle.GetState(vehicleID) == AIVehicle.VS_RUNNING){
			AILog.Info("VEHICLE Stopped")
			AIController.Sleep(20);
			if (AIVehicle.GetCurrentSpeed(vehicleID) == 0 && AIVehicle.GetState(vehicleID) == AIVehicle.VS_RUNNING){
				local tile = AIVehicle.GetLocation(vehicleID);
				AILog.Info("VEHICLE RUNNING BUT STOPPED, THERE IS A BLOCKADE AROUND x: "
						   + AIMap.GetTileX(tile) + " y: " + AIMap.GetTileY(tile));
				//AIVehicle.ReverseVehicle(vehicleID);
				//AIController.Sleep(25);
				return tile;
			}
			return null;
		}
		return null;
	}

	function CheckForDestroyedBlockades(){
		for(local i = 0; i < MAX_PLAYERS; i++) {
			this._player_list[i].CheckRoadBlockedTiles();
			AILog.Info("Checking for destroyed blockades");
		}
	}

  function CheckForDestroyedStationTiles(){
		for(local i = 0; i < MAX_PLAYERS; i++) {
			this._player_list[i].CheckStationTiles();
			AILog.Info("Checking for destroyed stations");
		}
	}

	function PunishPlayersByKarmaPoints(){
		this.ClearAllPlayersTownsRating();
		this.AssignTowns();
		for(local i = 0; i < MAX_PLAYERS; i++) {
			AILog.Info("Checking player with id: " + i);
			if (AICompany.IsMine(this._player_list[i]._player_id)){
				continue;
			}
			this._player_list[i].CheckAndPunish();
		}
	}

	function testHeliPorts(){
		this._player_list[0]._towns.BuildHeliPorts();
	}

	function testBuildBlockade(){
		this._player_list[0]._towns.BuildRoadBlockade();
	}

	function testRemoveBlockade(){
		this._player_list[0]._towns.MakeBlockadePassable();
	}

	function testDepotDestroy(){
		this._player_list[0]._towns.DestroyDepoTileInCity();
	}

	function testSurroundCity(){
		this._player_list[0]._towns.SurroundCityWithRails();
	}

	function CheckIfArrayContainsTile(tileArray, tile){
		if (tile == null){
			return null;
		}
		local candidateTiles = array(0);
		candidateTiles.push(tile + AIMap.GetTileIndex(0, 1));
		candidateTiles.push(tile + AIMap.GetTileIndex(1, 0));
		candidateTiles.push(tile + AIMap.GetTileIndex(0, -1));
		candidateTiles.push(tile + AIMap.GetTileIndex(-1, 0));
		// array.find() dosen't work dispite the documentation, i have to iterate throught both
		for(local k=0; k<tileArray.len(); k++){
			for(local i=0; i<candidateTiles.len(); i++){
				if (tileArray[k] == candidateTiles[i]){
					return candidateTiles[i];
				}
			}
		}
		return false;
	}

	function ArrayFind(array, node){
		for(local i=0; i<array.len(); i++){
			if (array[i] == node){
				return true;
			}
		}
		return false;
	}

	function CheckForIndustry(tile){
		//checking for industries in the range of the station and adds them to array
		local industryArray = array(0);
		for (local distance=1 ; distance <=4; distance++) {
			local candidateTile = tile + AIMap.GetTileIndex(-distance,-distance);
			local moves = distance * 2;
			local industryID = 65535; //there is no industry if the ID is 65535
			for (local l = 0; l < 4; l++){
				for (local i = 0; i < moves; i++){
					AILog.Info("CheckIndustry cycle: " + i +
								"tile x: " + AIMap.GetTileX(candidateTile) + "tile y: " + AIMap.GetTileY(candidateTile));
					industryID = AIIndustry.GetIndustryID(candidateTile);
					if (industryID != 65535){
						if (this.ArrayFind(industryArray, industryID) == false){
							industryArray.push(industryID);
						}
					}
					if(l == 0){
						candidateTile = candidateTile + AIMap.GetTileIndex(0,1);
					}
					if(l == 1){
						candidateTile = candidateTile + AIMap.GetTileIndex(1,0);
					}
					if(l == 2){
						candidateTile = candidateTile + AIMap.GetTileIndex(0,-1);
					}
					if(l == 3){
						candidateTile = candidateTile + AIMap.GetTileIndex(-1,0);
					}
				}
			}
		}
		return industryArray;
	}

	function CheckAndPunishStations(industry){
		local array = array(0);
		local tile = AIIndustry.GetLocation(industry);
		for (local distance=1 ; distance <=7; distance++) {
			local candidateTile = tile + AIMap.GetTileIndex(-distance,-distance);
			local moves = distance * 2;
			for (local l = 0; l < 4; l++){
				for (local i = 0; i < moves; i++){
					AILog.Info("CheckOtherStation cycle: " + i +
								"tile x: " + AIMap.GetTileX(candidateTile) + "tile y: " + AIMap.GetTileY(candidateTile));
					if (AITile.IsStationTile(candidateTile) && !AICompany.IsMine(AITile.GetOwner(candidateTile))
						&& AIIndustry.GetDistanceManhattanToTile(industry, candidateTile) < 13){
						AILog.Info("Found station at industry punish owner: " + AITile.GetOwner(candidateTile));
						array.push(candidateTile);
						//this.AddKarmaPoints(AITile.GetOwner(candidateTile), -50);
					}
					if(l == 0){
						candidateTile = candidateTile + AIMap.GetTileIndex(0,1);
					}
					if(l == 1){
						candidateTile = candidateTile + AIMap.GetTileIndex(1,0);
					}
					if(l == 2){
						candidateTile = candidateTile + AIMap.GetTileIndex(0,-1);
					}
					if(l == 3){
						candidateTile = candidateTile + AIMap.GetTileIndex(-1,0);
					}
				}
			}
		}
		return array;
	}

	function CheckForOtherIndustryStations(stationTile){
		local industries = this.CheckForIndustry(stationTile);
		local tileArray = array(0);
		for(local i = 0; i < industries.len(); ++i) {
			tileArray.extend(this.CheckAndPunishStations(industries[i])); //test this
		}
    for (local i=0; i<tileArray.len(); i++){
      local owner = AITile.GetOwner(stationTiles[i]);
      if (this._player_list[i].IsStationTileSet(tileArray[i]) == false){
        this.CheckTileAndOwner(owner, tileArray[i]);
        this._player_list[owner]._station_tiles.push(tileArray[i]);
        AILog.Info("Added tile to list " + tileArray[i] + " owner: " + owner);
      }
    }
	}

	function FindOtherBusStops(tile){
		local array = array(0);
		for (local distance=1 ; distance <=8; distance++) { // 4 + 4 coverage because of rail stations has 4 tile coverege
			local candidateTile = tile + AIMap.GetTileIndex(-distance,-distance);
			local moves = distance * 2;
			for (local l = 0; l < 4; l++){
				for (local i = 0; i < moves; i++){
					//AILog.Info("CheckOtherStation cycle: " + i +
					//			"tile x: " + AIMap.GetTileX(candidateTile) + "tile y: " + AIMap.GetTileY(candidateTile));
					if (AITile.IsStationTile(candidateTile) && !AICompany.IsMine(AITile.GetOwner(candidateTile))){
						AILog.Info("Found bus station punish owner: " + AITile.GetOwner(candidateTile));
						array.push(candidateTile);
						//this.AddKarmaPoints(AITile.GetOwner(candidateTile), -50);
					}
					if(l == 0){
						candidateTile = candidateTile + AIMap.GetTileIndex(0,1);
					}
					if(l == 1){
						candidateTile = candidateTile + AIMap.GetTileIndex(1,0);
					}
					if(l == 2){
						candidateTile = candidateTile + AIMap.GetTileIndex(0,-1);
					}
					if(l == 3){
						candidateTile = candidateTile + AIMap.GetTileIndex(-1,0);
					}
				}
			}
		}
		return array;
	}

  function CheckTileAndOwner(owner, tile){
      if (AIRoad.IsRoadStationTile(tile)){
        this.AddKarmaPoints(owner, -30);
        AILog.Info("RoadStation Tile");
        return;
      }
      if (AIRail.IsRailStationTile(tile)){
        this.AddKarmaPoints(owner, -10);
        AILog.Info("Rail Station Tile");
        return;
      }
      if (AIAirport.IsAirportTile(tile)){
        this.AddKarmaPoints(owner, -15);
        AILog.Info("Airport Tile");
        return;
      }
  }

	function CheckForOtherTownStations(stationTile){
		//add them to array and punish by that
		local stationTiles = this.FindOtherBusStops(stationTile);
		for (local i=0; i<stationTiles.len(); i++){
		  local owner = AITile.GetOwner(stationTiles[i]);
		  if (this._player_list[owner].IsStationTileSet(stationTiles[i]) == false){
			this.CheckTileAndOwner(owner, stationTiles[i]);
			this._player_list[owner]._station_tiles.push(stationTiles[i]);
			AILog.Info("Added tile to list " + stationTiles[i] + " owner: " + owner);
		  }
		}
	}
	
	function NormalPathfinder(src, dest){
		AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
		local pathfinder = RoadPathFinder();
		pathfinder.InitializePath([src], [dest]);

		local path = false;
		while (path == false) {
			path = pathfinder.FindPath(100);
			AIController.Sleep(1);
		}
		if (path == null) {
			return null;
		}
		
		return path;
	}
	
	function CheckForRoadBlockadeFromSource(src, dest, vehicleTile){
		AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
		local pathfinder = RoadPathFinder();
		pathfinder.cost.no_existing_road=200000;
		pathfinder.InitializePath([src], [dest]);

		local path = false;
		local counter = 0;
		while (path == false || counter < 4) {
			path = pathfinder.FindPath(100);
			AIController.Sleep(1);
		}
		if (path == null) {
			/* No path was found. */
			AILog.Error("pathfinder.FindPath return null, probably there is removed tile");
			//this.PunishRemovedTownTiles(this.NormalPathfinder(src, dest));
			return;
		}
		
		return this.CheckForRoadBlockadeOnPath(path, vehicleTile)
	}
	
	function PunishRemovedTownTiles(_path){
		if (_path == null) {
			AILog.Error("path is null");
			return false;
		}
		local path = _path;
		local k = 0
		while (path != null) {
			local par = path.GetParent();
			if (par != null) {
				k++;
			}
			path = par;
		}
		
		AILog.Info("PunishRemovedTownTiles k: " + k);
		path = _path
		local i = 0;
		while (path != null) {
			local par = path.GetParent();
			if (par != null) {
				AILog.Info("i: " + i);
				if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
					if ((i<10 || i>(k-10)) && AIRail.IsRailTile(path.GetTile()) && !AIRoad.IsRoadTile(path.GetTile())) {
						if (this._player_list[owner].IsRoadBlockedTileSet(path.GetTile()) == false){
							this.AddKarmaPoints(owner, -30);
							this._player_list[owner]._road_blockade_tiles.push(path.GetTile());
							AILog.Info("Added Blocked Town Tile to list " + path.GetTile() + " owner: " + owner);
							this._roadBlockade.GetAroundBlockedTile(path.GetTile());
						}
					}
				}
				i++;
			}
			path = par;
		}
	}
	
	function CheckForRoadBlockadeOnPath(path, vehicleTile){
		local array = this._roadBlockade.IsBlockadeOnPath(path);
		if (array == false){
			AILog.Info("There is no blockade");
			return false;
		}
		
		local blockadeTile = this.CheckIfArrayContainsTile(array, vehicleTile)
		if (blockadeTile == false || blockadeTile == null){
			AILog.Info("There is no blockade on that Tile, false alarm");
			return false;
		}

		local owner = null;
		if (AIRoad.IsRoadTile(blockadeTile + AIMap.GetTileIndex(0, 1))){
			owner = this._roadBlockade.WhoDidTheBlockade(blockadeTile, 1);
		} else {
			owner = this._roadBlockade.WhoDidTheBlockade(blockadeTile, 0);
		}
		AILog.Info("-----> Blockade on tile: " + blockadeTile + " owner: " + owner);
		if (this._player_list[owner].IsRoadBlockedTileSet(blockadeTile) == false){
			this.AddKarmaPoints(owner, -30);
			this._player_list[owner]._road_blockade_tiles.push(blockadeTile);
			AILog.Info("Added tile to list " + blockadeTile + " owner: " + owner);
			this._roadBlockade.GetAroundBlockedTile(blockadeTile);
		} else {
			if (AIController.GetTick() % 2 != 0 || this._roadBlockade.GetAroundBlockedSwitchTile(blockadeTile) == false){
			} else {
				this._roadBlockade.GetAroundBlockedTile(blockadeTile);
			}
		}
	}

	function CheckForDepoTileBlockade(depoTile){
		local newDepo = this._roadBlockade.IsBlockadeInFrontOfDepo(depoTile);
		local tileFront = AIRoad.GetRoadDepotFrontTile(depoTile);
		if (newDepo == null){
			return depoTile;
		}
		local owner = AITile.GetOwner(tileFront);
		this.AddKarmaPoints(owner, -50);
		this._player_list[owner]._road_blockade_tiles.push(tileFront);
		if(newDepo == 0){
			AILog.Info("new depot couldn't be built");
			return depoTile;
		} else {
			AILog.Info("new depot built");
			return newDepo;
		}
	}

	function PrintPoints(){
		AILog.Info("Player karma points and town ratings---------------------------");
		for(local i = 0; i < MAX_PLAYERS; i++) {
			local points = this._player_list[i]._karma_points;
			local id = this._player_list[i]._player_id;
			AILog.Info("Player with id: " + id + ", has karma of: " + points + ". " + this._player_list[i]._station_tiles.len());
			this._player_list[i]._towns.PrintTownRatings();
			for(local k=0; k < this._player_list[i]._station_tiles.len(); k++){
				AILog.Info("Station tile: " + this._player_list[i]._station_tiles[k]);
			}
		}
	}
	
	function PrintStations(){
		for(local i = 0; i < MAX_PLAYERS; i++) {
			AILog.Info("Player with id: " + this._player_list[i]._player_id + ". ");
			for(local k=0; k < this._player_list[i]._station_tiles.len(); k++){
				AILog.Info("------> Station tile: " + this._player_list[i]._station_tiles[k]);
			}
		}
	}

	function Save(){
		local playerList = array(0);
		//AILog.Info("Player Manager save");
		for(local i = 0; i < MAX_PLAYERS; i++) {
			playerList.push(this._player_list[i].Save());
		}
		local data = {
			players = playerList
		};

		return data;
	}

	function Load(data){
		local playerManager = PlayerManager();
		playerManager._player_list.clear();
		if ("players" in data){
			for (local i=0; i < 15; i++) {
				local player = Player.Load(data.players[i]);
				playerManager._player_list.push(player);
			}
		}
		return playerManager;
	}
}
