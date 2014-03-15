import sys
sys.path.insert(0, "/srv/sr-comp-http")

from app import app as application

application.config["COMPSTATE"] = "/srv/sr-comp-http/compstate"
