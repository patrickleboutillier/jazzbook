site:
	perl make_index.pl > index.html
	sudo cp index.html /var/www/html/
	sudo cp *.ttf /var/www/html/
	sudo rm -f /var/www/html/irealb/*.json
	sudo cp jsoned/*.json /var/www/html/irealb/
	sudo cp -a stgraal/ /var/www/html/
