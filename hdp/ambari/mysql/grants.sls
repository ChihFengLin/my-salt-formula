{% from "hdp/ambari/map.jinja" import mysql with context %}
{% from "hdp/ambari/map.jinja" import ambari_props with context %}

include:
  - hdp.ambari.mysql.database
  - hdp.ambari.mysql.users

{%- if ambari_props.database_configurations.database_options is defined %}
{% for user, userargs in ambari_props.database_configurations.database_options.iteritems() %}

{% if not salt['grains.get']('mysql:user:local:%s' % user, False) %}
grant_{{ user }}_user_with_localhost:
  mysql_query.run:
    - database: {{ userargs.db_name }}
    - query: "GRANT ALL PRIVILEGES ON *.* TO '{{ user }}'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    - connection_host: localhost
    - connection_user: {{ mysql.root_user }}
    - connection_pass: {{ mysql.root_password }}
    - connection_charset: utf8
    - require:
      - mysql_query: create_{{ user }}_database_user_with_localhost
{% endif %}

{% endfor %}
{% endif %}

{%- if ambari_props.database_configurations.database_options is defined %}
{% for user, userargs in ambari_props.database_configurations.database_options.iteritems() %}

{% if not salt['grains.get']('mysql:user:all:%s' % user, False) %}
grant_{{ user }}_user_with_all_hosts:
  mysql_query.run:
    - database: {{ userargs.db_name }}
    - query: "GRANT ALL PRIVILEGES ON *.* TO '{{ user }}'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    - connection_host: localhost
    - connection_user: {{ mysql.root_user }}
    - connection_pass: {{ mysql.root_password }}
    - connection_charset: utf8
    - require:
      - mysql_query: create_{{ user }}_database_user_with_all_hosts
{% endif %}

{% endfor %}
{% endif %}