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

	.text.patch 0x20A0000 : { *(.text)             } >rom
	.rodata.patch         : { *(.rodata*)          } >rom
	.data.patch           : { *(.data)             } >ram0 AT>rom
	.bss.patch            : { *(.bss)              } >ram0

	.fwinfo 0x210FFD0 : { *(.fwinfo) } >rom
}

__data            = ADDR(.data);
__data_load       = LOADADDR(.data);
__data_size       = SIZEOF(.data);
__data_dsp        = ADDR(.data.dsp);
__data_dsp_load   = LOADADDR(.data.dsp);
__data_dsp_size   = SIZEOF(.data.dsp);
__data_patch      = ADDR(.data.patch);
__data_patch_load = LOADADDR(.data.patch);
__data_patch_size = SIZEOF(.data.patch);
__bss             = ADDR(.bss);
__bss_size        = SIZEOF(.bss);
__bss_dsp         = ADDR(.bss.dsp);
__bss_dsp_size    = SIZEOF(.bss.dsp);
__bss_patch       = ADDR(.bss.patch);
__bss_patch_size  = SIZEOF(.bss.patch);
