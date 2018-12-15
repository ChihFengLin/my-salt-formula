{% from "hdp/ambari/map.jinja" import mysql with context %}
{% set root_password = salt['pillar.get']('mysql:root_password', mysql.root_password) %}

mysql_config:
  file.managed:
    - name: {{ mysql.config }}
    - source: salt://hdp/ambari/mysql/files/my.cnf.{{ grains.os_family }}
    - mode: 644
    - template: jinja
    - require:
      - pkg: mysql57_community_release

mysql_config_dir:
  file.directory:
    - name: /etc/mysql/conf.d
    - makedirs: true
    - mode: 755

mysql_service:
  service.running:
    - name: {{ mysql.service }}
    - enable: true
    - require:
      - file: mysql_config
    - watch:
      - file: mysql_config

{% if salt['grains.get']('mysql:database:first', True) %}
reset_root_password_using_mysql_secure:
  cmd.script:
    - source: salt://hdp/ambari/mysql/files/mysql_secure.sh
    - user: root
    - group: root
    - shell: /bin/bash
    - args: "'{{ mysql.log_file }}' '{{ root_password }}'"
    - require:
      - service: mysql_service

add_database_first_install_to_grain:
  grains.present:
    - name: mysql:database:first
    - value: False
{% endif %}