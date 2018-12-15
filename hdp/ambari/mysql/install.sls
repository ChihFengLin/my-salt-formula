{% from "hdp/ambari/map.jinja" import mysql with context %}
{% from "hdp/ambari/map.jinja" import rpm_pkg with context %}

install_pubkey_mysql:
  file.managed:
    - name: /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
    - source: {{ salt['pillar.get']('mysql:pubkey', rpm_pkg.key) }}
    - source_hash:  {{ salt['pillar.get']('mysql:pubkey_hash', rpm_pkg.key_hash) }}
        
add_rpm_into_repo:
  cmd.run:
    - name: sudo rpm -ivh {{  rpm_pkg.rpm }}
    - creates: /etc/yum.repos.d/mysql-community.repo

mysql57_community_release:
  pkg.installed:
    - pkgs: 
      - {{ mysql.server_pkg }}
      - {{ mysql.client_pkg }}
    - require:
      - file: install_pubkey_mysql

install_mysql_python_pkg:
  pkg.installed:
    - name: {{ mysql.python_pkg }}

set_pubkey_mysql:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/mysql-community.repo
    - pattern: '^gpgkey=.*'
    - repl: 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql'
    - require:
      - pkg: mysql57_community_release

set_gpg_mysql:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/mysql-community.repo
    - pattern: 'gpgcheck=.*'
    - repl: 'gpgcheck=1'
    - require:
      - pkg: mysql57_community_release