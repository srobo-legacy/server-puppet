import sys
sys.path.insert(0, "/srv/srcomp-http")

from app import app as application

application.config["COMPSTATE"] = "/srv/srcomp-http/compstate"
