# threatstack.sls

# Setup Threat Stack yum repo

# Allow for package repo override from pillar
{% if pillar['pkg_url'] is defined %}
    {% set pkg_url = pillar['pkg_url'] %}
{% else %}
    {% set pkg_url = 'https://pkg.threatstack.com' %}
{% endif %}

# Allow for GPG location override from pillar
{% if pillar['pkg_url'] is defined %}
    {% set gpgkey = pillar['gpg_key'] %}
{% elif grains['os_family']=="Debian" %}
    {% set gpgkey = 'https://app.threatstack.com/APT-GPG-KEY-THREATSTACK' %}
{% else %}
    {% set gpgkey = 'https://app.threatstack.com/RPM-GPG-KEY-THREATSTACK' %}
{% endif %}

threatstack-repo:
{% if grains['os_family']=="Debian" %}
  pkg.installed:
    - pkgs:
      - curl
      - apt-transport-https
  {# We do this due to issues with key_url #}
  cmd.run:
    - name: 'curl -q -f {{ gpgkey }} | apt-key add -'
  pkgrepo.managed:
    - humanname: threatstack
    - name: deb {{ pkg_url }}/Ubuntu {{ grains['oscodename'] }} main
    - file: '/etc/apt/sources.list.d/threatstack.list'
{% elif grains['os_family']=="RedHat" %}
  pkgrepo.managed:
    - name: threatstack
    - humanname: Threat Stack Package Repository
    - gpgkey: {{ gpgkey }}
  {% if grains['os']=="AMAZON" %}
    - baseurl: {{ pkg_url }}/Amazon
    - gpgcheck: 1
    - enabled: 1
  {% else %}
    - baseurl: {{ pkg_url }}/CentOS
    - gpgcheck: 1
    - enabled: 1
  {% endif %}
{% endif %}

# Install RPM, lock down RPM version

threatstack-agent:
  pkg.installed:
    - name: threatstack-agent
    - require:
      - pkgrepo: threatstack-repo

# Configure identity file by running script, needs to be done only once

cloudsight-setup:
  cmd.run:
    - cwd: /
    - name: cloudsight setup --deploy-key={{ pillar['deploy_key'] }}
    - unless: test -f /opt/threatstack/cloudsight/config/.secret
    - require:
      - pkg: threatstack-agent
