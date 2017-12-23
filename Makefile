clean:
	rm irealb_1300.parsed

decode:
	rm -f decoded/*
	perl decode_irealb.pl < irealb_1300.url

parse: 
	rm -f parsed/*
	for f in decoded/*.irealb ; do perl parse_irealb.pl $$f ; done
	cat parsed/*.parsed > irealb_1300.parsed

xml:
	rm -f xmled/pass/* xmled/reject/*
	for f in parsed/*.parsed ; do perl xmlify_irealb.pl $$f ; done
	@echo -n "PASS:   " ; ls -l xmled/pass/* | wc -l 
	@echo -n "REJECT: " ; ls -l xmled/reject/* | wc -l 


check:
	grep -B1 ^T irealb_1300.parsed ; /bin/true
	grep -P ',[a-zA-Z]:' irealb_1300.parsed ; /bin/true



diag: parse
	perl xmlify_irealb.pl -n < irealb_1300.parsed 2>&1 >/dev/null | cut -d' ' -f 1-3  | sort | uniq -c




