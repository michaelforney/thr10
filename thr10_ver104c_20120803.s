.include "thr10.s"

.macro fwdata addr:req,size:req
	.incbin "thr10_ver104c_20120803.bin",\addr-0x2010000,\size
.endm

.text
	fwdata 0x2010000,0x7645C

.section .data.dsp,"aw"
	fwdata 0x208645C,0x10100
.section .bss.dsp,"aw",%nobits
	.space 0x00118B4

.data
	fwdata 0x2096F8C,0x03AD0
.bss
	.space 0x000A49C

.section .data.exc,"aw"
	fwdata 0x209655C,0x00800  @ irq
	fwdata 0x2096D5C,0x00100  @ svc
	fwdata 0x2096E5C,0x00100  @ usr
	fwdata 0x2096F5C,0x00010  @ abt
	fwdata 0x2096F6C,0x00010  @ und
	fwdata 0x2096F7C,0x00010  @ fiq

.section .fwinfo,"a"
	fwdata 0x210FFD0,0x00030

func 0x201AF88+1,  584, amp_set_cabinet
func 0x201E598+1,   16, panel_get_buttons
func 0x201E72C+1,  102, panel_set_led
func 0x2028CB8+1, 3488, control_handle_buttons
func 0x2017380+1,   12, control_set_speaker
data 0x1012614       1, control_headphone_connected
func 0x203D988+1,  282, dsp_command
data 0x101260C,      2, tuner_active
data 0x4021904,     16, amp_state, base=.data.dsp-0x4000000
