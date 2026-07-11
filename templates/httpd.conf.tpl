ServerRoot "{{APACHE_DIR}}"
PidFile "{{LOGS_DIR}}\httpd.pid"
LoadModule access_compat_module "{{APACHE_DIR}}\modules\mod_access_compat.so"
LoadModule authn_core_module "{{APACHE_DIR}}\modules\mod_authn_core.so"
LoadModule authz_core_module "{{APACHE_DIR}}\modules\mod_authz_core.so"
LoadModule authz_host_module "{{APACHE_DIR}}\modules\mod_authz_host.so"
LoadModule alias_module "{{APACHE_DIR}}\modules\mod_alias.so"
LoadModule dir_module "{{APACHE_DIR}}\modules\mod_dir.so"
LoadModule env_module "{{APACHE_DIR}}\modules\mod_env.so"
LoadModule headers_module "{{APACHE_DIR}}\modules\mod_headers.so"
LoadModule log_config_module "{{APACHE_DIR}}\modules\mod_log_config.so"
LoadModule mime_module "{{APACHE_DIR}}\modules\mod_mime.so"
LoadModule rewrite_module "{{APACHE_DIR}}\modules\mod_rewrite.so"
LoadModule ssl_module "{{APACHE_DIR}}\modules\mod_ssl.so"
Listen {{HTTP_PORT}}
ServerName {{HOST_NAME}}:{{HTTP_PORT}}
DirectoryIndex index.php index.html
DocumentRoot "{{DOCUMENT_ROOT}}"
<Directory "{{DOCUMENT_ROOT}}">
  AllowOverride All
  Require all granted
</Directory>
Alias /dashboard "{{DASHBOARD_DIR}}"
<Directory "{{DASHBOARD_DIR}}">
  AllowOverride All
  Require all granted
</Directory>
Alias /adminer "{{ADMINER_DIR}}"
<Directory "{{ADMINER_DIR}}">
  AllowOverride All
  Require all granted
</Directory>
{{APACHE_MODULE_LINES}}
LoadModule php_module "{{PHP_MODULE}}"
AddHandler application/x-httpd-php .php
PHPIniDir "{{GENERATED_DIR}}"
ErrorLog "{{LOGS_DIR}}\apache-error.log"
CustomLog "{{LOGS_DIR}}\apache-access.log" common
IncludeOptional "{{GENERATED_DIR}}\httpd-vhosts.conf"
{{SSL_INCLUDE}}
