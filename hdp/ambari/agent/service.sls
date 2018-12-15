{% from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set ambari_version = ambari_props.repos.ambari %}

include:
  - hdp.ambari.agent.install

ambari_agent_svc:
  service.running:
    - name: ambari-agent
    - enable: True
    - require:
      - pkg: ambari_agent_{{ ambari_version.version }}_pkg
    - watch:
      - file: ambari_agent_{{ ambari_version.version }}_config