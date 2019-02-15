# threatstack.sls

# Determine if we are installing agent 1.x or agent 2.x
{% if (pillar['ts_agent_latest'] is defined and pillar['ts_agent_latest'] == True) or (pillar['ts_agent_version'] is defined and pillar['ts_agent_version'].startswith('2.')) %}
  {% set install_agent2 = True %}
{% else %}
  {% set install_agent2 = False %}
{% endif %}

# Allow for package repo override from pillar
{% if pillar['pkg_url'] is defined %}
    {% set pkg_url = pillar['pkg_url'] %}
{% else %}
    {% if install_agent2 == True %}
      {% set pkg_url_base = 'https://pkg.threatstack.com/v2' %}
    {% else %}
      {% set pkg_url_base = 'https://pkg.threatstack.com' %}
    {% endif %}
    {% set pkg_maj_ver = grains['osmajorrelease'] %}
    {% if grains['os_family']=="Debian" %}
      {% set pkg_url = [pkg_url_base, 'Ubuntu']|join('/') %}
    {% elif grains['os']=="Amazon" %}
      {% set pkg_url = [pkg_url_base, 'Amazon']|join('/') %}
    {% elif grains['os']=="Centos" %}
      {% set pkg_url = [pkg_url_base, 'EL', pkg_maj_ver]|join('/') %}
    {% else %}
      {% set pkg_url = [pkg_url_base, 'EL', '7']|join('/') %}
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

{% if pillar['ts_agent_extra_args'] is defined %}
  {% set agent_extra_args = pillar['ts_agent_extra_args'] %}
{% else %}
  {% set agent_extra_args = '' %}
{% endif %}

# NOTE: We do not signal the cloudsight service to restart because the package
# takes care of this.  The workflow differs between fresh installation
# installation and upgrades.
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

# Shutdown and disable auditd
# Sometimes the agent install scripts can't do it on Amazon Linux
{% if grains['os']=="Amazon" %}
disable-auditd-amazonlinux:
  name: auditd
  service.dead:
    - enable: False
{% endif %}

# Install RPM, lock down RPM version

threatstack-agent:
  {% if pillar['ts_agent_latest'] is defined and pillar['ts_agent_latest'] == True %}
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
# Agent 2.x uses `tsagent` to setup and configure the agent process
# Agent 1.x uses `cloudsight` to setup and configure the agent process
{% if pillar['ts_configure_agent'] is not defined or pillar['ts_configure_agent'] == True %}
  {% if install_agent2 == True %}
tsagent-setup:
  cmd.run:
    - cwd: /
    - name: tsagent setup --deploy-key={{ pillar['deploy_key'] }} {{ agent_extra_args }}
    - unless: test -f /opt/threatstack/etc/tsagentd.cfg
    - require:
      - pkg: threatstack-agent

    {% if pillar['ts_agent_config_args'] is defined %}
/opt/threatstack/etc/.config_args:
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - contents:
      - {{ pillar['ts_agent_config_args'] }}

tsagent-config:
  cmd.wait:
    - cwd: /
    - name: tsagent config {{ pillar['ts_agent_config_args'] }}
    - watch:
      - file: /opt/threatstack/etc/.config_args
    {% endif %}

  {% else %}
cloudsight-setup:
  cmd.run:
    - cwd: /
    - name: cloudsight setup --deploy-key={{ pillar['deploy_key'] }} {{ agent_extra_args }}
    - unless: test -f /opt/threatstack/cloudsight/config/.audit
    - require:
      - pkg: threatstack-agent

    {% if pillar['ts_agent_config_args'] is defined %}
/opt/threatstack/cloudsight/config/.config_args:
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - contents:
      - {{ pillar['ts_agent_config_args'] }}

cloudsight-config:
  cmd.wait:
    - cwd: /
    - name: cloudsight config {{ pillar['ts_agent_config_args'] }}
    - watch:
      - file: /opt/threatstack/cloudsight/config/.config_args
    {% endif %}

  {% endif %}
{% endif %}

# NOTE: We do not signal the cloudsight service to restart via the package
# resource because the workflow differs between fresh installation and
# upgrades.  The package scripts will handle this.
# Agent 1.x is defined as the `cloudsight` service
# Agent 2.x is defined as the `threatstack` service
{% if install_agent2 == True %}
threatstack:
  service.running:
    - enable: True
    - restart: True
  {% if pillar['ts_agent_config_args'] is defined %}
    - watch:
      - cmd: tsagent-config
  {% endif %}
{% else %}
cloudsight:
  service.running:
    - enable: True
    - restart: True
  {% if pillar['ts_agent_config_args'] is defined %}
    - watch:
      - cmd: cloudsight-config
  {% endif %}
{% endif %}
