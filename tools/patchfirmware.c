#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <libelf.h>
#include "arg.h"

static void
usage(void)
{
	fprintf(stderr, "usage: patchfirmware file\n");
	exit(1);
}

static void
fatal(const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	fputc('\n', stderr);
	va_end(ap);
	exit(1);
}

static void
applypatch(Elf_Scn *srcscn, Elf_Scn *dstscn, Elf32_Addr addr, Elf32_Word size)
{
	Elf_Data *src, *dst;

	src = elf_getdata(srcscn, NULL);
	if (!src)
		fatal("elf_getdata: %s", elf_errmsg(-1));
	dst = elf_getdata(dstscn, NULL);
	if (dst->d_size < addr + size || src->d_size < addr + size)
		fatal("invalid patch at %lu", (unsigned long)addr);
	memcpy((char *)dst->d_buf + addr, (char *)src->d_buf + addr, size);
}

int
main(int argc, char *argv[])
{
	int fd;
	Elf *e;
	Elf_Scn *scn, *symtab;
	Elf_Data *d;
	Elf32_Shdr *sh;
	Elf32_Sym *st, *stend;
	size_t shstrndx;
	const char *name;

	ARGBEGIN {
	} ARGEND

	if (argc != 1)
		usage();

	if (elf_version(EV_CURRENT) == EV_NONE)
		fatal("unsupported libelf version");
	fd = open(argv[0], O_RDWR);
	if (fd < 0)
		fatal("open %s: %s", argv[0], strerror(errno));
	e = elf_begin(fd, ELF_C_RDWR, NULL);
	if (!e)
		fatal("elf_begin: %s", elf_errmsg(-1));
	if (elf_getshdrstrndx(e, &shstrndx) != 0)
		fatal("elf_getshdrstrndx: %s", elf_errmsg(-1));

	/* find symbol table */
	symtab = NULL;
	scn = NULL;
	while ((scn = elf_nextscn(e, scn)) != NULL) {
		sh = elf32_getshdr(scn);
		if (sh->sh_type == SHT_SYMTAB) {
			symtab = scn;
			break;
		}
	}
	if (!symtab)
		fatal("no symbol table");

	d = NULL;
	while ((d = elf_getdata(symtab, d)) != NULL) {
		for (st = d->d_buf, stend = st + d->d_size / sizeof *st; st != stend; ++st) {
			if (ELF32_ST_TYPE(st->st_info) != STT_NOTYPE)
				continue;
			scn = elf_getscn(e, st->st_shndx);
			if (!scn)
				continue;
			sh = elf32_getshdr(scn);
			if (!sh)
				fatal("elf32_getshdr: %s", elf_errmsg(-1));
			name = elf_strptr(e, shstrndx, sh->sh_name);
			if (name && strncmp(name, ".patch.", 7) == 0) {
				Elf_Scn *dstscn;

				dstscn = elf_getscn(e, sh->sh_link);
				if (!dstscn)
					fatal("elf_getscn: %s", elf_errmsg(-1));
				applypatch(scn, dstscn, st->st_value, st->st_size);
			}
		}
	}

	/* move patch relocations to patched section */
	scn = NULL;
	while ((scn = elf_nextscn(e, scn)) != NULL) {
		sh = elf32_getshdr(scn);
		if (sh->sh_type == SHT_REL) {
			Elf_Scn *infoscn;
			Elf32_Shdr *infosh;

			infoscn = elf_getscn(e, sh->sh_info);
			if (!infoscn)
				fatal("elf_getscn: %s", elf_errmsg(-1));
			infosh = elf32_getshdr(infoscn);
			if (!infosh)
				fatal("elf32_getshdr: %s", elf_errmsg(-1));
			name = elf_strptr(e, shstrndx, infosh->sh_name);
			if (name && strncmp(name, ".patch.", 7) == 0) {
				sh->sh_info = infosh->sh_link;
				elf_flagscn(scn, ELF_C_SET, ELF_F_DIRTY);
			}
		}
	}

	if (elf_update(e, ELF_C_WRITE) < 0)
		fatal("elf_update: %s", elf_errmsg(-1));
	elf_end(e);
	return 0;
}
