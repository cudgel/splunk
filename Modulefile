name    'cudgel/splunk'
version '2.1.6'
source 'https://github.com/cudgel/splunk'
author 'cudgel'
license 'Apache License, Version 2.0'
summary 'Module to install/manage Splunk deployments'
description 'UNKNOWN'
project_page 'https://github.com/cudgel/splunk'

## Add dependencies, if any:
dependency 'puppetlabs/stdlib', '>= 4.0.0'

# Generate the changelog file
system("git-log-to-changelog > CHANGELOG")
$? == 0 or fail "changelog generation #{$?}!"

