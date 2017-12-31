clean:
	rm irealb_1300.parsed

#decode:
#	rm -f decoded/*
#	perl decode_irealb.pl < irealb_1300.url

#parse: 
#	rm -f parsed/*
#	perl make_parse.pl

json:
	rm -f jsoned/reject/*.json jsoned/*.json
	perl make_json.pl
	@echo -n "PASS:   " ; ls -l jsoned/*.json | wc -l 
	@echo -n "REJECT: " ; ls -l jsoned/reject/* | wc -l

site:
	perl make_index.pl > index.html
	sudo cp index.html /var/www/html/
	sudo cp *.ttf /var/www/html/
	sudo rm -f /var/www/html/irealb/*.json
	sudo cp jsoned/*.json /var/www/html/irealb/
	sudo cp -a stgraal/ /var/www/html/
