{%- from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set security = ambari_props.security %}
{%- set security_options = ambari_props.security_options %}
{%- set blueprint_dynamic = ambari_props.blueprint_dynamic %}

include:
  - hdp.ambari.blueprint.populate_host_groups
  - hdp.ambari.blueprint.populate_service_groups

generate_blueprint_dynamic_file:
  file.managed:
    - name: /tmp/blueprint_dynamic.json
    - source: salt://hdp/ambari/blueprint/files/{{ ambari_props.blueprint_file }}
    - template: jinja
    - mode: 0640
    - user: root
    - group: root
    - allow_empty: False
    - context:
        security: {{ security }}
        security_options: {{ security_options }}
        database_config: {{ ambari_props.database_configurations }}
        blueprint_dynamic: {{ blueprint_dynamic }}
        ambari_groups: {{ grains.blueprint.service_groups.ambari_groups }}
        namenode_groups: {{ grains.blueprint.service_groups.namenode_groups }}
        namenode_hosts: {{ grains.blueprint.service_groups.namenode_hosts }}
        zkfc_groups: {{ grains.blueprint.service_groups.zkfc_groups }}
        resourcemanager_groups: {{ grains.blueprint.service_groups.resourcemanager_groups }}
        journalnode_groups: {{ grains.blueprint.service_groups.journalnode_groups }}
        zookeeper_groups: {{ grains.blueprint.service_groups.zookeeper_groups }}
        zookeeper_hosts: {{ grains.blueprint.service_groups.zookeeper_hosts }}
        hiveserver_hosts: {{ grains.blueprint.service_groups.hiveserver_hosts }}
        oozie_hosts: {{ grains.blueprint.service_groups.oozie_hosts }}
        atlas_hosts: {{ grains.blueprint.service_groups.atlas_hosts }}
        druid_hosts: {{ grains.blueprint.service_groups.druid_hosts }}
        superset_hosts: {{ grains.blueprint.service_groups.superset_hosts }}
        kafka_groups: {{ grains.blueprint.service_groups.kafka_groups }}
        kafka_hosts: {{ grains.blueprint.service_groups.kafka_hosts }}
        rangeradmin_groups: {{ grains.blueprint.service_groups.rangeradmin_groups }}
        rangeradmin_hosts: {{ grains.blueprint.service_groups.rangeradmin_hosts }}
        rangerkms_hosts: {{ grains.blueprint.service_groups.rangerkms_hosts }}
        streamline_hosts: {{ grains.blueprint.service_groups.streamline_hosts }}
        registry_hosts: {{ grains.blueprint.service_groups.registry_hosts }}
        blueprint_all_services: {{ grains.blueprint.service_groups.blueprint_all_services }}
        blueprint_all_clients: {{ grains.blueprint.service_groups.blueprint_all_clients }}
    - require:
        - grains: add_service_groups_to_grain