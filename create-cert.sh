name="example"

openssl req \
    -x509 \
    -new \
    -newkey rsa:4096 \
    -keyout $name.key \
    -out $name.crt \
    -days 365 \
    -nodes \
    -subj "/C=US/OU=Me/ST=Where/L=Moon/O=Tycho/CN=www.$name.com"

openssl pkcs12 \
    -export \
    -nodes \
    -out $name.pfx \
    -inkey $name.key \
    -in $name.crt \
    -passout pass: