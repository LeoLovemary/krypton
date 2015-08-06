# Copyright (c) 2015 Cesanta Software Limited
# All rights reserved

SOURCES = src/b64.c src/ber.c src/bigint.c src/ctx.c src/hexdump.c src/hmac.c \
					src/md5.c src/meth.c src/pem.c src/prf.c src/random.c src/rc4.c \
					src/rsa.c src/sha1.c src/sha256.c src/ssl.c src/tls.c src/tls_cl.c \
					src/tls_recv.c src/tls_sv.c src/x509.c src/x509_verify.c
HEADERS = src/ktypes.h src/crypto.h src/bigint_impl.h src/bigint.h \
					src/tlsproto.h src/tls.h src/ber.h src/pem.h src/x509.h
TEST_SOURCES = test/sv-test.c test/cl-test.c
CFLAGS := -O2 -W -Wall -Wno-unused-parameter $(CLFAGS_EXTRA)

CLANG_FORMAT := clang-format

ifneq ("$(wildcard /usr/local/bin/clang-3.6)","")
	CLANG:=/usr/local/bin/clang-3.6
	CLANG_FORMAT:=/usr/local/bin/clang-format-3.6
endif

.PHONY: all clean tests openssl-tests krypton-tests

all: tests format

krypton.c: $(HEADERS) $(SOURCES) Makefile
	cat openssl/ssl.h $(HEADERS) $(SOURCES) | sed -E "/#include .*(ssl.h|`echo $(HEADERS) | sed -e 's,src/,,g' -e 's, ,|,g'`)/d" > $@

tests: openssl-tests krypton-tests

krypton-tests: CFLAGS += -DUSE_KRYPTON=1 -I.
krypton-tests: sv-test-krypton cl-test-krypton

openssl-tests: sv-test-openssl cl-test-openssl

sv-test-openssl: test/sv-test.c
	$(CC) $(CFLAGS) -o sv-test-openssl test/sv-test.c -lssl -lcrypto

cl-test-openssl: test/cl-test.c
	$(CC) $(CFLAGS) -o cl-test-openssl test/cl-test.c -lssl -lcrypto

sv-test-krypton: test/sv-test.c krypton.c
	$(CC) $(CFLAGS) -o sv-test-krypton test/sv-test.c krypton.c

cl-test-krypton: test/cl-test.c krypton.c
	$(CC) $(CFLAGS) -o cl-test-krypton test/cl-test.c krypton.c

vc6: krypton.c
	wine cl -c $(SOURCES) -Isrc -DNOT_AMALGAMATED

format:
	@find . -name "*.[ch]" | xargs $(CLANG_FORMAT) -i

clean:
	rm -rf *-openssl *-krypton *.o *.gc* *.dSYM *.exe *.obj *.pdb
