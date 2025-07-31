.macro mapsym type:req,addr:req
	.set \type\().\+,\addr
.endm

.macro def name:req,type:req,addr:req,size:req
	.globl \name
	.set \name,\addr
	.type \name,\type
	.size \name,\size
.endm

.macro data addr:req,size:req,name,base=.data-0x1008000
	mapsym $d,\base+\addr
	.ifb \name
		def data\+,%object,\base+\addr,\size
	.else
		def \name,%object,\base+\addr,\size
	.endif
.endm

.macro func addr:req,size:req,name,base=.text-0x2010000
	.if \addr & 1
		mapsym $t,\base+\addr-1
	.else
		mapsym $a,\base+\addr
	.endif
	.ifb \name
		def func\+,%function,\base+\addr,\size
	.else
		def \name,%function,\base+\addr,\size
	.endif
.endm
