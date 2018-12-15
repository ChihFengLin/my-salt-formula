{% from 'hdp/ambari/map.jinja' import ambari_props with context %}
{%- set ambari_server_conf = ambari_props.ambari_server_conf %}
{%- set hosts = ambari_props.hosts %}
{%- set ambari_version = ambari_props.repos.ambari %}
{%- set db_conf = ambari_props.database_configurations %}
{%- set java_conf = ambari_props.java_configurations %}

include:
  - hdp.ambari.repo

{% if salt['grains.get']('os_family') == 'RedHat' %}
ambari_server_{{ ambari_version.version }}_pkg:
  pkg.installed:
    - name: ambari-server
{% endif %}

ambari_server_properties:
  file.managed:
    - name: /etc/ambari-server/conf/ambari.properties
    - source: salt://hdp/ambari/server/files/ambari.properties
    - template: jinja
    - user: root
    - group: root
    - permission: 0644
    - makedirs: True
    - require_in:
      - pkg: ambari_server_{{ ambari_version.version }}_pkg

ambari-server-log4j:
  file.managed:
    - name: /etc/ambari-server/conf/log4j.properties
    - source: salt://hdp/ambari/server/files/log4j.properties
    - template: jinja
    - user: root
    - group: root
    - permission: 0644
    - makedirs: True
    - require_in:
      - pkg: ambari_server_{{ ambari_version.version }}_pkg


{% if db_conf.database_type == 'mysql' %}
install_mysql_required_packages:
  pkg.installed:
    - pkgs: {{ db_conf['mysql'].packages }}

{% if not salt['grains.get']('ambari:schena:imported', False) %}
load_ambari_server_schema_into_mysql:
  cmd.run:
    - name: >-
        mysql -uambari
        -p{{ db_conf.database_options.ambari.db_password }}
        {{ db_conf.database_options.ambari.db_name }}
        < /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql

add_ambari_server_schema_flag_to_grain:
  grains.present:
    - name: ambari:schena:imported
    - value: True
{% endif %}

configure_ambari_JDBC_driver_mysql:
  cmd.run:
    - name: >-
        /usr/sbin/ambari-server setup
        --jdbc-db=mysql
        --jdbc-driver={{ db_conf['mysql'].jdbc_location }}
{% endif %}

ambari_server_setup_for_java_home_and_database:
  cmd.run:
    - name: >-
        /usr/sbin/ambari-server setup -s -j {{ java_conf.openjdk_path }}
        --database={{ db_conf.database_type }}
        --databasehost={{ grains.host }}
        --databaseport={{ hosts.database_server.port }}
        --databaseusername=ambari
        --databasename={{ db_conf.database_options.ambari.db_name }}
        --databasepassword={{ db_conf.database_options.ambari.db_password }}