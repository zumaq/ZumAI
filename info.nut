class ZumAI extends AIInfo {
  function GetAuthor()      { return "Newbie AI Writer"; }
  function GetName()        { return "ZumAI"; }
  function GetDescription() { return "An example AI by following the tutorial at http://wiki.openttd.org/"; }
  function GetVersion()     { return 1; }
  function GetDate()        { return "2007-03-17"; }
  function CreateInstance() { return "ZumAI"; }
  function GetShortName()   { return "XXXX"; }
  function GetAPIVersion()  { return "1.0"; }
}

RegisterAI(ZumAI());