require 'puppet-lint/tasks/puppet-lint'

PuppetLint.configuration.send('disable_arrow_alignment')
PuppetLint.configuration.send('disable_class_parameter_defaults')
PuppetLint.configuration.send('disable_2sp_soft_tabs')
PuppetLint.configuration.send('disable_80chars')

# Ignore submodules we don't own
PuppetLint.configuration.ignore_paths = [
    'modules/firewall/**/*.pp',
    'modules/vcsrepo/**/*.pp',
    'modules/mysql/**/*.pp',
    'modules/stdlib/**/*.pp',
    'modules/subversion/**/*.pp',
# Submodules we've forked, but aren't likely to fix lint issues in
    'modules/ldap/**/*.pp',
]
