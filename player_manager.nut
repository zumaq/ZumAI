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
	
	function addKarmaPoints(playerID, points){
		if((playerID > (MAX_PLAYERS - 1))  || playerID < 0)	{
			AILog.Info("PlayerID out of bounds.");
			return false;
		}
		this._player_list[playerID].AddKarmaPoints(points);
		return true;
	}
	
	function resetPlayerPoints(playerID){
		if((playerID > (MAX_PLAYERS - 1))  || playerID < 0)	{
			AILog.Info("PlayerID out of bounds.");
			return false;
		}
		this._player_list[playerID].ResetKarmaPoints();
		return true;
	}
	
	function assignTowns(){
		local townlist = AITownList();
		this.clearAllPlayersTownsRating();
		for(local l = townlist.Begin(); !townlist.IsEnd(); l = townlist.Next()) {
			for(local i = 0; i < MAX_PLAYERS; i++) {
				this._player_list[i].AddTown(l);
			}
		}
	}
	
	function clearAllPlayersTownsRating(){
		for(local i = 0; i < MAX_PLAYERS; i++) {
			this._player_list[i].ClearTowns();
		}
	}
	
	function testHeliPorts(){
		this._player_list[0]._towns.BuildHeliPorts();
	}
	
	function testDepotDestroy(){
		this._player_list[0]._towns.DestroyDepoTileInCity();
	}
	
	function testSurroundCity(){
		this._player_list[0]._towns.SurroundCityWithRails();
	}
	
	function checkForRoadBlockadeOnPath(path){
		local array = this._roadBlockade.IsBlockadeOnPath(path);
		if (array == false){
			AILog.Info("There is no blockade");
			return false;
		}
		
		local count = array.len();
		local owner = null;
		for(local i = 0; i<count; ++i) {
			if (AIRoad.IsRoadTile(array[i] + AIMap.GetTileIndex(0, 1))){
				owner = this._roadBlockade.WhoDidTheBlockade(array[i], 1);
			} else {
				owner = this._roadBlockade.WhoDidTheBlockade(array[i], 0);
			}
			AILog.Info("-----> Blockade on tile: " + array[i] + " owner: " + owner);
			this.AddKarmaPoints(owner, -50);
			this._player_list[owner]._road_blockade_tiles.push(array[i]);
			
			//this is just a test for a function if it works
			this._player_list[owner]._towns.DestroyDepoTileInCity();
		}
	}
	
	function printPoints(){
		AILog.Info("Player karma points and town ratings---------------------------");
		for(local i = 0; i < MAX_PLAYERS; i++) {
			local points = this._player_list[i]._karma_points;
			local id = this._player_list[i]._player_id;
			AILog.Info("Player with id: " + id + ", has karma of: " + points + ".");
			this._player_list[i]._towns.PrintTownRatings();
		}
	}
	
}