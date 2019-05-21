#***********************************************************
# Install YUI Compressor
#***********************************************************
sudo apt install -y yui-compressor


#***********************************************************
# Create js compression script
#***********************************************************

cat > /var/www/html/compress_js.sh <<\EOF
#!/bin/sh
for file in `find . -name "*.js"`
do
echo "Compressing $file …"
yui-compressor --type js -o $file $file
done
EOF



#***********************************************************
# Perform JS compression (Takes a VERY LONG TIME)
#***********************************************************

sh /var/www/html/compress_js.sh


#***********************************************************
# Install JPEG Optim
#***********************************************************




sudo apt -y install jpegoptim


cat > /var/www/html/compress_jpg.sh <<\EOF
#!/bin/sh
for file in `find . -name "*.jpg"`
do
echo "Compressing $file …"
jpegoptim $file
done
EOF

#***********************************************************
# Run JPEG Compression
#***********************************************************


sudo sh -c "sh /var/www/html/compress_jpg.sh"
