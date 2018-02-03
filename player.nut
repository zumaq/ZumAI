/**
 * @author Michal Zopp
 * @file player.nut
 */

 /** TODO: LOAD AND SAVE THE PLAYERS WITH POINTS
  * @brief class Player, don't be fooled by the name. The name just states and handles
  *  one company as a one player. But in reality you can cooperate with other players
  *  in the same company. Currently Maximum Number of companies that can be on a server is 15.
  */
class Player
{
	static MAX_KARMA_POINTS = 200; // Maximum points you can have
	static DEFAULT_KARMA_POINTS = 100; // Default poins for karma
	static MIN_KARMA_POINTS = 0; // Minimum points you can have
	_player_id=null;
	_road_blockade_tiles = null; //this is a array of blocked tiles by the particular player
	_karma_points=null;
	
	constructor(id){
		this._player_id=id;
		this._road_blockade_tiles = array(0);
		this._karma_points=DEFAULT_KARMA_POINTS;
	}
	
	function AddKarmaPoints(points);
	
	function ResetKarmaPoints();
	
	function AddRoadBlockedTile(tile);
	
	function RemoveRoadBlockedTile(tile);
	
	function IsRoadBlockedTileSet(tile);
}

function Player::AddKarmaPoints(points){
	this._karma_points = this._karma_points + points;
	if(this._karma_points > MAX_KARMA_POINTS){
		this._karma_points = MAX_KARMA_POINTS;
	}
	if(this._karma_points < MIN_KARMA_POINTS){
		this._karma_points = MIN_KARMA_POINTS;
	}
	return this._karma_points
}

function Player::ResetKarmaPoints(){
	this._karma_points = DEFAULT_KARMA_POINTS;
	return true;
}

function Player::AddRoadBlockedTile(tile){
	if (Player.IsRoadBlockedTileSet(tile)) {
		AILog.Info("This tile was already set.");
		return false;
	}
	this._road_blocked_tile.push(tile);
	return true;
}

function Player::RemoveRoadBlockedTile(tile){
	if (!Player.IsRoadBlockedTileSet(tile)) {
		AILog.Info("This tile was already removed.");
		return false;
	}
	this._road_blocked_tile.pop(tile);
	this._karma_points.AddKarmaPoints(50); //player has removed blockade so he deserves points.
	return true;
}

function Player::IsRoadBlockedTileSet(tile){
	local count = this._road_blocked_tile.len();
	for(local i = 0; i < count; ++i) {
		if (_road_blocked_tile[i] == tile) {
			return true;
		}
	}
	return false;
}
