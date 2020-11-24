# threatstack-formula

A formula for installing Threat Stack agent

This formula supports installing agent 1.x and agent 2.x

## Available states
The following states are available:
* ``threatstack``: Installs the Threatstack agent.

## Configuration
* `pkg_url:`                [optional] Path to an alternate repository site.  Set if you manage your own package repository.
    * ex. "https://mirror.example.com"
* `deploy_key:`             [required] Your organization's deploy key.
    * ex. "xxxx-xxxx-your-secret-key-xxxx"
* `ts_configure_agent:`     [optional] If the agent should be configured during run.  Set to False if installing agent into an AMI.
    * ex. True
* `ts_agent_version:`       [optional] Version of agent to install.  By default if this setting is omitted, the latest version will be installed.  Set a version to maintain consistency in an environment.
    * ex. "1.4.5.0ubuntu14.0"
* `ts_agent_config_args:`   [optional] Optional arguments to be passed to `cloudsight config` or `tsagent config` (depends on version of agent).  Use this to enable optional features.
    * agent 1.x ex. "--enable_foo=1"
    * agent 2.x ex. "--set enable_foo 1"
* `ts_agent_extra_args:`    [optional] Optional arguments to be passed to `cloudsight setup` or `tsagent setup` (depends on version of agent).
    * Please refer to the agent documentation or check the appropriate help output for `cloudsight setup`/`tsagent setup`.
* `ts_agent_1x_platforms:`  [required] This list defines the linux distributions (and versions) that should use the 1.x agent. This should only be changed if you have reviewed this salt formula, and understand the ramifications.

## Testing
There is currently no spec testing as a saltstack rspec module does not exist.

Integration testing can be configured two different ways.

#### Pillar data from environment variables

This method requires the following:
* Uncommenting the section for `threatstack.sls` in `.kitchen.yml`
* Commenting out the `pillars_from_files` section in `.kitchen.yml`
* Setting `TS_DEPLOY_KEY` in the environment to a valid key value for tests to succeed.
```
export TS_DEPLOY_KEY='<deploy_key>'
bundle exec kitchen test
```

For setting additional configuration changes in the environment, see `.kitchen.yml` for all available pillar items

#### Pillar data from `pillars_from_files`

This method requires the following:
* Uncommenting the `pillars_from_files` section in `.kitchen.yml`
* Commenting out the section for `threatstack.sls` in `.kitchen.yml`
This method requires updating `deploy_key` pillar item in `pillar.example` to a valid key value for tests to succeed.
```
<Edit `pillar.example`>
bundle exec kitchen test
```

## Contributing enhancements/fixes

See the [CONTRIBUTING document](CONTRIBUTING.md) for details.
