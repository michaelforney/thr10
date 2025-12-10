.POSIX:

CC=armeb-none-eabi-gcc
OBJCOPY=armeb-none-eabi-objcopy

-include config.mk

FW?=thr10_ver104c_20120803

CC+=-mcpu=arm7tdmi -mbig-endian
CFLAGS+=-Wall
CFLAGS+=-mthumb -ffreestanding -fno-pic
CFLAGS+=-g -O2

BUILDCC?=c99
BUILDCFLAGS?=-O2
LIBELF_LIBS?=-l elf

.PHONY: all
all: thr10.mid thr10.bin

tools/patchfirmware.o: tools/patchfirmware.c
	$(BUILDCC) $(BUILDCFLAGS) $(LIBELF_CFLAGS) -c -o $@ tools/patchfirmware.c
tools/patchfirmware: tools/patchfirmware.o
	$(BUILDCC) $(BUILDLDFLAGS) $(LIBELF_LDFLAGS) -o $@ tools/patchfirmware.o $(LIBELF_LIBS)
tools/bintomid.o: tools/bintomid.c
	$(BUILDCC) $(BUILDCFLAGS) -c -o $@ tools/bintomid.c
tools/bintomid: tools/bintomid.o
	$(BUILDCC) $(BUILDLDFLAGS) -o $@ tools/bintomid.o

.s.o:
	$(CC) $(CFLAGS) -c -o $@ $<

thr10_ver104c_20120803.o: thr10_ver104c_20120803.bin thr10.s
thr10_ver104c_20120803.elf: thr10_ver104c_20120803.o thr10.ld
	$(CC) $(LDFLAGS) -static -T thr10.ld -nostdlib -o $@ thr10_ver104c_20120803.o

thr10_ver104c_20120803-patched.o: thr10_ver104c_20120803.o patch-thr10_ver104c_20120803.o tools/patchfirmware
	$(CC) -r -o $@.tmp thr10_ver104c_20120803.o patch-thr10_ver104c_20120803.o
	tools/patchfirmware $@.tmp
	$(OBJCOPY) -R '.patch.*' $@.tmp $@
	rm -f $@.tmp

OBJ=\
	patch.o\
	$(FW)-patched.o

thr10.elf: $(OBJ) thr10.ld
	$(CC) $(LDFLAGS) -no-pie -static -T thr10.ld -nostdlib -o $@ $(OBJ) -l gcc

thr10.bin: thr10.elf
	$(OBJCOPY) -O binary -j '.text*' -j '.data*' -j '.rodata*' -j '.fwinfo' --gap-fill 0xFF --pad-to 0x2110000 thr10.elf $@

thr10.mid: thr10.bin tools/bintomid
	tools/bintomid thr10.bin $@

.PHONY: clean
clean:
	rm -f thr10.mid thr10.bin thr10.elf $(OBJ)\
		thr10_ver104c_20120803.o thr10_ver104c_20120803.elf patch-thr10_ver104c_20120803.o\
		tools/bintomid tools/bintomid.o\
		tools/patchfirmware tools/patchfirmware.o
