{%- from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set hosts = ambari_props.hosts %}
{%- set repos = ambari_props.repos %}


{%- set centos_v = 'centos7' %}

{%- set ambari_repo_url = 
  'http://%s/ambari/%s/%s-%s' % (
    hosts.repo_server.ipv4, centos_v, 
    repos.ambari.version, repos.ambari.build_number
) %}

{%- set hdp_repo_url = 
  'http://%s/hdp/HDP/%s/%s-%s' % (
    hosts.repo_server.ipv4, centos_v, 
    repos.hdp.version, repos.hdp.build_number
) %}

{%- set hdp_utils_repo_url = 
  'http://%s/hdp/HDP-UTILS-%s/%s/%s' % (
    hosts.repo_server.ipv4, repos.hdp_utils.version, 
    centos_v, repos.hdp_utils.version
) %}

{%- set repo_url_map = {
  'ambari': ambari_repo_url,
  'hdp': hdp_repo_url,
  'hdp_utils': hdp_utils_repo_url
} %}

{% for repo_name in ['ambari', 'hdp', 'hdp_utils'] %}

check_{{ repo_name }}_repo:
  http.query:
    - name: {{ repo_url_map[repo_name] }}
    - status: 200

{{ repo_name|replace("_", "-") }}-repo-{{ repos[repo_name].version }}:
  pkgrepo.managed:
    - name: {{ repo_name|replace("_", "-") }}-{{ repos[repo_name].version }}
    - humanname: {{ repo_name|replace("_", "-") }}-{{ repos[repo_name].version }}
    - baseurl: {{ repo_url_map[repo_name] }}
    - gpgcheck: 0
    - enabled: 1
    - priority: 1
    - require:
      - http: check_{{ repo_name }}_repo

{% endfor %}