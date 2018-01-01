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

index:
	perl make_index.pl > jsoned/index.html
