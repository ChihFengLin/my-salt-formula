{%- from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set repos = ambari_props.repos %}
{%- set server_conf = ambari_props.ambari_server_conf %}
{%- set security = ambari_props.security %}
{%- set security_options = ambari_props.security_options %}
{%- set blueprint_dynamic = ambari_props.blueprint_dynamic %}


##################################################
## Get version definition id from Ambari server ##
##################################################

{%- set vdf_check_url = 
  'http://%s:8080/api/v1/version_definitions?VersionDefinition/release/version=%s' 
  % (grains.host, repos.hdp.version) 
%}

{%- set response = salt['http.query'](
  vdf_check_url,
  username=server_conf.admin_user,
  password=server_conf.admin_password,
  method='GET',
  header_list=['X-Requested-By:ambari'],
  verify_ssl=False,
  status=True,
  decode=True
) %}

{% set response_items = response['body'] | load_json | traverse('items') %}
{% if response_items | length == 0 %}
not_enough_machines:
  cmd.run:
    - name: |
        echo can not get vdf id from Ambari server
        exit 1
{% endif %}

{% set vdf_id = response_items[0]['VersionDefinition']['id'] %} 

add_vdf_id_to_grain:
  grains.present:
    - name: blueprint:vdf_id
    - value: {{ vdf_id }}
    - force: True


##########################################################################
## Construct host groups from blueprint yaml file and store into grains ##
##########################################################################
{%- set host_groups = {} %}
{%- set required_instance_num = 0 %}
{%- for group in blueprint_dynamic %} 
  {%- set required_instance_num = required_instance_num + group['instances'] | int %}
  
  {% if loop.last %}

add_total_require_instance_number_to_grain:
  grains.present:
    - name: blueprint:required_instance_num
    - value: {{ required_instance_num }}
    - force: True

    {%- set ip_list = salt['mine.get']('*', 'network.ip_addrs').values() | sort %}
    {%- set is_enough_instance = ip_list|length >= required_instance_num %}

    {% if is_enough_instance %}
      
      {%- set index = 0 %}
      {%- for group in blueprint_dynamic %}
        {%- set current_group_hosts = [] %}
        {%- set instance_num = group['instances'] | int %}
        {%- set group_name = group['host_group'].encode('utf-8') %}
  
        {% for i in range(index, index + instance_num) %}
          {% do current_group_hosts.append(ip_list[i][0]) %}
        {% endfor %}

        {% do host_groups.update({group_name:current_group_hosts}) %}
        {% set index = index + instance_num %}      
      {% endfor  %}

add_host_groups_to_grain:
  grains.present:
    - name: blueprint:host_groups
    - value: {{ host_groups }}
    - force: True

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
        host_groups: {{ host_groups }}
        vdf_id: {{ vdf_id }}
        security: {{ security }}
        security_options: {{ security_options }}
    - require:
        - grains: add_host_groups_to_grain

    {% else %}

not_enough_machines:
  cmd.run:
    - name: |
        echo this deployment needs at least {{ required_instance_num }} machines
        exit 1

    {% endif %}
  {% endif %}
{% endfor %}


#############################################################################
## Construct service groups from blueprint yaml file and store into grains ##
#############################################################################
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

  {% do blueprint_all_services.extend(item.services) %}
  {% do blueprint_all_clients.extend(item.clients) %}

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
    "blueprint_all_services": blueprint_all_services | unique,
    "blueprint_all_clients": blueprint_all_clients | unique
  }
) %}

add_service_groups_to_grain:
  grains.present:
    - name: blueprint:service_groups
    - value: {{ service_groups }}
    - force: True

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
        ambari_groups: {{ ambari_groups }}
        namenode_groups: {{ namenode_groups }}
        namenode_hosts: {{ namenode_hosts }}
        zkfc_groups: {{ zkfc_groups }}
        resourcemanager_groups: {{ resourcemanager_groups }}
        journalnode_groups: {{ journalnode_groups }}
        zookeeper_groups: {{ zookeeper_groups }}
        zookeeper_hosts: {{ zookeeper_hosts }}
        hiveserver_hosts: {{ hiveserver_hosts }}
        oozie_hosts: {{ oozie_hosts }}
        atlas_hosts: {{ atlas_hosts }}
        druid_hosts: {{ druid_hosts }}
        superset_hosts: {{ superset_hosts }}
        kafka_groups: {{ kafka_groups }}
        kafka_hosts: {{ kafka_hosts }}
        rangeradmin_groups: {{ rangeradmin_groups }}
        rangeradmin_hosts: {{ rangeradmin_hosts }}
        rangerkms_hosts: {{ rangerkms_hosts }}
        streamline_hosts: {{ streamline_hosts }}
        registry_hosts: {{ registry_hosts }}
        blueprint_all_services: {{ blueprint_all_services }}
        blueprint_all_clients: {{ blueprint_all_clients }}
    - require:
        - grains: add_service_groups_to_grain