# threatstack.sls

# Allow for package repo override from pillar
{% if pillar['pkg_url'] is defined %}
    {% set pkg_url = pillar['pkg_url'] %}
{% else %}
    {% set pkg_url_base = 'https://pkg.threatstack.com' %}
    {% if grains['os_family']=="Debian" %}
      {% set pkg_url = [pkg_url_base, 'Ubuntu']|join('/') %}
    {% elif grains['os']=="AMAZON" %}
      {% set pkg_url = [pkg_url_base, 'Amazon']|join('/') %}
    {% else %}
      {% set pkg_url = [pkg_url_base, 'CentOS']|join('/') %}
    {% endif %}
{% endif %}

# Allow for GPG location override from pillar
{% if pillar['pkg_url'] is defined %}
    {% set gpgkey = pillar['gpg_key'] %}
{% elif grains['os_family']=="Debian" %}
    {% set gpgkey = 'https://app.threatstack.com/APT-GPG-KEY-THREATSTACK' %}
{% else %}
    {% set gpgkey = 'https://app.threatstack.com/RPM-GPG-KEY-THREATSTACK' %}
{% endif %}

{% set key_id = '6EE04BD4' %}

threatstack-repo:
{% if grains['os_family']=="Debian" %}
  pkg.installed:
    - pkgs:
      - curl
      - apt-transport-https
  {# We do this due to issues with key_url #}
  cmd.run:
    - name: 'curl -q -f {{ gpgkey }} | apt-key add -'
    - unless:
      - apt-key list| grep {{ key_id }}
  pkgrepo.managed:
    - name: deb {{ pkg_url }} {{ grains['oscodename'] }} main
    {#
      Can't use this because of the cert setup on that endpoint. Openssl
      needs to provide servername.
    #}
    {# - key_url: {{ gpgkey }} #}
    - file: '/etc/apt/sources.list.d/threatstack.list'
{% elif grains['os_family']=="RedHat" %}
  pkgrepo.managed:
    - name: threatstack
    - humanname: Threat Stack Package Repository
    - gpgkey: {{ gpgkey }}
    - gpgcheck: 1
    - enabled: 1
    - baseurl: {{ pkg_url }}
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
