import os

os.environ['TRAC_ENV'] = '/srv/trac'
os.environ['PYTHON_EGG_CACHE'] = '/srv/trac/.python-eggs'

import trac.web.main
application = trac.web.main.dispatch_request
