# threatstack.sls

# Setup Threat Stack yum repo

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
    {% set gpgkey_file = '/etc/pki/rpm-gpg/RPM-GPG-KEY-THREATSTACK' %}
    {% set gpgkey_file_uri = 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-THREATSTACK' %}
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
    - unless: 'apt-key list | grep "Threat Stack"'
  pkgrepo.managed:
    - name: deb {{ pkg_url }} {{ grains['oscodename'] }} main
    - file: '/etc/apt/sources.list.d/threatstack.list'
{% elif grains['os_family']=="RedHat" %}
  cmd.run:
    - name: 'wget {{ gpgkey }} -O {{ gpgkey_file }}'
    - creates: {{ gpgkey_file }}
  pkgrepo.managed:
    - name: threatstack
    - humanname: Threat Stack Package Repository
    - gpgkey: {{ gpgkey_file_uri }}
    - gpgcheck: 1
    - enabled: 1
    - baseurl: {{ pkg_url }}
{% endif %}

# Install RPM, lock down RPM version

threatstack-agent:
  {% if pillar['ts_agent_latest'] is defined and pillar['ts_agent_latest'] == true %}
  pkg.latest:
    - name: threatstack-agent
    - require:
      - pkgrepo: threatstack-repo
  {% else %}
  pkg.installed:
    - name: threatstack-agent
    {% if pillar['ts_agent_version'] is defined %}
    - version: {{ pillar['ts_agent_version'] }}
    {% endif %}
    - require:
      - pkgrepo: threatstack-repo
  {% endif %}

# Configure identity file by running script, needs to be done only once
{% if pillar['ts_configure_agent'] is not defined or pillar['ts_configure_agent'] == true %}
cloudsight-setup:
  cmd.run:
    - cwd: /
    - name: cloudsight setup --deploy-key={{ pillar['deploy_key'] }}
    - unless: test -f /opt/threatstack/cloudsight/config/.audit
    - require:
      - pkg: threatstack-agent
{% endif %}