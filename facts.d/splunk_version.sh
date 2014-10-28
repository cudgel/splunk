#!/bin/bash

version=`ls -1 ~splunk/splunk*manifest | sort -n | tail -1 | awk -F- '{print $2"-"$3}'`
echo "splunk_version: $version"