#
all:    test



ssl:
	mkdir ssl
openssl-fips-2.0.13/.built:	openssl-fips-2.0.13.tar.gz ssl
	gunzip -c openssl-fips-2.0.13.tar.gz | tar xf -
	cd openssl-fips-2.0.13; \
	export FIPSDIR=$$PWD/../ssl/fips2.0; \
	./config; \
	make; \
	make install; \
	touch .built


openssl-1.0.1t/.built:	openssl-fips-2.0.13/.built openssl-1.0.1t.tar.gz
	gunzip  -c openssl-1.0.1t.tar.gz | tar xf -
	cd openssl-1.0.1t; \
	./config fips shared no-krb5 no-rc5 no-idea no-asm -fno-strict-aliasing --openssldir=$$PWD/../ssl --with-fipsdir=$$PWD/../ssl/fips2.0; \
	make depend; \
	make; \
	make install; \
	touch .built


test:   openssl-1.0.1t/.built
	OPENSSL_FIPS=1 LD_LIBRARY_PATH=ssl/lib ssl/bin/openssl version
	# this should work:
	LD_LIBRARY_PATH=ssl/lib ssl/bin/openssl md5 Makefile
	# should get errors for this:
	OPENSSL_FIPS=1 LD_LIBRARY_PATH=ssl/lib ssl/bin/openssl md5 Makefile


clean: 
	rm -rf openssl-fips-2.0.13 openssl-1.0.1t ssl
