{% from "hdp/ambari/map.jinja" import mysql with context %}
{% from "hdp/ambari/map.jinja" import ambari_props with context %}

remove_mysql57_community_release:
  pkg.removed:
    - pkgs: 
      - {{ mysql.server_pkg }}
      - {{ mysql.client_pkg }}

remove_mysql57_community_release_data:
  file.directory:
    - name: {{ mysql.data_root_dir }}
    - clean: True

remove_mysql57_community_release_logs:
  file.absent:
    - name: {{ mysql.log_file }}

remove_database_first_install_to_grain:
  grains.absent:
    - name: mysql:database:first
    - destructive: True

{% for user, userargs in ambari_props.database_configurations.database_options.iteritems() %}
remove_{{ user }}_database_to_grain:
  grains.absent:
    - name: mysql:database:{{ userargs.db_name }}
    - destructive: True

remove_local_{{ user }}_to_grain:
  grains.absent:
    - name: mysql:user:local:{{ user }}
    - destructive: True

remove_all_{{ user }}_to_grain:
  grains.absent:
    - name: mysql:user:all:{{ user }}
    - destructive: True

{% endfor %}