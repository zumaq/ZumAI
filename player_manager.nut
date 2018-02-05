/**
 * @author Michal Zopp
 * @file player_manager.nut
 */
 
require("player.nut");

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
	
	constructor(){
		for(local i = 0; i < MAX_PLAYERS; i++) {
			this._player_list.push(Player(i));
		}
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