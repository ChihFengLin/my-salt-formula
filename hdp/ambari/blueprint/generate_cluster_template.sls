{%- from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set hosts = ambari_props.hosts %}
{%- set repos = ambari_props.repos %}
{%- set server_conf = ambari_props.ambari_server_conf %}
{%- set security = ambari_props.security %}
{%- set security_options = ambari_props.security_options %}
{%- set blueprint_dynamic = ambari_props.blueprint_dynamic %}

include:
  - hdp.ambari.blueprint.populate_host_groups
  - hdp.ambari.blueprint.populate_service_groups

# Generate cluster template and blueprint json files
generate_cluster_template_file:
  file.managed:
    - name: /tmp/cluster_template.json
    - source: salt://hdp/ambari/blueprint/files/{{ ambari_props.cluster_template_file }}
    - template: jinja
    - mode: 0640
    - user: root
    - group: root
    - allow_empty: False
    - context:
        host_groups: {{ grains.blueprint.host_groups}}
        vdf_id: {{ grains.blueprint.vdf_id }}
        security: {{ security }}
        security_options: {{ security_options }}
    - require:
        - grains: add_host_groups_to_grain