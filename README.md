# threatstack-formula

A formula for installing Threat Stack agent

This formula supports installing agent 2.x

>>>
**No longer supports Threat Stack agent 1.x**

For 1.x support, look at the 2.x versions of this formula.
>>>

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
    * ex. "2.0.0.0ubuntu20.0"
    * agent 2.x ex. "--set enable_foo 1"
* `ts_agent_extra_args:`    [optional] Optional arguments to be passed to `tsagent setup`.
    * Please refer to the agent documentation or check the appropriate help output for `tsagent setup`.

## Testing
There is currently no spec testing as a saltstack rspec module does not exist.

Integration testing can be configured two different ways.

#### Pillar data from environment variables

This method requires the following:
* Uncommenting the section for `threatstack.sls` in `.kitchen.yml`
* Commenting out the `pillars_from_files` section in `.kitchen.yml`
* Setting `TS_DEPLOY_KEY`, `TS_CONFIGURE_AGENT`, `TS_PACKAGE_VERSION` in the environment to a valid key value for tests to succeed.
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
