Listen 127.0.0.1:{{HTTPS_PORT}}
<VirtualHost _default_:{{HTTPS_PORT}}>
  DocumentRoot "{{DOCUMENT_ROOT}}"
  ServerName {{HOST_NAME}}:{{HTTPS_PORT}}
  SSLEngine on
  SSLCertificateFile "{{SSL_CERT_FILE}}"
  SSLCertificateKeyFile "{{SSL_KEY_FILE}}"
  ErrorLog "{{LOGS_DIR}}\apache-ssl-error.log"
  CustomLog "{{LOGS_DIR}}\apache-ssl-access.log" common
</VirtualHost>