clean:
	rm irealb_1300.parsed

decode:
	rm -f decoded/*
	perl decode_irealb.pl < irealb_1300.url

parse: 
	rm -f parsed/*
	perl make_parse.pl

json:
	rm -f json/reject/*.json json/*.json
	perl make_json.pl
	@echo -n "PASS:   " ; ls -l jsoned/*.json | wc -l 
	@echo -n "REJECT: " ; ls -l jsoned/reject/* | wc -l

site:
	perl make_index.pl > index.html
	(test -f ../jazzbook.html && mv ../jazzbook.html .) || /bin/true
	sudo cp index.html jazzbook.html /var/www/html/
	sudo rm -f /var/www/html/tunes/*.json
	sudo cp jsoned/*.json /var/www/html/tunes/
