decode:
	perl decode_irealb.pl < irealb_1300.url > irealb_1300.decoded

parse: decode
	perl parse_irealb.pl < irealb_1300.decoded > irealb_1300.parsed

check:
	grep -B1 ^T irealb_1300.parsed ; /bin/true
	grep -P ',[a-zA-Z]:' irealb_1300.parsed ; /bin/true


xml:
	rm -f xml/*.xml
	cd xml && ../xmlify_irealb.pl < ../irealb_1300.parsed

diag:
	perl xmlify_irealb.pl -n < irealb_1300.parsed 2>&1 >/dev/null | cut -d' ' -f 1-3  | sort | uniq -c

clean:
	rm irealb_1300.decoded irealb_1300.parsed



