IF GEN_2_GRAPHICS
RedPicFront::  INCBIN "gfx/gstrainers/red.pic"
LeafPicFront:: INCBIN "gfx/gstrainers/leaf.pic"
rept 11 ; Padding
	db 0
endr
ELSE
RedPicFront:: INCBIN "gfx/player/red.pic"
ENDC

ShrinkPic1::  INCBIN "gfx/player/shrink1.pic"
ShrinkPic2::  INCBIN "gfx/player/shrink2.pic"
