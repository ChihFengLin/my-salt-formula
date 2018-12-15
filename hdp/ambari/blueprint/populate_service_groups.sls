{%- from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set hosts = ambari_props.hosts %}
{%- set repos = ambari_props.repos %}
{%- set server_conf = ambari_props.ambari_server_conf %}
{%- set blueprint_dynamic = ambari_props.blueprint_dynamic %}

include:
  - hdp.ambari.blueprint.populate_host_groups

{%- set host_groups = grains.blueprint.host_groups %}
{%- set service_groups = {} %}

# Set initial list value for each service group
{%- set ambari_groups = [] %}
{%- set namenode_groups = [] %}
{%- set namenode_hosts = [] %}
{%- set zkfc_groups = [] %}
{%- set resourcemanager_groups = [] %}
{%- set journalnode_groups = [] %}
{%- set zookeeper_groups = [] %}
{%- set zookeeper_hosts = [] %}
{%- set hiveserver_hosts = [] %}
{%- set oozie_hosts = [] %}
{%- set atlas_hosts = [] %}
{%- set druid_hosts = [] %}
{%- set superset_hosts = [] %}
{%- set kafka_groups = [] %}
{%- set kafka_hosts = [] %}
{%- set rangeradmin_groups = [] %}
{%- set rangeradmin_hosts = [] %}
{%- set rangerkms_hosts = [] %}
{%- set streamline_hosts = [] %}
{%- set registry_hosts = [] %}
{%- set blueprint_all_services = [] %}
{%- set blueprint_all_clients = [] %}

# Update service groups based on blueprint yaml file
{% for item in blueprint_dynamic %}

{% if 'AMBARI_SERVER' in item.services %}
{%- do ambari_groups.append(item.host_group) %}
{% endif %}

{% if 'NAMENODE' in item.services %}
{%- do namenode_groups.append(item.host_group) %}
{%- do namenode_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{% if 'ZKFC' in item.services %}
{%- do zkfc_groups.append(item.host_group) %}
{% endif %}

{% if 'RESOURCEMANAGER' in item.services %}
{%- do resourcemanager_groups.append(item.host_group) %}
{% endif %}

{% if 'JOURNALNODE' in item.services %}
{%- do journalnode_groups.append(item.host_group) %}
{% endif %}

{% if 'ZOOKEEPER_SERVER' in item.services %}
{%- do zookeeper_groups.append(item.host_group) %}
{%- do zookeeper_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{% if 'HIVE_SERVER' in item.services %}
{%- do hiveserver_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{% if 'OOZIE_SERVER' in item.services %}
{%- do oozie_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{% if 'ATLAS_SERVER' in item.services %}
{%- do atlas_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{%- if 'DRUID_BROKER' in item.services or 
       'DRUID_COORDINATOR' in item.services or 
       'DRUID_ROUTER' in item.services or 
       'DRUID_MIDDLEMANAGER' in item.services or 
       'DRUID_HISTORICAL' in item.services or 
       'DRUID_OVERLORD' in item.services %}
{%- do druid_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{% if 'SUPERSET' in item.services %}
{%- do superset_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{% if 'KAFKA_BROKER' in item.services %}
{%- do kafka_groups.append(item.host_group) %}
{%- do kafka_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{% if 'RANGER_ADMIN' in item.services or 'RANGER_USERSYNC' in item.services %}
{%- do rangeradmin_groups.append(item.host_group) %}
{%- do rangeradmin_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{% if 'RANGER_KMS_SERVER' in item.services %}
{%- do rangerkms_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{% if 'STREAMLINE_SERVER' in item.services %}
{%- do streamline_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{% if 'REGISTRY_SERVER' in item.services %}
{%- do registry_hosts.extend(host_groups[item.host_group]) %}
{% endif %}

{% set blueprint_all_services = blueprint_all_services | union(item.services) %}
{% set blueprint_all_clients = blueprint_all_clients |  union(item.clients) %}

{% endfor %}

{%- do service_groups.update(
  {
    "ambari_groups" : ambari_groups,
    "namenode_groups": namenode_groups,
    "namenode_hosts": namenode_hosts,
    "zkfc_groups": zkfc_groups,
    "resourcemanager_groups": resourcemanager_groups,
    "journalnode_groups": journalnode_groups,
    "zookeeper_groups": zookeeper_groups,
    "zookeeper_hosts": zookeeper_hosts,
    "hiveserver_hosts": hiveserver_hosts,
    "oozie_hosts": oozie_hosts,
    "atlas_hosts": atlas_hosts,
    "druid_hosts": druid_hosts,
    "superset_hosts": superset_hosts,
    "kafka_groups": kafka_groups,
    "kafka_hosts": kafka_hosts,
    "rangeradmin_groups": rangeradmin_groups,
    "rangeradmin_hosts": rangeradmin_hosts,
    "rangerkms_hosts": rangerkms_hosts,
    "streamline_hosts": streamline_hosts,
    "registry_hosts": registry_hosts,
    "blueprint_all_services": blueprint_all_services,
    "blueprint_all_clients": blueprint_all_clients
  }
) %}

add_service_groups_to_grain:
  grains.present:
    - name: blueprint:service_groups
    - value: {{ service_groups }}
    - force: True