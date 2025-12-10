.macro patch addr:req,body:vararg
	.if \addr > 0x2010000
		.section .patch.text,"xo",.text
		.org \addr-0x2010000
	.elseif \addr > 0x1080000
		.section .patch.data,"xo",.data
		.org \addr-0x1080000
	.endif
	patch\+:
	.ifnb \body
		\body
		endpatch
	.endif
.endm

.macro endpatch
	.size patch\+,.-patch\+
.endm

patch 0x2013B30,.word __data_dsp_load
patch 0x2013B34,.word __data_dsp
patch 0x2013B38,.word __data_dsp_size
patch 0x2013B3C,.word __bss_dsp_size
patch 0x2013B40,.word __bss_dsp

patch 0x2013BA8,.word __data_patch_load
patch 0x2013BAC,.word __data_patch
patch 0x2013BB0,.word __data_patch_size
patch 0x2013BB4,.word __bss_patch_size
patch 0x2013BB8,.word __bss_patch

patch 0x2013BBC,.word __data_load
patch 0x2013BC0,.word __data
patch 0x2013BC4,.word __data_size
patch 0x2013BC8,.word __bss_size
patch 0x2013BCC,.word __bss

.thumb

patch 0x2018512,bl wrap_dsp_command
patch 0x201A0A4,bl wrap_dsp_command @ amp 3
patch 0x201A180,bl wrap_dsp_command @ amp 0
patch 0x201A3AA,bl wrap_dsp_command @ amp 1
patch 0x201ABA6,bl wrap_dsp_command @ amp 2
patch 0x201ACCA,bl wrap_dsp_command @ amp 4

patch 0x202BF4A,bl wrap_control_set_speaker
patch 0x202BFA4,bl wrap_control_handle_buttons
