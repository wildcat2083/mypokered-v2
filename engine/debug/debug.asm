DebugStart2:
	xor a
	call SwitchMenu

Forever:
	ld a, [wDebugMenuID]
	ld c,a
	add a,a
	add a,c
	ld c,a
	ld b,$00
	ld hl,MenuList
	add hl,bc
	inc hl
	ld e,[hl]
	inc hl
	ld d,[hl]
	inc de
	ld h,d
	ld l,e
	ld bc,Forever

	push bc
	ld bc,$0003
	ld a, [hJoyInput]
	and $40
	jp nz,DerefPointer
	add hl,bc
	ld a, [hJoyInput]
	and $80
	jp nz,DerefPointer
	add hl,bc
	ld a, [hJoyInput]
	and $20
	jp nz,DerefPointer
	add hl,bc
	ld a, [hJoyInput]
	and $10
	jp nz,DerefPointer
	add hl,bc
	ld a, [hJoyInput]
	and $02
	jp nz,DerefPointer
	add hl,bc
	ld a, [hJoyInput]
	and $01
	jp nz,DerefPointer
	pop bc
	halt
	jp Forever

DerefPointer:
	push af
	ld e,[hl]
	inc hl
	ld d,[hl]
	ld h,d
	ld l,e
	ld bc,DerefRets
	push bc
	jp hl

DerefRets:
	pop af
	ld b,a

DerefRets_L1:
	ld a, [hJoyInput]
	and b
	cp $00
	jp nz,DerefRets_L1
	ret

ReturnControlCall:
	pop bc
	pop bc
	pop bc

ReturnControl:
	ld a,SFX_SAVE
	call PlaySound
	call WaitForSoundToFinish
	ret

BackToMain:
	xor a
	call SwitchMenu
	ret

ConfirmSound:
	ld a,SFX_PURCHASE
	call PlaySound
	call WaitForSoundToFinish
	ret

DrawTextbox:
	ld a,"┌"
	ld de,$0014
	dec b
	push bc
	push hl
	ld [hli], a
	inc a ; ─
	dec c
	dec c
	call MemSet
	inc a ; ┐
	ld [hli], a

DrawTextbox_L1:
	ld a,"│"
	pop hl
	add hl,de
	pop bc
	dec b
	jr z,DrawTextbox_L2
	push bc
	push hl
	ld [hli], a
	dec c
	dec c
	ld a," "
	call MemSet
	ld [hl],"│"
	jr DrawTextbox_L1

DrawTextbox_L2:
	ld a,"└"
	ld [hli], a
	ld a,"─"
	dec c
	dec c
	call MemSet
	ld [hl],"┘"
	ret

MemSet:
	ld [hli], a
	dec c
	jr nz,MemSet
	ret

PutStringMultiline:
	push de
	ld a,[hl]
	cp $0d
	jr nz,PutStringMultiline_L2
	inc hl
	pop de
	coord de, 1, 13
	push de

PutStringMultiline_L2:
	call PutChar
	dec hl
	ld a,[hl]
	inc hl
	cp $00
	jr z,PutStringMultiline_R1
	pop de
	ld c,$14

PutStringMultiline_L1:
	inc de
	dec c
	jr nz,PutStringMultiline_L1
	push de
	jr PutStringMultiline_L2

PutStringMultiline_R1:
	pop de
	ret

PutChar:
	ld a, [hli]
	cp $00
	ret z
	cp $0a
	ret z
	ld [de],a
	inc de
	jr PutChar

SwitchMenu:
	push af

SwitchMenu_L1:
	ld a, [hJoyInput]
	cp $00
	jp nz,SwitchMenu_L1
	pop af
	ld [wDebugMenuID], a
	ld b,$00
	ld c,a
	add a,a
	add a,c
	inc a
	ld c,a
	ld hl,MenuList
	add hl,bc
	ld d,[hl]
	inc hl
	ld e,[hl]
	ld h,e
	ld l,d
	ld c,$13
	add hl,bc
	ld d,[hl]
	inc hl
	ld e,[hl]
	ld h,e
	ld l,d
	push hl
	coord hl, 2, 3
	lb bc,$09,$12
	call DrawTextbox
	pop hl
	ld bc,SwitchMenuBack
	push bc
	jp hl

SwitchMenuBack:
	ret

MenuList:
	ld bc,Menu1Properties
	ld bc,Menu2Properties
	ld bc,Menu3Properties
	ld bc,Menu4Properties
	ld bc,Menu5Properties
	ld bc,Menu6Properties
	ld bc,Menu7Properties

Menu1Properties:
	ld bc,MenuCursorUp   ; [UP]
	ld bc,MenuCursorDown ; [DOWN]
	ld bc,SwitchMenuBack ; [LEFT]
	ld bc,SwitchMenuBack ; [RIGHT]
	ld bc,ReturnControlCall  ; [B]
	ld bc,Menu1Perform   ; [A]
	ld bc,Menu1Constructor ; .ctor
	ld bc,Menu1Desc1 ; desc1
	ld bc,Menu1Desc2 ; desc1
	ld bc,Menu1Desc3 ; desc1
	ld bc,Menu1Desc4 ; desc1
	ld bc,Menu1Desc5 ; desc1
	ld bc,Menu1Desc6 ; desc1
	ld bc,Menu1Desc7 ; desc1

Menu1Text:
	db "Write memory", $0a
	db "Hex viewer", $0a
	db "Anti-crasher", $0a
	db "MemCorruptor", $0a
	db "Miscellanous", $0a
	db "Address list",$0a
	db "Exit",$00

Menu1Desc1:
	db "Write single and",$0a,$0a
	db "multi-byte values",$00

Menu1Desc2:
	db "View contents of",$0a,$0a
	db "ROM, RAM, etc.",$00

Menu1Desc3:
	db "Hook RST vectors",$0a,$0a
	db "to stop crashes",$00

Menu1Desc4:
	db "Corrupt blocks",$0a,$0a
	db "of memory",$00

Menu1Desc5:
	db "Perform common",$0a,$0a
	db "tasks and hacks",$00

Menu1Desc6:
	db "Most important",$0a,$0a
	db "addresses to know",$00

Menu1Desc7:
	db "Quit this menu",$00

Menu1Constructor:
	xor a
	ld [wDebugMenuCursorPos], a ; cursor position at 0
	ld hl,Menu1Text
	coord de, 4, 4
	call PutStringMultiline
	call MenuCursorRedraw
	ret

Menu1Perform:
	ld a, [wDebugMenuCursorPos]
	cp $06
	jp z,ReturnControlCall
	inc a
	call SwitchMenu
	ret

HexCycleTbl:
	db "0123456789ABCDEF"

ReadHexExpr:
	ld a,[hl]
	ld c,$00
	ld de,HexCycleTbl

ReadHexExpr_L1:
	ld a,[de]
	cp [hl]
	jr z,ReadHexExpr_L2
	inc c
	inc de
	jr ReadHexExpr_L1

ReadHexExpr_L2:
	ld a,c
	ret

ReadDblHexExpr:
	xor a
	call ReadHexExpr
	swap a
	inc hl
	push af
	call ReadHexExpr
	ld c,a
	pop af
	add a,c
	ret

WriteHexExpr:
	push de
	push hl
	ld hl,HexCycleTbl
	ld b,$00
	ld c,a
	add hl,bc
	ld d,h
	ld e,l
	ld a,[hl]
	pop hl
	ld [hli], a
	pop de
	ret

WriteDblHexExpr:
	ld b,a
	push bc
	swap a
	and $0f
	call WriteHexExpr
	pop bc
	ld a,b
	and $0f
	call WriteHexExpr
	ret

Menu2Properties:
	ld bc,Menu2CycUp   ; [UP]
	ld bc,Menu2CycDown ; [DOWN]
	ld bc,Menu2CurLeft ; [LEFT]
	ld bc,Menu2CurRight ; [RIGHT]
	ld bc,BackToMain ; [B]
	ld bc,Menu2Perform   ; [A]
	ld bc,Menu2Constructor ; .ctor
	ld bc,Menu2Desc1 ; desc1

Menu2Constructor:
	xor a
	ld [wDebugMenuCursorPos], a ; cursor position at 0
	inc a
	ld [wDebugMenuParam], a ; length at 1
	call MenuCursorRedraw
	ld hl,Menu2Text
	coord de, 3, 4
	call PutStringMultiline
	ld a,$f6
	ld c,$0f
	coord hl, 3, 7
	call MemSet
	coord hl, 7, 7
	ld [hl],$9c
	ld hl,Menu2Text2
	coord de, 3, 10
	call PutStringMultiline
	jp Menu2Redraw

Menu2Text:
	db " -Write memory-", $00

Menu2Text2:
	db "Expr. length: 1",$00

Menu2Desc1:
	db $0d,"START and A: Len",$0a
	db "D-PAD: Modify",$0a
	db "A Button: OK",$0a
	db "B Button: Cancel",$00

Menu2LenCyc:
	ld hl,wDebugMenuParam
	ld a,[hl]
	inc a
	ld [hl],a
	cp $06
	jr nz,Menu2LenCyc_L1
	ld [hl],$01

Menu2LenCyc_L1:
	ld a,[hl]
	coord hl, 17, 10
	add a,$f6
	ld [hl],a
	ret

Menu2Perform:
	ld a, [hJoyInput]
	and $08
	cp $00
	jr nz,Menu2LenCyc
	coord hl, 3, 7
	call ReadDblHexExpr
	ld d,a
	push de
	inc hl
	call ReadDblHexExpr
	pop de
	ld e,a
	ld a, [wDebugMenuParam]
	ld c,a
	coord hl, 8, 7

Menu2Perform_1L:
	push bc
	push de
	call ReadDblHexExpr
	inc hl
	pop de
	ld [de],a
	inc de
	pop bc
	dec c
	jr nz,Menu2Perform_1L
	call ConfirmSound
	jp BackToMain

Menu2CurLeft:
	ld hl,wDebugMenuCursorPos
	ld a,[hl]
	cp $00
	ret z
	dec [hl]
	jr Menu2Redraw

Menu2CurRight:
	ld hl,wDebugMenuCursorPos
	ld a,[hl]
	cp $0e
	ret z
	inc [hl]
	jr Menu2Redraw

Menu2Redraw:
	coord hl, 3, 6
	ld a,$7f
	ld c,$10
	push hl
	call MemSet
	pop hl
	ld a, [wDebugMenuCursorPos]
	add a,l
	ld l,a
	ld [hl],$ee
	ret

DrawBottomBox:
	coord hl, 0, 12
	ld bc,$0614
	call DrawTextbox
	ret

Menu2CycUp:
	coord hl, 3, 7
	ld a, [wDebugMenuCursorPos]
	add a,l
	ld l,a
	inc [hl]
	ld a,[hl]
	cp $9d
	jr z,MenuCycRestore
	cp $00
	jr z,Menu2CycUp_L1
	cp $86
	ret nz
	ld [hl],$f6
	ret

Menu2CycUp_L1:
	ld [hl],$80
	ret

MenuCycRestore:
	ld [hl],$9c
	ret

Menu2CycDown:
	coord hl, 3, 7
	ld a, [wDebugMenuCursorPos]
	add a,l
	ld l,a
	dec [hl]
	ld a,[hl]
	cp $9b
	jr z,MenuCycRestore
	cp $f5
	jr z,Menu2CycDown_L1
	cp $7f
	ret nz
	ld [hl],$ff
	ret

Menu2CycDown_L1:
	ld [hl],$85
	ret

Menu3Properties:
	ld bc,Menu3Up   ; [UP]
	ld bc,Menu3Down ; [DOWN]
	ld bc,Menu3Left ; [LEFT]
	ld bc,Menu3Right ; [RIGHT]
	ld bc,BackToMain ; [B]
	ld bc,Menu3AutoRefresh   ; [A]
	ld bc,Menu3Constructor ; .ctor
	ld bc,Menu3Desc1 ; desc1

Menu3Constructor:
	xor a
	ld [wDebugMenuCursorPos], a ; starting address hi byte
	ld [wDebugMenuParam], a ; starting address lo byte
	call MenuCursorRedraw
	coord hl, 3, 4
	ld [hl],$7f
	jr Menu3Redraw

Menu3Desc1:
	db $0d,"UP/DOWN: Move 100"
	db $0a,"LEFT/RIGHT: Mov.10"
	db $0a,"Hold A: Autoupdate"
	db $0a,"B Button: Cancel",$00

Menu3Redraw:
	coord hl, 3, 4
	ld c,$07
	ld a, [wDebugMenuCursorPos]
	ld d,a
	ld a, [wDebugMenuParam]
	ld e,a

Menu3Redraw_L1:
	push bc
	push hl
	ld a,d
	call WriteDblHexExpr
	ld a,e
	call WriteDblHexExpr
	ld [hl],$9c
	inc hl
	ld a,[de]
	call WriteDblHexExpr
	inc de
	ld [hl],$7f
	inc hl
	ld a,[de]
	call WriteDblHexExpr
	inc de
	ld [hl],$7f
	inc hl
	ld a,[de]
	call WriteDblHexExpr
	inc de
	ld [hl],$7f
	inc hl
	ld a,[de]
	call WriteDblHexExpr
	inc de
	pop hl
	ld bc,$0014
	add hl,bc
	pop bc
	dec c
	jr nz,Menu3Redraw_L1
	ret

Menu3Up:
	ld hl,wDebugMenuCursorPos
	ld a, [hJoyInput]
	and $08
	jr z,Menu3Up_L1
	ld a,[hl]
	sub $0f
	ld [hl],a

Menu3Up_L1:
	dec [hl]
	jp Menu3Redraw

Menu3Down:
	ld hl,wDebugMenuCursorPos
	ld a, [hJoyInput]
	and $08
	jr z,Menu3Down_L1
	ld a,[hl]
	add a, $0f
	ld [hl],a

Menu3Down_L1:
	inc [hl]
	jp Menu3Redraw

Menu3Left:
	ld hl,wDebugMenuParam
	ld a,[hl]
	cp $00
	jr nz,Menu3HiDecRet
	dec hl
	dec [hl]
	inc hl

Menu3HiDecRet:
	sub $10
	ld [hl],a
	jp Menu3Redraw

Menu3Right:
	ld hl,wDebugMenuParam
	ld a,[hl]
	cp $f0
	jr nz,Menu3HiIncRet
	dec hl
	inc [hl]
	inc hl

Menu3HiIncRet:
	add a,$10
	ld [hl],a
	jp Menu3Redraw

Menu3AutoRefresh:
	pop hl
	pop de
	ld de,$0000 ;this will disable debounce checking, since
	push de ;every x and 0 equals 0
	pop hl
	jp Menu3Redraw

Menu4Properties:
	ld bc,MenuCursorUp   ; [UP]
	ld bc,MenuCursorDown ; [DOWN]
	ld bc,SwitchMenuBack ; [LEFT]
	ld bc,SwitchMenuBack ; [RIGHT]
	ld bc,BackToMain ; [B]
	ld bc,Menu4Perform   ; [A]
	ld bc,Menu4Constructor ; .ctor
	ld bc,Menu4Desc1 ; desc1
	ld bc,Menu4Desc2 ; desc2
	ld bc,Menu4Desc3 ; desc3
	ld bc,Menu4Desc3 ; desc4
	ld bc,Menu4Desc4 ; desc5

Menu4Constructor:
	xor a
	ld [wDebugMenuCursorPos], a ; ld (wDebugMenuCursorPos),a ; cursor position at 0
	call MenuCursorRedraw
	ld hl,Menu4Text
	coord de, 4, 4
	call PutStringMultiline
	ret

Menu4Desc1:
	db "Turn off RST",$0a,$0a
	db "crash prevention",$00

Menu4Desc2:
	db $0d,"Fixes the RST",$0a
	db "vectors with an",$0a
	db "absolute jump",$0a
	db "instruction.",$00

Menu4Desc3:
	db $0d,"Fixes the RST",$0a
	db "vectors using",$0a
	db "return instru-",$0a
	db "ctions.",$00

Menu4Desc4:
	db $0d,"Fixes the RST",$0a
	db "vectors through",$0a
	db "stack manipula-",$0a
	db "tions.",$00

Menu4Text:
	db "Turn off",$0a
	db "Jump fix",$0a
	db "Return fix",$0a
	db "Dbl-return fix",$0a
	db "Stack fix",$00

Menu4FixList:
	db $00,$00,$00,$00
	db $c1,$c3,$b9,$01
	db $c9,$de,$ad,$00
	db $e1,$e1,$e1,$e9
	db $e1,$e1,$e9,$00

Menu4Perform:
	ld a, [wDebugMenuCursorPos] ; load cursor position
	add a,a
	add a,a ; multiply 4 times
	ld b,$00
	ld c,a
	ld hl,Menu4FixList
	add hl,bc
	ld de,$ffa6 ; hDivideBCDBuffer + 1
	ld c,$04

Menu4Perform_L1:
	ld a, [hli]
	ld [de],a
	inc de
	dec c
	jr nz,Menu4Perform_L1
	call ConfirmSound
	jp BackToMain

Menu5Properties:
	ld bc,Menu5CycUp   ; [UP]
	ld bc,Menu5CycDown ; [DOWN]
	ld bc,Menu5CurLeft ; [LEFT]
	ld bc,Menu5CurRight ; [RIGHT]
	ld bc,BackToMain ; [B]
	ld bc,Menu5Perform   ; [A]
	ld bc,Menu5Constructor ; .ctor
	ld bc,Menu5Desc1 ; desc1

Menu5Constructor:
	xor a
	ld [wDebugMenuCursorPos], a ; cursor position at 0
	call MenuCursorRedraw
	ld hl,Menu5Text
	coord de, 3, 4
	call PutStringMultiline
	ld a,$f6
	ld c,$09
	coord hl, 6, 9
	call MemSet
	coord hl, 10, 9
	ld [hl],$e3
	jp Menu5Redraw

Menu5Desc1:
	db $0d,"D-PAD: Modify",$0a
	db "A Button: Corrupt",$0a
	db "B Button: Cancel",$0a
	db "[select RAM only]",$00

Menu5Text:
	db " -MemCorruptor-",$0a
	db "Hover over the",$0a
	db "dash and hold A",$0a
	db "to fuzz randomly",$00

Menu5CycUp:
	coord hl, 6, 9
	ld a, [wDebugMenuCursorPos]
	add a,l
	ld l,a
	inc [hl]
	ld a,[hl]
	cp $e4
	jr z,Menu5CycRestore
	cp $00
	jr z,Menu5CycUp_L1
	cp $86
	ret nz
	ld [hl],$f6
	ret

Menu5CycUp_L1:
	ld [hl],$80
	ret

Menu5CycRestore:
	ld [hl],$e3
	ret

Menu5CycDown:
	coord hl, 6, 9
	ld a, [wDebugMenuCursorPos]
	add a,l
	ld l,a
	dec [hl]
	ld a,[hl]
	cp $e2
	jr z,Menu5CycRestore
	cp $f5
	jr z,Menu5CycDown_L1
	cp $7f
	ret nz
	ld [hl],$ff
	ret

Menu5CycDown_L1:
	ld [hl],$85
	ret

Menu5CurLeft:
	ld hl,wDebugMenuCursorPos
	ld a,[hl]
	cp $00
	ret z
	dec [hl]
	jr Menu5Redraw

Menu5CurRight:
	ld hl,wDebugMenuCursorPos
	ld a,[hl]
	cp $08
	ret z
	inc [hl]

Menu5Redraw:
	coord hl, 6, 8
	ld a,$7f
	ld c,$9
	push hl
	call MemSet
	pop hl
	ld a, [wDebugMenuCursorPos]
	add a,l
	ld l,a
	ld [hl],$ee
	ret

Menu5RandomFuzz:
	pop hl
	pop de
	ld de,$0000 ;this will disable debounce checking, since
	push de ;every x and 0 equals 0
	pop hl
	call Random
	ld l,a
	call Random
	and $1f
	add a,$c0
	ld h,a
	call Random
	ld [hl],a
	coord hl, 10, 8
	ld a,[hl]
	cp $7f
	jr z,Menu5RandomFuzz_L1
	ld [hl],$7f
	ret

Menu5RandomFuzz_L1:
	ld [hl],$ee
	ret

Menu5Perform:
	ld a, [wDebugMenuCursorPos]
	cp $04
	jr z,Menu5RandomFuzz
	coord hl, 6, 9
	call ReadDblHexExpr
	ld d,a
	push de
	inc hl
	call ReadDblHexExpr
	pop de
	ld e,a
	inc hl
	inc hl
	push de
	call ReadDblHexExpr
	ld d,a
	push de
	inc hl
	call ReadDblHexExpr
	pop de
	ld e,a
	pop hl
	inc de

Menu5Perform_L1:
	call Random
	ld [hli], a
	ld a,h
	cp d
	jr nz,Menu5Perform_L1
	ld a,l
	cp e
	jr nz,Menu5Perform_L1
	call ConfirmSound
	jp BackToMain

Menu6Properties:
	ld bc,Menu6CursorUp   ; [UP]
	ld bc,Menu6CursorDown ; [DOWN]
	ld bc,Menu6ParamL ; [LEFT]
	ld bc,Menu6ParamR ; [RIGHT]
	ld bc,BackToMain ; [B]
	ld bc,Menu6Perform   ; [A]
	ld bc,Menu6Constructor ; .ctor
	ld bc,Menu6Desc1 ; desc1
	ld bc,Menu6Desc1 ; desc2
	ld bc,Menu6Desc1 ; desc3
	ld bc,Menu6Desc1 ; desc4
	ld bc,Menu6Desc1 ; desc5
	ld bc,Menu6Desc1 ; desc6
	ld bc,Menu6Desc1 ; desc7

Menu6Constructor:
	xor a
	ld [wDebugMenuCursorPos], a ; cursor position at 0
	ld [wDebugMenuParam], a ; param at 0
	call MenuCursorRedraw
	ld hl,Menu6Text
	coord de, 4, 4
	call PutStringMultiline
	jp Menu6Redraw

Menu6Desc1:
	db $0d,"L/R: Mod.param",$0a
	db "A Button: Accept",$0a
	db "B Button: Cancel",$0a
	db "Parameter:",$00

Menu6Text:
	db "Give ()",$0a
	db "Give item",$0a
	db "Clear () box",$0a
	db "All fly locs.",$0a
	db "Predef [7 heal]",$0a
	db "Max money",$0a
	db "Display area TX",$00

Menu6Redraw:
	ld a, [wDebugMenuParam]
	coord hl, 12, 16
	call WriteDblHexExpr
	ret

Menu6ParamL:
	ld hl,wDebugMenuParam
	ld a,[hl]
	add a,$10
	ld [hl],a
	jr Menu6Redraw

Menu6ParamR:
	ld hl,wDebugMenuParam
	inc [hl]
	jr Menu6Redraw

Menu6CursorUp:
	ld bc,Menu6Redraw
	push bc
	jp MenuCursorUp

Menu6CursorDown:
	ld bc,Menu6Redraw
	push bc
	jp MenuCursorDown

Menu6Cursor0:
	ld c,$05
	call GivePokemon
	jr Menu6Finish

Menu6Cursor1:
	ld c,$01
	call GiveItem
	jr Menu6Finish

Menu6Cursor2:
	xor a
	ld [wNumInBox], a ; da7f=0
	jr Menu6Finish

Menu6Perform:
	ld a, [wDebugMenuParam] ; load param
	ld b,a
	ld a, [wDebugMenuCursorPos] ; load cursor position
	cp $00
	jr z,Menu6Cursor0
	cp $01
	jr z,Menu6Cursor1
	cp $02
	jr z,Menu6Cursor2
	cp $03
	jr z,Menu6Cursor3
	cp $04
	jr z,Menu6Cursor4
	cp $05
	jr z,Menu6Cursor5
	jr Menu6Cursor6

Menu6Finish:
	call ConfirmSound
	jp BackToMain

Menu6Cursor3:
	xor a
	dec a
	ld hl,wTownVisitedFlag
	ld [hli], a
	ld [hl],a
	jr Menu6Finish

Menu6Cursor4:
	ld a,b
	call Predef
	jr Menu6Finish

Menu6Cursor5:
	ld hl,wPlayerMoney
	ld a,$99
	ld [hli], a
	ld [hli], a
	ld [hli], a
	jr Menu6Finish

Menu6Cursor6:
	ld a,b
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
	pop bc
	jp ReturnControlCall

Menu7Properties:
	ld bc,SwitchMenuBack   ; [UP]
	ld bc,SwitchMenuBack ; [DOWN]
	ld bc,Menu7TurnL ; [LEFT]
	ld bc,Menu7TurnR ; [RIGHT]
	ld bc,BackToMain ; [B]
	ld bc,SwitchMenuBack   ; [A]
	ld bc,Menu7Constructor ; .ctor
	ld bc,Menu7Desc1 ; desc1

Menu7Constructor:
	xor a
	ld [wDebugMenuCursorPos], a ; page at 0
	call MenuCursorRedraw
	ld hl,Menu7Text1
	coord de, 3, 4
	call PutStringMultiline
	ret

Menu7Desc1:
	db "Left/Right - page",$0a,$0a
	db "B Button: Cancel",$00

Menu7Texts:
	ld bc,Menu7Text1
	ld bc,Menu7Text2
	ld bc,Menu7Text3
	ld bc,Menu7Text4
	;   ----------------

Menu7Text1:
	db "C000: Sound I/O ",$0a
	db "C100: SpriteData",$0a
	db "CC28: Menu keys ",$0a
	db "CFC6: Battle nfo",$0a
	db "CF7A: Mart items",$0a
	db "D058: Encounter ",$0a
	db "D162: Party ()  ",$00

Menu7Text2:
	db "D31C: Item count",$0a
	db "D356: Cur badges",$0a
	db "D361: X/Y coords",$0a
	db "D36E: Map script",$0a
	db "D53A: Items box ",$0a
	db "D888: Wild data ",$0a
	db "DA80: () in box ",$00

Menu7Text3:
	db "1st () settings:",$0a
	db "D18B: Level     ",$0a
	db "D172: Moveset   ",$0a
	db "D188: PP        ",$0a
	db "D18F: Stats     ",$0a
	db "----------------",$0a
	db "D5AB: Evt flags ",$00

Menu7Text4:
	db "C3A0: ScreenData",$0a
	db "CD80: Screen buf",$0a
	db "CF4B: Last name ",$0a
	db "D05C: Team ID   ",$0a
	db "D12B: Textbox ID",$0a
	db "D157: PlayerName",$0a
	db "D349: Rival name",$00

Menu7TurnL:
	ld hl,wDebugMenuCursorPos
	ld a,[hl]
	cp $00
	ret z
	dec [hl]
	jr Menu7Redraw

Menu7TurnR:
	ld hl,wDebugMenuCursorPos
	ld a,[hl]
	cp $03
	ret z
	inc [hl]
	jr Menu7Redraw

Menu7Redraw:
	ld a,[hl]
	ld hl,Menu7Texts
	ld e,a
	add a,a
	add a,e
	inc a
	ld c,a
	ld b,$00
	add hl,bc
	ld a,[hl]
	ld e,a
	inc hl
	ld a,[hl]
	ld h,a
	ld l,e
	coord de, 3, 4
	jp PutStringMultiline

MenuCursorUp:
	ld hl,wDebugMenuCursorPos
	ld a,[hl]
	cp $00
	ret z
	dec [hl]
	call MenuCursorRedraw
	ret

MenuCursorDown:
	ld hl,wDebugMenuCursorPos
	ld a, [wDebugMenuID]
	swap a
	xor [hl]
	cp $06
	ret z
	cp $34
	ret z
	cp $56
	ret z
	inc [hl]
	call MenuCursorRedraw
	ret

MenuCursorRedraw:
	call DrawBottomBox
	coord hl, 3, 4
	ld d,h
	ld e,l
	push hl
	ld bc,$0014
	push bc
	ld hl,MenuCursorRedrawStr
	call PutStringMultiline
	pop bc
	pop hl
	ld a, [wDebugMenuCursorPos]
	push af

MenuCursorRedraw_L1:
	cp $00
	jr z,MenuCursorRedraw_L2
	add hl,bc
	dec a
	jr nz,MenuCursorRedraw_L1

MenuCursorRedraw_L2:
	ld [hl],$ed
	ld a, [wDebugMenuID]
	ld c,a
	add a,a
	add a,c
	ld c,a
	ld b,$00
	ld hl,MenuList
	add hl,bc
	inc hl
	ld e,[hl]
	inc hl
	ld d,[hl]
	ld h,d
	ld l,e
	ld bc,$0016
	pop af
	ld d,a
	add a,a
	add a,d
	add a,c
	ld c,a
	add hl,bc
	ld e,[hl]
	inc hl
	ld d,[hl]
	ld h,d
	ld l,e
	coord de, 1, 14
	call PutStringMultiline
	ret

MenuCursorRedrawStr:
	db $7f,$0a,$7f,$0a,$7f,$0a,$7f,$0a,$7f,$0a,$7f,$0a,$7f,$00
