{% from "hdp/ambari/map.jinja" import mysql with context %}
{% from "hdp/ambari/map.jinja" import ambari_props with context %}

include:
  - hdp.ambari.mysql.service

remove_default_test_database:
  mysql_database.absent:
    - name: test
    - connection_host: localhost
    - connection_user: {{ mysql.root_user }}
    - connection_pass: {{ mysql.root_password }}
    - connection_charset: utf8
    - require:
      - service: mysql_service

{%- if ambari_props.database_configurations.database_options is defined %}
{% for user, userargs in ambari_props.database_configurations.database_options.iteritems() %}

{% if not salt['grains.get']('mysql:database:%s' % userargs.db_name, False) %}
{{ user }}_database:
  mysql_database.present:
    - name: {{ userargs.db_name }}
    - connection_host: localhost
    - connection_user: {{ mysql.root_user }}
    - connection_pass: {{ mysql.root_password }}
    - connection_charset: utf8
    - require:
      - service: mysql_service

add_{{ user }}_database_to_grain:
  grains.present:
    - name: mysql:database:{{ userargs.db_name }}
    - value: True
{% endif %}

{% endfor %}
{% endif %}