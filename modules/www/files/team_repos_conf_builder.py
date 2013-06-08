#!/usr/bin/env python

from __future__ import with_statement

import sys
import string
import os
import ldap

if len(sys.argv) != 2:
	print >>sys.stderr, "Usage: team_repo_conf_builder.py outputfile"
	sys.exit(1)

TEMPLATE_FILE = 'team_repos_conf_template.conf'
OUTPUT_FILE = sys.argv[1]
TEAM_START_MARKER = '## --PER-TEAM-START-- ##'
TEAM_END_MARKER = '## --PER-TEAM-END-- ##'
TEAM_PREFIX = 'team-'

content = None
with open(TEMPLATE_FILE) as f:
	content = f.readlines()

start_line = -1
end_line = -1

line_no = 0
for line in content:
	line = line.strip()
	if line == TEAM_START_MARKER:
		start_line = line_no

	if line == TEAM_END_MARKER and start_line >= 0:
		end_line = line_no
		break

	line_no += 1

if start_line == -1:
	print >> sys.stderr, "Failed to find teams' start marker"

if end_line == -1:
	print >> sys.stderr, "Failed to find teams' end marker"
	exit(1)

template_lines = content[ start_line + 1 : end_line ]
#print template_lines
template_string = ''.join(template_lines)

#print template_string

replaced_content = ''

# Read manager password
passwordf = open('/etc/ldap.secret')
pw = passwordf.readlines()[0]

# Connect and bind to ldap
l = ldap.open("localhost", 389)
l.bind('cn=Manager,o=sr', pw)

# Find the list of teams
teamlist = l.search_ext_s("ou=groups,o=sr", ldap.SCOPE_ONELEVEL, "(cn=team-*)", ['cn'], sizelimit=0)

# Convert ldap gunge into a list of TLAs
tlas = []
for team in teamlist:
    dn, attrs = team
    cn = attrs['cn'][0][5:]
    tlas.append(cn)

for tla in tlas:
	replaced = template_string.format(TLA=tla, team_prefix=TEAM_PREFIX)
	replaced_content += replaced

#print replaced_content

new_content = ''.join(content[:start_line + 1])
new_content += replaced_content
new_content += ''.join(content[end_line:])

# Ensure the following open file operation creates a file with mode 600
os.umask(0177)

with open(OUTPUT_FILE, 'w') as f:
	f.write(new_content)
