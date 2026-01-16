external_url 'https://${gitlab_domain}'

nginx['ssl_certificate'] = '${cert_path}'
nginx['ssl_certificate_key'] = '${key_path}'

gitlab_rails['initial_root_password'] = '${temp_password}'