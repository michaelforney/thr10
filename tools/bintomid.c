#include <errno.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "arg.h"
#include "intpack.h"

static void
usage(void)
{
	fprintf(stderr, "bintomid bin mid\n");
	exit(1);
}

static inline void *
putbe14_7bit(void *p, uint_least16_t v)
{
	unsigned char *b = p;

	b[0] = v >> 7 & 0x7F;
	b[1] = v & 0x7F;
	return b + 2;
}

static void
writevarint(FILE *f, int value)
{
	unsigned char buf[(sizeof value * CHAR_BIT + 6) / 7];
	unsigned char *pos;

	pos = buf + sizeof buf;
	*--pos = value & 0x7F;
	while (value > 0x7F) {
		value >>= 7;
		*--pos = (value & 0x7F) | 0x80;
	}
	fwrite(pos, 1, sizeof buf - (pos - buf), f);
}

static void
writemeta(FILE *f, int delta, int type, const unsigned char *data, size_t datalen)
{
	writevarint(f, delta);
	fputc(0xFF, f);
	fputc(type, f);
	writevarint(f, datalen);
	if (datalen > 0)
		fwrite(data, 1, datalen, f);
}

static void
writesysex(FILE *f, int delta, const unsigned char *msg, size_t len)
{
	writevarint(f, delta);
	if (*msg == 0xF0) {
		fputc(0xF0, f);
		++msg, --len;
	} else {
		fputc(0xF7, f);
	}
	writevarint(f, len);
	fwrite(msg, 1, len, f);
}

static int
checksum(const unsigned char *buf, size_t len)
{
	const unsigned char *end;
	int sum;

	sum = 0;
	for (end = buf + len; buf != end; ++buf)
		sum = (sum + *buf) & 0x7F;
	return sum;
}

int
main(int argc, char *argv[])
{
	static const unsigned char timesig[] = {0x04, 0x02, 0x18, 0x08};
	static const unsigned char dta1erase[] = {
		0xF0, 0x43, 0x7D, 0x30,
		'D', 'T', 'A', '1', 'E', 'R', 'A', 'S', 'E',
		0x02, 0xF7,
	};
	static const unsigned char dta1main[] = {
		0xF0, 0x43, 0x7D, 0x40,
		0x00, 0x00,
		'D', 'T', 'A', '1', 'M', 'A', 'I', 'N',
	};
	static const unsigned char dta1csum[] = {
		0xF0, 0x43, 0x7D, 0x70,
		'D', 'T', 'A', '1', 'C', 'S', 'U', 'M',
		0x00, 0xF7,
	};
	FILE *bin, *mid;
	int block, delta, csum;
	long lenoff, endoff;
	unsigned char *pos;
	unsigned char data[448];
	unsigned char buf[sizeof dta1main + 4 + (sizeof data + 6) / 7 * 8 + 2];

	ARGBEGIN {
	} ARGEND

	if (argc != 2)
		usage();

	bin = fopen(argv[0], "rb");
	if (!bin) {
		fprintf(stderr, "open %s: %s\n", argv[0], strerror(errno));
		return 1;
	}
	mid = fopen(argv[1], "wb");
	if (!mid) {
		fprintf(stderr, "open %s: %s\n", argv[1], strerror(errno));
		return 1;
	}

	pos = buf;
	memcpy(pos, "MThd", 4), pos += 4;
	pos = putbe32(pos, 6);
	pos = putbe16(pos, 0);
	pos = putbe16(pos, 1);
	pos = putbe16(pos, 500);  /* 500 ticks / beat * 120 beat / minute = 1 tick / msec */
	memcpy(pos, "MTrk", 4), pos += 4;
	pos = putbe32(pos, 0);  /* track length, rewritten later */
	fwrite(buf, 1, pos - buf, mid);
	lenoff = ftell(mid);
	if (lenoff == -1) {
		perror("ftell");
		return 1;
	}

	putbe24(buf, 500000);
	writemeta(mid, 0, 0x51, buf, 3);
	writemeta(mid, 0, 0x58, timesig, sizeof timesig);
	writesysex(mid, 0, dta1erase, sizeof dta1erase);

	block = 0;
	delta = 16000;
	csum = 0;
	for (;;) {
		size_t len;
		int i, j;

		len = fread(data, 1, 448, bin);
		if (len == 0)
			break;
		pos = buf;
		memcpy(pos, dta1main, sizeof dta1main), pos += sizeof dta1main;
		putbe14_7bit(buf + 4, sizeof dta1main - 6 + 4 + (len + 6) / 7 * 8);
		pos = putbe14_7bit(pos, block);
		pos = putbe14_7bit(pos, 0x3FFF);
		for (i = 0; i < len; i += 7) {
			int high, byte;

			high = 0;
			for (j = 0; j < 7; ++j) {
				byte = i + j < len ? data[i + j] : 0;
				*pos++ = byte & 0x7F;
				high |= (byte & 0x80) >> (j + 1);
			}
			*pos++ = high;
		}
		csum = (csum + checksum(data, len)) & 0x7F;
		*pos = (~checksum(buf + 6, pos - buf - 6) + 1) & 0x7F, ++pos;
		*pos++ = 0xF7;
		writesysex(mid, delta, buf, pos - buf);
		++block;
		delta = 50;
	}
	if (ferror(bin)) {
		fprintf(stderr, "read %s: %s\n", argv[0], strerror(errno));
		return 1;
	}

	memcpy(buf, dta1csum, sizeof dta1csum);
	buf[sizeof dta1csum - 2] = (~csum + 1) & 0x7F;
	writesysex(mid, delta, buf, sizeof dta1csum);
	writemeta(mid, 0, 0x2F, NULL, 0);

	endoff = ftell(mid);
	if (endoff == -1) {
		perror("ftell");
		return -1;
	}
	fseek(mid, lenoff - 4, SEEK_SET);

	putbe32(buf, endoff - lenoff);
	fwrite(buf, 1, 4, mid);
	fflush(mid);
	if (ferror(mid)) {
		fprintf(stderr, "write %s failed\n", argv[1]);
		return 1;
	}
	return 0;
}
