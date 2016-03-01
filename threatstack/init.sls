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
    {% set gpgkey = 'https://app.threatstack.com/YUM-GPG-KEY-THREATSTACK' %}
{% endif %}

threatstack_public:
{% if grains['os_family']=="Debian" %}
  pkg.installed:
    - pkgs:
      - apt-transport-https
  cmd.run:
    - name: 'curl -q -f {{ gpgkey }} | apt-key add -'
  pkgrepo.managed:
    - humanname: threatstack_public
    - name: deb {{ pkg_url }} Ubuntu {{ grains['oscodename'] }} main" any main
    - file: '/etc/apt/sources.list.d/threatstack_public.list'
{% elif grains['os_family']=="RedHat" %}
  pkgrepo.managed:
  {% if grains['os']=="AMAZON" %}
    - humanname: threatstack_public
    - baseurl: {{ pkg_url }}/Amazon
    - gpgcheck: 1
    - enabled: 1
    - gpgkey: {{ gpgkey }}
  {% else %}
    - humanname: threatstack_public
    - baseurl: {{ pkg_url }}/CentOS
    - gpgcheck: 1
    - enabled: 1
    - gpgkey: {{ gpgkey }}
  {% endif %}
{% endif %}

# Install RPM, lock down RPM version

install-threatstack-agent:
  pkg.installed:
    - name: threatstack-agent

# Configure identity file by running script, needs to be done only once

cloudsight-setup:
  cmd.run:
    - cwd: /
    - name: cloudsight setup --deploy-key={{ pillar['deploy_key'] }}
    - unless: test -f /opt/threatstack/cloudsight/config/.secret
