# threatstack.sls
{% set os_maj_ver = { 'ver': grains['osmajorrelease'] }  %}
{% set os_family = grains['os_family'] %}
{% set os_name = grains['os'] %}
{% set agent2_pkg_url_base = 'https://pkg.threatstack.com/v2' %}
{% set pkg_location = { 'pkg_url': '' } %}

# For Debian-based distributions
{% if grains['os_family']=='Debian' %}
  {% set _ =  os_maj_ver.update({ 'ver': grains['oscodename']}) %}
{% endif %}

# If the package URL is explicitly set, use the override and move on
{% if pillar['pkg_url'] is defined %}
  {% set _ = pkg_location.update({ 'pkg_url': pillar['pkg_url']}) %}
{% endif %}

# Check if OS is not supported in 2.X, and assign the repository URL appropriately
{% if pillar['pkg_url'] is not defined %}
  {% set _ = pkg_location.update({ 'pkg_url': agent2_pkg_url_base}) %}

  # Set the rest of the URL path
  #
  # CentOS and EL are fundamentally the same package, so pull from the same place
  {% if os_family=="Debian" %}
    {% set _ = pkg_location.update({ 'pkg_url': ([pkg_location.pkg_url, 'Ubuntu']|join('/')) }) %}
  {% elif os_name=="Amazon" %}
    # First version of Amazon Linux 1 was '2011.09'
    {% if os_maj_ver.ver > 2010 %}
      {% set _ = pkg_location.update({ 'pkg_url': ([pkg_location.pkg_url, 'Amazon', '1']|join('/')) }) %}
    {% else %}
      {% set _ = pkg_location.update({ 'pkg_url': ([pkg_location.pkg_url, 'Amazon', os_maj_ver.ver]|join('/')) }) %}
    {% endif %}
  {% elif os_family=="RedHat" %}
    {% set _ = pkg_location.update({ 'pkg_url': ([pkg_location.pkg_url, 'EL', os_maj_ver.ver]|join('/')) }) %}
  {% endif %}
{% endif %}

# Allow for GPG location override from pillar
{% if pillar['gpg_key'] is defined %}
  {% set gpgkey = pillar['gpg_key'] %}
  {% if os_family=="RedHat" %}
    {% set gpgkey_file = pillar['gpg_key_file'] %}
    {% set gpgkey_file_uri = pillar['gpg_key_file_uri'] %}
  {% endif %}
{% elif os_family=="Debian" %}
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
{% if os_family=="Debian" %}
  pkg.installed:
    - pkgs:
      - curl
      - apt-transport-https
  {# We do this due to issues with key_url #}
  cmd.run:
    - name: 'curl -q -f {{ gpgkey }} | apt-key add -'
    - unless: 'apt-key list | grep "Threat Stack"'
  pkgrepo.managed:
    - name: deb {{ pkg_location.pkg_url }} {{ os_maj_ver.ver }} main
    - file: '/etc/apt/sources.list.d/threatstack.list'
{% elif os_family=="RedHat" %}
  cmd.run:
    - name: 'curl {{ gpgkey }} -o {{ gpgkey_file }}'
    - creates: {{ gpgkey_file }}
  pkgrepo.managed:
    - name: threatstack
    - humanname: Threat Stack Package Repository
    - gpgkey: {{ gpgkey_file_uri }}
    - gpgcheck: 1
    - enabled: 1
    - baseurl: {{ pkg_location.pkg_url }}
{% endif %}

# Shutdown and disable auditd
# Sometimes the agent install scripts can't do it on RedHat distros
{% if os_family=="RedHat" %}
'/sbin/service auditd stop && chkconfig auditd off':
  cmd.run
{% endif %}

# If no version defined, install latest from defined repository
threatstack-agent:
  {% if pillar['ts_agent_version'] is not defined %}
  pkg.latest:
    - name: threatstack-agent
    - require:
      - pkgrepo: threatstack-repo
  {% else %}
  pkg.installed:
    - name: threatstack-agent
    - version: {{ pillar['ts_agent_version'] }}
    - require:
      - pkgrepo: threatstack-repo
  {% endif %}

# Configure identity file by running script, needs to be done only once
{% if pillar['ts_configure_agent'] is not defined or pillar['ts_configure_agent'] == True %}
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
    - mode: '0644'
    - contents:
      - {{ pillar['ts_agent_config_args'] }}

tsagent-config:
  cmd.wait:
    - cwd: /
    - name: tsagent config {{ pillar['ts_agent_config_args'] }}
    - watch:
      - file: /opt/threatstack/etc/.config_args
  {% endif %}
{% endif %}

# NOTE: We do not signal the cloudsight service to restart via the package
# resource because the workflow differs between fresh installation and
# upgrades.  The package scripts will handle this.
#
# We only enable the service if `ts_configure_agent` is True, because if
# the agent isn't configured, starting up the agent will fail
{% if pillar['ts_configure_agent'] is not defined or pillar['ts_configure_agent'] == True %}
threatstack:
  service.running:
    - enable: True
    - restart: True
  {% if pillar['ts_agent_config_args'] is defined %}
    - watch:
      - cmd: tsagent-config
  {% endif %}
{% else %}
threatstack:
  service.enabled
{% endif %}
