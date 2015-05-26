# Overview

This is a puppet face that adds two new sub commands the puppet report application.
This tool is designed to be used from a machine whos certificate is already in the puppetdb whitelist.
Puppet Masters or Masters of Masters (CAs) should work out of the box for example.

# Installation
Puppet faces are automatically loaded when installed in the modulepath. Install in the environment of
your puppet master. Once installed the command should immediately be available. If you wish to not install
this in your module path you can export the `RUBYLIB` environment variable with a fully qualified path to
the lib directory inside this module as well.

# Usage

Help can be found with `puppet help report` and specific help can be found with `puppet help report unresponsive`

## Unresponsive nodes (Has not checked in within the last 60 minutes)

To query puppetdb for reports for nodes that have not checked in for the last 60 minutes.
The output is reverse sorted with the highest delta nodes first
```shell
puppet report unresponsive
```
```shell
agent-1.vm,production,2015-05-26T04:24:54.168Z,0 days,2 hours,10 minutes,47 seconds
aio-master-1.vm,production,2015-05-26T06:25:03.094Z,0 days,1 hours,10 minutes,37 seconds
```

| Field1   | Field2      | Field3           | Field4 | Field5  | Field6    | Field7    |
| -------- | ----------- | ---------------- | ------ |-------- | --------- |---------  |
| certname | environment | report-timestamp | N days | N hours | N minutes | N seconds |

You can tune the query to find nodes with different deltas by passing ``--minutes`

```shell
puppet report unresponsive --minutes 120
agent-1.vm,production,2015-05-26T04:24:54.168Z,0 days,2 hours,12 minutes,22 seconds
```
| Field1   | Field2      | Field3           | Field4 | Field5  | Field6    | Field7    |
| -------- | ----------- | ---------------- | ------ |-------- | --------- |---------  |
| certname | environment | report-timestamp | N days | N hours | N minutes | N seconds |

## Nodes with changed status 
Lists the active nodes with changed status
```
puppet report list --status changed
aio-master-1.vm,production,1432399328,2015-05-23T16:42:35.239Z,50a26624029999e5afe5c6e3dca87b7effcefac2
```
| Field1   | Field2      | Field3         | Field4           | Field 5                |
| -------- | ----------- | -------------- | ---------------- | ---------------------- |
| certname | environment | config_version | report-timestamp | hash ( of the report ) |


## Nodes with failed status

List the nodes with failed status.

```shell
puppet report list --status failed
```
```shell
aio-master-1.vm,production,,2015-05-25T04:02:49.297Z,ab8ae404c024117aaed3be744094993f6a016949
aio-master-1.vm,production,,2015-05-25T04:13:47.592Z,d9678bc2bb1242301aa241753e64d3300e7df722
aio-master-1.vm,production,1432528237,2015-05-25T04:31:06.482Z,be894bb39beb5f9b647021d10e26df779beed212
aio-master-2.vm,production,1432531658,2015-05-25T05:28:13.253Z,2ce5e7c05c41ff2749dee8dcd3b0e276e915e348
aio-master-1.vm,production,1432533456,2015-05-25T05:58:12.557Z,befde4050cc7ee182cfd8d25bbd2536392aed27a
aio-master-1.vm,production,1432535254,2015-05-25T06:28:01.613Z,6a2fbae292214f18ab714c98ef86468dfb4e8ce6
aio-master-1.vm,production,1432537053,2015-05-25T06:58:14.385Z,43e43d0fd653521e610a769730c1c02088fd5f66
aio-master-4.vm,production,1432539107,2015-05-25T07:32:11.156Z,767a99a0fcaf82d1d3e8f3f9e98758fd1a89720e
aio-master-1.vm,production,1432540908,2015-05-25T08:02:19.646Z,59af08de543d9664754fc45d99d504f6c6afa444
aio-master-5.vm,production,1432543932,2015-05-25T08:52:36.957Z,293e6b6098ca393fe4ade28bcd216b47b14556a4
aio-master-1.vm,production,1432545733,2015-05-25T09:22:44.046Z,60ae892008c77ed54db94c86867a47e637666c76
aio-master-1.vm,production,1432547530,2015-05-25T09:52:58.575Z,140ee7ebb0679806c2ea281940b58dcdc80500c8
agent-1.vm,production,1432547737,2015-05-25T09:55:35.565Z,427e8f90b6eb9af418c862251ba57ef509ac1d84
agent-2.vm,production,1432547780,2015-05-25T09:56:21.674Z,a9313bc6cbccc5d9dd60e5247f48380ea3f887cb
```
### Output


| Field1   | Field2      | Field3         | Field4           | Field 5                |
| -------- | ----------- | -------------- | ---------------- | ---------------------- |
| certname | environment | config_version | report-timestamp | hash ( of the report ) |



# Raw output

This face is designed to format all output as csv, if desired the raw puppetdb query can be displayed using the `--render-as`
options in puppet.


## JSON output

### Report List

```shell
puppet report list --render-as json | python -m json.tool
```
```json
[
    {
        "certname": "aio-master-1.vm", 
        "configuration-version": "1432545733", 
        "end-time": "2015-05-25T09:22:44.046Z", 
        "environment": "production", 
        "hash": "60ae892008c77ed54db94c86867a47e637666c76", 
        "puppet-version": "3.8.0 (Puppet Enterprise 3.8.0)", 
        "receive-time": "2015-05-25T09:22:58.332Z", 
        "report-format": 4, 
        "start-time": "2015-05-25T09:22:06.974Z", 
        "status": "failed", 
        "transaction-uuid": "7268ac56-89b8-45a7-b1b8-f0c252ef9ee6"
    }, 
    {
        "certname": "agent-1.vm", 
        "configuration-version": "1432547780", 
        "end-time": "2015-05-25T09:56:21.674Z", 
        "environment": "production", 
        "hash": "a9313bc6cbccc5d9dd60e5247f48380ea3f887cb", 
        "puppet-version": "3.8.0 (Puppet Enterprise 3.8.0)", 
        "receive-time": "2015-05-25T09:56:23.817Z", 
        "report-format": 4, 
        "start-time": "2015-05-25T09:56:18.246Z", 
        "status": "failed", 
        "transaction-uuid": "e07e8f3c-255f-4921-af2a-c58545f6748f"
    }
]
```
This response format is documented at [https://docs.puppetlabs.com/puppetdb/2.3/api/query/v3/reports.html#response-format](https://docs.puppetlabs.com/puppetdb/2.3/api/query/v3/reports.html#response-format)

### Report Unresponsive

```shell
puppet report unresponsive --render-as json | python -m json.tool
```
```json
[
    {
        "catalog-environment": "production", 
        "catalog-timestamp": "2015-05-26T04:24:49.854Z", 
        "certname": "agent-1.vm", 
        "deactivated": null, 
        "facts-environment": "production", 
        "facts-timestamp": "2015-05-26T04:24:37.646Z", 
        "report-environment": "production", 
        "report-timestamp": "2015-05-26T04:24:54.168Z"
    }, 
    {
        "catalog-environment": "production", 
        "catalog-timestamp": "2015-05-26T06:54:50.844Z", 
        "certname": "aio-master-1.vm", 
        "deactivated": null, 
        "facts-environment": "production", 
        "facts-timestamp": "2015-05-26T06:54:34.844Z", 
        "report-environment": "production", 
        "report-timestamp": "2015-05-26T06:55:00.383Z"
    }
]
```

This response format is documented at [https://docs.puppetlabs.com/puppetdb/2.3/api/query/v3/nodes.html#response-format](https://docs.puppetlabs.com/puppetdb/2.3/api/query/v3/nodes.html#response-format)


See `render-as` documentation for more format information [https://docs.puppetlabs.com/references/latest/man/module.html#OPTIONS](https://docs.puppetlabs.com/references/latest/man/module.html#OPTIONS)

# Advanced Usage
This module can manually specify the puppetdb host and port to connect to.
This information is required if not running from a master as puppetdb.conf will not exit and the ruby libraries used to
automatically lookup this information will be missing.
```shell
puppet report unresponsive --host puppetdb.vagrant.vm --port 8081
```

