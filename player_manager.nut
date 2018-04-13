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
	
	static MAX_PLAYERS = 15; // The maximum that allows to join on one server is 15, but for the convenince
							 // of the for cycles, because the id goes from 1 to 15.
	_player_list = array(0);
	_roadBlockade = null;
	
	constructor(){
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
				AIVehicle.ReverseVehicle(vehicleID);
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
	
	function CheckForRoadBlockadeOnPath(path, vehicleTile){
		local array = this._roadBlockade.IsBlockadeOnPath(path);
		if (array == false){
			AILog.Info("There is no blockade");
			return false;
		}
		local blockadeTile = this.CheckIfArrayContainsTile(array, vehicleTile)
		if (blockadeTile == false){
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
			AILog.Info("new depot could't be built");
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
			AILog.Info("Player with id: " + id + ", has karma of: " + points + ".");
			this._player_list[i]._towns.PrintTownRatings();
		}
	}
	
}