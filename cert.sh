
openssl x509 -in  <cert> -noout  -text

grep 'client-certificate-data: ' ${HOME}/.kube/config | \
   sed 's/.*client-certificate-data: //' | \
   base64 -d | \
   openssl x509 --in - --text
   
   openssl x509 -in  server.crt -noout  -text -subject
      openssl x509 -in  server.crt -noout  -text -issuer
   
   openssl verify <cert>