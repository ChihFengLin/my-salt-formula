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

upload_the_blueprint_{{ ambari_props.blueprint_name }}_to_the_Ambari_server:
  http.query:
    - name: http://{{ grains.fqdn }}:8080/api/v1/blueprints/{{ ambari_props.blueprint_name }}
    - header_list: ["X-Requested-By: ambari"]
    - username: {{ server_conf.admin_user }}
    - password: {{ server_conf.admin_password }}
    - method: POST
    - verify_ssl: False
    - status: 200
    - data_file: /tmp/{{ ambari_props.blueprint_file }}
    - require:
      - http: delete_any_existing_blueprint_called_{{ ambari_props.blueprint_name }}

launch_the_create_cluster_request:
  http.query:
    - name: http://{{ grains.fqdn }}:8080/api/v1/clusters/{{ ambari_props.cluster_name }}
    - username: {{ server_conf.admin_user }}
    - password: {{ server_conf.admin_password }}
    - method: POST
    - verify_ssl: False
    - status: 200
    - data_file: /tmp/{{ ambari_props.cluster_template_file }}
    - require:
      - http: upload_the_blueprint_{{ ambari_props.blueprint_name }}_to_the_Ambari_server

# Wait for the cluster to be built
