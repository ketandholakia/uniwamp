ServerRoot "{{APACHE_DIR}}"
PidFile "{{LOGS_DIR}}\httpd.pid"
Listen 127.0.0.1:{{HTTP_PORT}}
ServerName {{HOST_NAME}}:{{HTTP_PORT}}
DocumentRoot "{{DOCUMENT_ROOT}}"
<Directory "{{DOCUMENT_ROOT}}">
  AllowOverride All
  Require all granted
</Directory>
Alias /dashboard "{{DASHBOARD_DIR}}"
<Directory "{{DASHBOARD_DIR}}">
  AllowOverride All
  Require ip 127.0.0.1 ::1
</Directory>
Alias /adminer "{{ADMINER_DIR}}"
<Directory "{{ADMINER_DIR}}">
  AllowOverride All
  Require ip 127.0.0.1 ::1
</Directory>
{{APACHE_MODULE_LINES}}
LoadModule php_module "{{PHP_MODULE}}"
PHPIniDir "{{GENERATED_DIR}}"
ErrorLog "{{LOGS_DIR}}\apache-error.log"
CustomLog "{{LOGS_DIR}}\apache-access.log" common
IncludeOptional "{{GENERATED_DIR}}\httpd-vhosts.conf"
{{SSL_INCLUDE}}