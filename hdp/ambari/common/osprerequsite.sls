{% from "hdp/ambari/map.jinja" import ambari_props with context -%}

make sure ntp service is started:
  service.running:
    - name: {{ ambari_props.ntp_service_name }}
    - enable: True

#disableselinux:
#  selinux.mode:
#    - name: permissive

make sure /etc/security/limits.d exists:
  file.directory:
    - name: /etc/security/limits.d
    - dir_mode: 755

update kernel parameters:
  file.managed:
    - name: /etc/security/limits.d/99-hadoop.conf
    - mode: 0644
    - create: True
    - contents:
      - "* soft nofile 32768"
      - "* hard nofile 22768"
      - "* soft nproc 32768"
      - "* hard nproc 32768"
      - "root       soft    nproc    unlimited"
      - "ams        -       nofile   64000"
      - "atlas      -       nofile   64000"
      - "druid      -       nofile   64000"
      - "hive       -       nofile   64000"
      - "infra-solr -       nofile   64000"
      - "kms        -       nofile   64000"
      - "knox       -       nofile   64000"
      - "logsearch  -       nofile   64000"
      - "ranger     -       nofile   64000"
      - "spark      -       nofile   64000"
      - "zeppelin   -       nofile   64000"
      - "zookeeper  -       nofile   64000"

disabled ipv6:
  file.append:
    - name: /etc/sysctl.conf
    - text:
      - "net.ipv6.conf.all.disable_ipv6 = 1"
      - "net.ipv6.conf.default.disable_ipv6 = 1"
      - "net.ipv6.conf.lo.disable_ipv6 = 1"
      - "vm.swappiness=1"

disable transparent huge pages until the next reboot:
  cmd.run:
    - name: >-
        echo never > /sys/kernel/mm/transparent_hugepage/enabled &&
        echo never > /sys/kernel/mm/transparent_hugepage/defrag
    - onlyif: 'test -e /sys/kernel/mm/transparent_hugepage/enabled'

update Grub parameters:
  file.append:
    - name: /etc/default/grub
    - text:
      - "GRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX transparent_hugepage=never\""

'grub2-mkconfig -o /boot/grub2/grub.cfg':
  cmd.run
