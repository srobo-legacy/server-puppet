#!/bin/sh

cd /home/gerrit
git clone /home/gerrit/srdata/git/All-Projects.git/
cd All-Projects
sed -i 's/^[0-9a-f]\+[\t ]\+Administrators$/fb5dafc8c021470b1afb90de58ae0a5a3e984745	Administrators/' groups
git add groups
git commit -m "Correct administrators guid" 2>/dev/null
git branch sr_guid_patch_branch
git push origin sr_guid_patch_branch
git show-ref refs/heads/sr_guid_patch_branch | awk '{print $1}' > /home/gerrit/srdata/git/All-Projects.git/refs/meta/config
cd /home/gerrit
rm -rf All-Projects
