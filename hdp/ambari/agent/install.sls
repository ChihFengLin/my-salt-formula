{% from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set ambari_agent_conf = ambari_props.ambari_agent_conf %}
{%- set ambari_version = ambari_props.repos.ambari %}

include:
  - hdp.ambari.repo
  {% if ambari_agent_conf.start_service %}
  - hdp.ambari.agent.service
  {% endif %}

{% if salt['grains.get']('os_family') == 'RedHat' %}
ambari_agent_{{ ambari_version.version }}_pkg:
  pkg.installed:
    - name: ambari-agent
{% endif %}

ambari_agent_{{ ambari_version.version }}_config:
  file.managed:
    - name: /etc/ambari-agent/conf/ambari-agent.ini
    - source: salt://hdp/ambari/agent/files/ambari-agent.ini
    - template: jinja
    - mode: 0640
    - user: root
    - group: root
    - makedirs: True
    - require_in:
      - pkg: ambari_agent_{{ ambari_version.version }}_pkg