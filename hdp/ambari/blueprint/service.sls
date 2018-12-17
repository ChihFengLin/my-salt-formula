{%- from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set hosts = ambari_props.hosts %}
{%- set repos = ambari_props.repos %}
{%- set server_conf = ambari_props.ambari_server_conf %}
{%- set blueprint_dynamic = ambari_props.blueprint_dynamic %}

include:
  - hdp.ambari.blueprint.populate_blueprint

check_if_a_cluster_{{ ambari_props.cluster_name }}_already_exists:
  http.query:
    - name: http://{{ grains.fqdn }}:8080/api/v1/clusters/{{ ambari_props.cluster_name }}
    - header_list: ["X-Requested-By: ambari"]
    - username: {{ server_conf.admin_user }}
    - password: {{ server_conf.admin_password }}
    - method: GET
    - verify_ssl: False
    - status: 404

{% if salt['grains.get']('blueprint:uploaded', false) %}
delete_any_existing_blueprint_called_{{ ambari_props.blueprint_name }}:
  http.query:
    - name: http://{{ grains.fqdn }}:8080/api/v1/blueprints/{{ ambari_props.blueprint_name }}
    - header_list: ["X-Requested-By: ambari"]
    - username: {{ server_conf.admin_user }}
    - password: {{ server_conf.admin_password }}
    - method: DELETE
    - verify_ssl: False
    - status: 200
    - require:
      - http: check_if_a_cluster_{{ ambari_props.cluster_name }}_already_exists
{% endif %}

upload_the_blueprint_{{ ambari_props.blueprint_name }}_to_the_Ambari_server:
  cmd.run:
    - name: >-
        curl --user {{ server_conf.admin_user }}:{{ server_conf.admin_password }} -H 'X-Requested-By:ambari' 
        -X POST http://{{ grains.fqdn }}:8080/api/v1/blueprints/{{ ambari_props.blueprint_name }} 
        -d @/tmp/{{ ambari_props.blueprint_file | replace('jinja', 'json') }}

add_uploaded_blueprint_flag_to_grain:
  grains.present:
    - name: blueprint:uploaded
    - value: True
    - force: True

launch_the_create_cluster_request:
  cmd.run:
    - name: >-
        curl --user {{ server_conf.admin_user }}:{{ server_conf.admin_password }} -H 'X-Requested-By:ambari' 
        -X POST http://{{ grains.fqdn }}:8080/api/v1/clusters/{{ ambari_props.cluster_name }} 
        -d @/tmp/{{ ambari_props.cluster_template_file | replace('jinja', 'json') }}
    - require:
      - cmd: upload_the_blueprint_{{ ambari_props.blueprint_name }}_to_the_Ambari_server


# Wait for the cluster to be built
