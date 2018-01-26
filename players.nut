/**
 * @author Michal Zopp
 * @file players.nut
 */

 /**
  * @brief class Players, don't be fooled by the name. The name just states and handles
  *  one company as a one player. But in reality you can cooperate with other players
  *  in the same company. Currently Maximum Number of companies that can be on a server is 15.
  */
class Players
{ 
	
	static MAX_PLAYERS = 15; // The maximum that allows to join on one server
	static MAX_KARMA_POINTS = 200; // Maximum points you can have
	static DEFAULT_KARMA_POINTS = 100; // Default poins for karma
	static MIN_KARMA_POINTS = 0; // Minimum points you can have
	
	_karma_points = array(15);
	
	constructor(){
		for(local i = 0; i < MAX_PLAYERS; ++i) {
			_karma_points[i]= DEFAULT_KARMA_POINTS;
		}
	}
	
	function addKarmaPoints(playerID, points){
		if((playerID > (MAX_PLAYERS - 1))  || playerID < 0){
			AILog.Info("PlayerID out of bounds.");
			return false;
		}
		
		_karma_points[playerID]= _karma_points[playerID] + points;
		return true;
	}
	
	function resetPlayerPoints(playerID){
		if((playerID > (MAX_PLAYERS - 1))  || playerID < 0){
			AILog.Info("PlayerID out of bounds.");
			return false;
		}
		
		_karma_points[playerID]= DEFAULT_KARMA_POINTS;
		return true;
	}
	
	function printPoints(){
		AILog.Info("Player karma points ---------------------------");
		for(local i = 0; i < MAX_PLAYERS; ++i) {
			AILog.Info("Player with id: " + i + ", has karma of: " + _karma_points[i] + ".");
		}
	}
	
}