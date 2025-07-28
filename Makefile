.POSIX:

CC=armeb-none-eabi-gcc

-include config.mk

FW?=thr10_ver104c_20120803

CC+=-mcpu=arm7tdmi -mbig-endian
CFLAGS+=-Wall
CFLAGS+=-mthumb -ffreestanding -g -fno-pic -O2

BUILDCC?=c99
BUILDCFLAGS?=-O2

.PHONY: all
all: $(FW).elf

tools/bintomid.o: tools/bintomid.c
	$(BUILDCC) $(BUILDCFLAGS) -c -o $@ tools/bintomid.c
tools/bintomid: tools/bintomid.o
	$(BUILDCC) $(BUILDLDFLAGS) -o $@ tools/bintomid.o

thr10_ver104c_20120803.o: thr10_ver104c_20120803.s thr10_ver104c_20120803.bin
	$(CC) $(CFLAGS) -c -o $@ thr10_ver104c_20120803.s
thr10_ver104c_20120803.elf: thr10_ver104c_20120803.o thr10.ld
	$(CC) $(LDFLAGS) -static -T thr10.ld -nostdlib -o $@ thr10_ver104c_20120803.o

.PHONY:
clean:
	rm -f thr10_ver104c_20120803.o thr10_ver104c_20120803.elf \
		tools/bintomid tools/bintomid.o
