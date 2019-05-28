#***********************************************************
# Set Timezone
#***********************************************************

apt -y install libpcre3-dev libssl-dev unzip build-essential daemon libxml2-dev libxslt1-dev libgd-dev libgeoip-dev




mkdir /home/nginx-waf/
wget https://nginx.org/download/nginx-1.17.0.tar.gz -O /home/nginx-waf/nginx.tar.gz
tar xzf /home/nginx-waf/nginx.tar.gz -C /home/nginx-waf

wget https://github.com/nbs-system/naxsi/archive/master.zip -O /home/nginx-waf/waf.zip
unzip /home/nginx-waf/waf.zip -d /home/nginx-waf/


cat > /home/nginx-waf/nginx-1.17.0/install.sh <<\EOF
cd /home/nginx-waf/nginx-1.17.0/
./configure --conf-path=/etc/nginx/nginx.conf --add-module=../naxsi-master/naxsi_src/ --error-log-path=/var/log/nginx/error.log --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-log-path=/var/log/nginx/access.log --http-proxy-temp-path=/var/lib/nginx/proxy --lock-path=/var/lock/nginx.lock --pid-path=/var/run/nginx.pid --user=www-data --group=www-data --with-http_ssl_module --without-mail_pop3_module --without-mail_smtp_module --without-mail_imap_module --without-http_uwsgi_module --without-http_scgi_module --prefix=/usr
make
make install
EOF

sh /home/nginx-waf/nginx-1.17.0/install.sh



mkdir -p /var/lib/nginx/{body,fastcgi}




cp /home/nginx-waf/naxsi-master/naxsi_config/naxsi_core.rules /etc/nginx/

cat > /etc/nginx/naxsi.rules <<\EOF
SecRulesEnabled;
DeniedUrl "/RequestDenied";

## Check Naxsi rules
CheckRule "$SQL >= 8" BLOCK;
CheckRule "$RFI >= 8" BLOCK;
CheckRule "$TRAVERSAL >= 4" BLOCK;
CheckRule "$EVADE >= 4" BLOCK;
CheckRule "$XSS >= 8" BLOCK;
EOF




sudo sed -i '/nobody;/a    user  www-data;' /etc/nginx/nginx.conf


sudo sed -i '/mime.types;/a    include /etc/nginx/naxsi_core.rules;' /etc/nginx/nginx.conf
sudo sed -i '/mime.types;/a        include /etc/nginx/conf.d/*.conf;' /etc/nginx/nginx.conf
sudo sed -i '/mime.types;/a    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf

sudo sed -i '/application/octet-stream;/a    access_log /var/log/nginx/access.log;' /etc/nginx/nginx.conf
sudo sed -i '/application/octet-stream;/a    error_log /var/log/nginx/error.log;' /etc/nginx/nginx.conf


sudo sed -i '/index  index.html index.htm;/a    include /etc/nginx/naxsi.rules;' /etc/nginx/nginx.conf


cat > /lib/systemd/system/nginx.service <<\EOF
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF



mkdir /etc/systemd/system/nginx.service.d
printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
systemctl daemon-reload

systemctl start nginx
