# threatstack.sls

# Setup Threat Stack yum repo

threatstack_public:
{% if grains['os']=="Ubuntu" %}
  pkg.installed:
    - pkgs:
      - apt-transport-https
  cmd.run:
    - name: 'curl -q -f https://app.threatstack.com/APT-GPG-KEY-THREATSTACK | apt-key add -'
  pkgrepo.managed:
    - humanname: threatstack_public
    - name: deb {{ threatstack.pkg_url }} Ubuntu {{ grains['oscodename'] }} main" any main
    - file: '/etc/apt/sources.list.d/threatstack_public.list'
{% elif grains['os']=="CentOS" %}
    - humanname: threatstack_public
    - baseurl: {{ threatstack.pkg_url }}CentOS
    - gpgcheck: 1
    - enabled: 1
    - gpgkey: https://app.threatstack.com/YUM-GPG-KEY-THREATSTACK
{% elif grains['os']=="AMAZON" %}
    - humanname: threatstack_public
    - baseurl: {{ threatstack.pkg_url }}Amazon
    - gpgcheck: 1
    - enabled: 1
    - gpgkey: https://app.threatstack.com/YUM-GPG-KEY-THREATSTACK
{% endif %}

# Install RPM, lock down RPM version

install-threatstack-agent:
  pkg.installed:
    - name: {{ threatstack.name }}

# Configure identity file by running script, needs to be done only once

cloudsight-setup:
  cmd.run:
    - cwd: /
    - name: cloudsight setup --deploy_key={{threatstack.deploy_key}}
    - unless: test -f /opt/threatstack/cloudsight/config/.secret
