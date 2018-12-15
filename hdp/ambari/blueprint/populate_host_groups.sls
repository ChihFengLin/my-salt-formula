{%- from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set hosts = ambari_props.hosts %}
{%- set repos = ambari_props.repos %}
{%- set server_conf = ambari_props.ambari_server_conf %}
{%- set blueprint_dynamic = ambari_props.blueprint_dynamic %}

# Add VDF ID from Ambari server into grains
{%- set vdf_check_url = 
  'http://%s:8080/api/v1/version_definitions?VersionDefinition/release/version=%s' 
  % (grains.fqdn, repos.hdp.version) 
%}

{%- set response = salt['http.query'](
  vdf_check_url,
  username=server_conf.admin_user,
  password=server_conf.admin_password,
  method='GET',
  header_list=['X-Requested-By:ambari'],
  verify_ssl=False,
  status=True,
  data_render=True
) %}

{% set response_items = response['body'] | load_json | traverse('items') %}

{% if response_items | length == 0 %}
fail_if_could_not_get_a_VersionDefinition_from_Ambari:
  cmd.run:
    - name: |
        echo could not get version definition id from Ambari
        exit 1
{% endif %}

{% set vdf_id = response_items[0]['VersionDefinition']['id'] %} 

add_vdf_id_to_grain:
  grains.present:
    - name: blueprint:vdf_id
    - value: {{ vdf_id }}
    - force: True

#  Construct host groups from blueprint yaml file and store into grains
{%- set required_instance_num = 0 %}
{%- for group in blueprint_dynamic %}
  
  {%- set required_instance_num = required_instance_num + group['instances'] | int %}
  
  {% if loop.last %}
    add_total_require_instance_number_to_grain:
      grains.present:
        - name: blueprint:required_instance_num
        - value: {{ required_instance_num }}
        - force: True

    {%- set ip_list = salt['mine.get']('*', 'network.ip_addrs').values() %}
    {%- set is_enough_instance = ip_list|length >= required_instance_num %}
    
    {% if is_enough_instance %}
      
      {%- set index = 0 %}
      {%- set host_groups = {} %}
      
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
    {% else %}
      not_enough_machines:
        cmd.run:
          - name: |
              echo this deployment needs at least {{ required_instance_num }} machines
              exit 1
    {% endif %}
  {% endif %}
{% endfor %}