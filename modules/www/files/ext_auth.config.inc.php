<?php
require_once("lib/AuthClient.php");
require_once("lib/IDEAuthProvider.php");
#### COPY THIS FILE TO config.inc.php AND EDIT TO SUIT ####

## Set up some session stuff
ini_set("session.save_path", dirname(__FILE__) . "/../sessions/");
ini_set("session.gc_maxlifetime", 3600); //1 hour session time

$priv_key = file_get_contents("/var/www/external-auth/keys/server");
$pub_key = file_get_contents("/var/www/external-auth/keys/server.pub");

ConfigManager::SetKeys($priv_key, $pub_key);

ConfigManager::SetProvider(new IDEAuthProvider("https://www.studentrobotics.org/ide/"));

?>
