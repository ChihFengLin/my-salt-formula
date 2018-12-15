{% from "repo_server/map.jinja" import repo_server with context %}
{% from "repo_server/map.jinja" import repos with context %}
{% from "repo_server/map.jinja" import hdp_utils with context %}

include:
  - apache

{%- set repo_map = {
  'ambari': {
    'httpd_dir': '%s/ambari' % (repo_server.httpd_root),
    'remote_repo_url': repo_server.ambari_url,
    'server_dir': 'ambari',
  },
  'hdp': {
    'httpd_dir': '%s/hdp/HDP' % (repo_server.httpd_root),
    'remote_repo_url': repo_server.hdp_url,
    'server_dir': 'hdp/HDP',
  },
  'hdp_utils': {
    'httpd_dir': '%s/hdp/HDP-UTILS-%s' % (repo_server.httpd_root, hdp_utils.version),
    'remote_repo_url': repo_server.hdp_utils_url,
    'server_dir': 'hdp/HDP-UTILS-%s' % (hdp_utils.version),
  },
} %}

{% if repos is defined %}
{%- for repo_name in repos %}

download_and_extract_{{ repo_name }}_tar_file:
  cmd.run:
    - name: |
        mkdir -p {{ repo_map[repo_name]['httpd_dir'] }}
        wget -O {{ repo_server.httpd_root }}/{{ repo_name }}.tar.gz "{{ repo_map[repo_name]['remote_repo_url'] }}"
        tar -xvzf {{ repo_server.httpd_root }}/{{ repo_name }}.tar.gz -C {{ repo_map[repo_name]['httpd_dir'] }} --strip-components=1
    - creates: {{ repo_map[repo_name]['httpd_dir'] }}
    - hide_output: True

remove_{{ repo_name }}_tar_file:
  file.absent:
    - name: {{ repo_server.httpd_root }}/{{ repo_name }}.tar.gz

validate_{{ repo_name }}_repo_on_the_server:
  http.query:
    - name: 'http://localhost/{{ repo_map[repo_name]['server_dir'] }}'
    - status: 200  

{% endfor %}
{% endif %}
