# threatstack-formula

A formula for installing Threat Stack agent

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

## Available states
The following states are available:
* ``threatstack``: Installs the Threatstack agent.

## Testing
There is currently no spec testing as a saltstack rspec module does not exist.

Integration testing requires setting `TS_DEPLOY_KEY` in the environment to a valid key value for tests to succeed.
```
export TS_DEPLOY_KEY='<deploy_key>'
bundle exec kitchen test
```
