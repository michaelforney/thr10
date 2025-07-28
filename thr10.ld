MEMORY
{
	rom.ssp2 (rx) : ORIGIN = 0x0000000, LENGTH = 0x0002000
	ram0      (w) : ORIGIN = 0x1000000, LENGTH = 0x0020000
	rom      (rx) : ORIGIN = 0x2000000, LENGTH = 0x0200000
	ram1      (w) : ORIGIN = 0x4000000, LENGTH = 0x0040000
}

SECTIONS
{
	.text       0x2010000 : { thr10_*.o(.text)     } >rom
	.data.dsp             : { thr10_*.o(.data.dsp) } >ram1 AT>rom
	.bss.dsp              : { thr10_*.o(.bss.dsp)  } >ram1
	.data.exc   0x101F1D0 : { thr10_*.o(.data.exc) } >ram0 AT>rom
	.data       0x1008000 : { thr10_*.o(.data)     } >ram0 AT>rom
	.bss                  : { thr10_*.o(.bss)      } >ram0

	.fwinfo 0x210FFD0 : { *(.fwinfo) } >rom
}
