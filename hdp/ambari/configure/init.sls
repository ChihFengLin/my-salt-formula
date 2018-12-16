{%- from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set repos = ambari_props.repos %}
{%- set server_conf = ambari_props.ambari_server_conf %}

include:
  - hdp.ambari.server

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

{% if not response['status'] == 200 %}
generate_HDP_Version_Definition_file:
  file.managed:
    - name: /tmp/cluster_vdf.xml
    - source: salt://hdp/ambari/configure/files/vdf-HDP-{{ repos.hdp.version }}.xml
    - template: jinja
    - mode: 0640
    - user: root
    - group: root
    - makedirs: True

register_the_VDF_with_Ambari:
  http.query:
    - name: http://{{ grains.host }}:8080/api/v1/version_definitions
    - header_list: ["X-Requested-By: ambari"]
    - username: {{ server_conf.admin_user }}
    - password: {{ server_conf.admin_password }}
    - method: POST
    - data: " {\"VersionDefinition\":{\"version_url\":\"file:/tmp/cluster_vdf.xml\"}}"
    - verify_ssl: False
    - status: 200
    - require:
      - service: ambari_server_svc
{% endif %}

enable_user_home_directory_creation:
  file.append:
    - name: /etc/ambari-server/conf/ambari.properties
    - text:
      - ambari.post.user.creation.hook.enabled=true
      - ambari.post.user.creation.hook=/var/lib/ambari-server/resources/scripts/post-user-creation-hook.sh


{%- set ip_dict = salt['mine.get']('*', 'network.ip_addrs') | dictsort(false, 'value') %}
{% set i = 0 %}
{%- for server_name, addr in ip_dict %}
{% if i != 0 %}
make_sure_Ambari_Agents_{{ server_name }}_has_registered:
  http.query:
    - name: http://{{ grains.host }}:8080/api/v1/hosts/{{ server_name }}
    - header_list: ["X-Requested-By: ambari"]
    - username: {{ server_conf.admin_user }}
    - password: {{ server_conf.admin_password }}
    - method: GET
    - verify_ssl: False
    - status: 200
{% endif %}
{% set i = i + 1 %}
{% endfor %}