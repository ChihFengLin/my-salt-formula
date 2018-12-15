{% from "repo_server/map.jinja" import repo_server with context %}

remove_all_httpd_files:
  file.directory:
    - name: {{repo_server.httpd_root}}/           
    - clean: True
