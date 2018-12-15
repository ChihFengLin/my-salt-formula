{% from "hdp/ambari/map.jinja" import mysql with context %}
{% from "hdp/ambari/map.jinja" import ambari_props with context %}

include:
  - hdp.ambari.mysql.database

{%- if ambari_props.database_configurations.database_options is defined %}
{% for user, userargs in ambari_props.database_configurations.database_options.iteritems() %}

{% if not salt['grains.get']('mysql:user:local:%s' % user, False) %}
create_{{ user }}_database_user_with_localhost:
  mysql_query.run:
    - database: {{ userargs.db_name }}
    - query: "CREATE USER '{{ user }}'@'localhost' IDENTIFIED BY '{{ userargs.db_password }}';"
    - connection_host: localhost
    - connection_user: {{ mysql.root_user }}
    - connection_pass: {{ mysql.root_password }}
    - connection_charset: utf8
    - require:
      - mysql_database: {{ user }}_database

add_local_{{ user }}_to_grain:
  grains.present:
    - name: mysql:user:local:{{ user }}
    - value: True

{% endif %}
{% endfor %}
{% endif %}

{%- if ambari_props.database_configurations.database_options is defined %}
{% for user, userargs in ambari_props.database_configurations.database_options.iteritems() %}

{% if not salt['grains.get']('mysql:user:all:%s' % user, False) %}
create_{{ user }}_database_user_with_all_hosts:
  mysql_query.run:
    - database: {{ userargs.db_name }}
    - query: "CREATE USER '{{ user }}'@'%' IDENTIFIED BY '{{ userargs.db_password }}';"
    - connection_host: localhost
    - connection_user: {{ mysql.root_user }}
    - connection_pass: {{ mysql.root_password }}
    - connection_charset: utf8
    - require:
      - mysql_database: {{ user }}_database

add_all_{{ user }}_to_grain:
  grains.present:
    - name: mysql:user:all:{{ user }}
    - value: True

{% endif %}
{% endfor %}
{% endif %}