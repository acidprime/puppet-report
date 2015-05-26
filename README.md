# Overview

This is a puppet face that adds two new sub commands the puppet report application.
This tool is designed to be used from a machine that is already in the puppetdb whitelist.
Puppet Masters or Masters of Masters (CAs) should work out of the box.

# Installation
Puppet faces are automatically loaded when installed in the modulepath. Install in the environment of
your puppet master. Once installed the command should immediately be available. If you wish to not install
this in your module path you can export the `RUBYLIB` environment variable with a fully qualified path to
the lib directory inside this module as well.

# Usage

## Unresponsive nodes (Has not checked in within the last 60 minutes)

To query puppetdb for reports for nodes that have not checked in for the last 60 minutes.

```shell
/opt/puppet/bin/puppet report unresponsive
```
```shell
agent-1.vm,production,2015-05-26T04:24:54.168Z,0 days,2 hours,10 minutes,47 seconds
aio-master-1.vm,production,2015-05-26T06:25:04.094Z,0 days,0 hours,10 minutes,37 seconds
```
You can tune the query to find nodes with different deltas by passing ``--minutes`

```shell
/opt/puppet/bin/puppet report unresponsive --minutes 120
agent-1.vm,production,2015-05-26T04:24:54.168Z,0 days,2 hours,12 minutes,22 seconds
``` 
