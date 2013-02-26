<?php
require_once("lib/AuthClient.php");
require_once("lib/IDEAuthProvider.php");
#### COPY THIS FILE TO config.inc.php AND EDIT TO SUIT ####

## Set up some session stuff
ini_set("session.save_path", dirname(__FILE__) . "/../sessions/");
ini_set("session.gc_maxlifetime", 3600); //1 hour session time

ConfigManager::SetProvider(new IDEAuthProvider("https://www.studentrobotics.org/ide/"));

?>
