{% from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set ambari_version = ambari_props.repos.ambari %}

include:
  - hdp.ambari.server.install

ambari_server_svc:
  service.running:
    - name: ambari-server
    - enable: True
    - require:
      - pkg: ambari_server_{{ambari_version.version}}_pkg
    - watch:
      - file: ambari_server_properties