# threatstack-formula

A formula for installing Threat Stack agent

## Available states
The following states are available:
* ``threatstack``: Installs the Threatstack agent.

## Configuration
* `deploy_key:`             [required] Your organization's deploy key.
    * ex. "xxxx-xxxx-your-secret-key-xxxx"
* `pkg_url:`                [optional] Path to an alternate repository site.  Set if you manage your own package repository.
    * ex. "https://mirror.example.com"
* `ts_configure:`           [optional] If the agent should be configured during run.  Set to False if installing agent into an AMI.
    * ex. True
* `ts_agent_version:`       [optional] Version of agent to install.  By default if no agent is installed the latest version will be be.  Set a version to maintain consistency in an environment or see `ts_agent_latest`.
    * ex. "1.4.5.0ubuntu14.0"
* `ts_agent_latest:`        [optional] Install the latest agent version.  By default the formula will only ensure that a package is installed.  Set to _True_ to always update to the latest agent version
    * ex. True
* `ts_agent_config_args:`   [optional] Optional arguments to be passe to `cloudsight config`.  Use this to enable optional festures.
    * ex. "--enable_foo=1"

## Testing
There is currently no spec testing as a saltstack rspec module does not exist.

Integration testing requires setting `TS_DEPLOY_KEY` in the environment to a valid key value for tests to succeed.
```
export TS_DEPLOY_KEY='<deploy_key>'
bundle exec kitchen test
```
