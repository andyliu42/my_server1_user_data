        str_replace:
          params:
            __mysql_root_password__: { get_param: mysql_root_password }
            __database_name__: { get_param: database_name }
            __database_user__: { get_param: database_user }
            __database_password__: { get_param: database_password }
            wc_notify: { get_attr: ['wait_handle', 'curl_cli'] }
          template: |
            #!/bin/bash


            # install MySQL
            apt-get update
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y mysql-server
 
            # configure MySQL root password
            mysqladmin -u root password "__mysql_root_password__"
 
            # listen on all network interfaces
            sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
 
            # restart service
            service mysql restart
 
            # create wordpress database
            mysql -u root --password="__mysql_root_password__" <<EOF
            CREATE DATABASE __database_name__;
            CREATE USER '__database_user__'@'localhost';
            SET PASSWORD FOR '__database_user__'@'localhost'=PASSWORD("__database_password__");
            GRANT ALL PRIVILEGES ON __database_name__.* TO '__database_user__'@'localhost' IDENTIFIED BY '__database_password__';
            CREATE USER '__database_user__'@'%';
            SET PASSWORD FOR '__database_user__'@'%'=PASSWORD("__database_password__");
            GRANT ALL PRIVILEGES ON __database_name__.* TO '__database_user__'@'%' IDENTIFIED BY '__database_password__';
            FLUSH PRIVILEGES;
            EOF

            # install dependencies
            apt-get -y install apache2 php5 libapache2-mod-php5 php5-mysql php5-gd mysql-client
            # download wordpress
            wget http://wordpress.org/latest.tar.gz
            tar -xzf latest.tar.gz
            # configure wordpress
            cp wordpress/wp-config-sample.php wordpress/wp-config.php
            sed -i 's/database_name_here/__database_name__/' wordpress/wp-config.php
            sed -i 's/username_here/__database_user__/' wordpress/wp-config.php
            sed -i 's/password_here/__database_password__/' wordpress/wp-config.php
            sed -i 's/localhost/localhost/' wordpress/wp-config.php
            # install a copy of the configured wordpress into apache's www directory
            rm /var/www/html/index.html
            cp -R wordpress/* /var/www/html/
            # give apache ownership of the application files
            chown -R www-data:www-data /var/www/html/
            chmod -R g+w /var/www/html/
            # notify heat that we are done here
            wc_notify --data-binary '{"status": "SUCCESS"}'
