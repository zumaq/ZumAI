class ZumAI extends AIInfo {
  function GetAuthor()      { return "Michal Zopp"; }
  function GetName()        { return "ZumAI"; }
  function GetDescription() { return "my testin AI"; }
  function GetVersion()     { return 1; }
  function GetDate()        { return "2007-03-17"; }
  function CreateInstance() { return "ZumAI"; }
  function GetShortName()   { return "ZUM"; }
  function GetAPIVersion()  { return "1.0"; }
}

RegisterAI(ZumAI());