; Address-to-label lookup used by the debug menu's Hex Viewer, so it can show
; what a memory address actually is instead of just its raw hex digits. Small
; curated table, linear-scanned (41 entries is fast enough that a fancier
; search isn't worth the added risk). Lives in its own bank since bank 46 was
; sitting completely empty.
SECTION "Debug Address Labels", ROMX, BANK[46]

NUM_DEBUG_ADDR_LABELS EQU 41

; wPlayerMoney and casino coins are stored as BCD -- each byte's two nibbles
; are two decimal digits directly, not a plain binary value. Showing them
; through the normal decimal byte-conversion path would print a number that
; has nothing to do with the actual amount, so they get a dedicated check
; that decodes and displays the real value instead.
MONEY_BASE_ADDR EQU $D347
COINS_BASE_ADDR EQU $D5A4

; in: de = base address of the currently visible 28-byte window (7 rows x 4
;     bytes), d = hi byte, e = lo byte
; out: hl = pointer to a null-terminated label string (always valid -- falls
;      back to a generic message if nothing in the visible range matches)
;
; Checks every one of the 28 visible bytes, not just the top-left address.
; That matters a lot here: the Hex Viewer's own D-pad controls only ever move
; the low byte in steps of 16, so the top-left address can only land on
; values ending in 0 -- meaning almost none of this table's real addresses
; (most of which don't end in 0) could ever be matched if only the top-left
; byte were checked, even when clearly visible elsewhere in the same grid.
FindDebugAddrLabel::
	ld b, 28 ; 7 rows x 4 bytes each -- back to hex display in the grid itself,
	         ; so back to the original row width. Labels and the Money/Coins
	         ; BCD decode below are unaffected either way -- they scan live
	         ; bytes directly and don't care what format the grid shows.
	call CheckBcdFieldsInView
	ret c ; already handled -- hl = wDebugAddrLabelBuf, filled and ready
.rangeLoop
	push bc
	push de
	call FindExactAddrLabel
	pop de
	pop bc
	ld a, h
	or l
	jr nz, .rangeFound ; a non-zero hl means FindExactAddrLabel found a real match
	inc de
	dec b
	jr nz, .rangeLoop
	ld hl, DebugNoLabelText
	jr .copyToWram
.rangeFound
	; fall through
.copyToWram
	; hl currently points into this routine's own bank (46), which is about to
	; stop being valid the moment Bankswitch restores the caller's original
	; bank on return. Copy the string into a fixed WRAM buffer first, and
	; hand back a pointer to *that* instead -- WRAM reads correctly no matter
	; which ROM bank is active.
	ld de, wDebugAddrLabelBuf
.copyLoop
	ld a, [hli]
	ld [de], a
	inc de
	and a
	jr nz, .copyLoop
	ld hl, wDebugAddrLabelBuf
	ret

; in: de = exact address to look up
; out: hl = pointer to the label string in this bank if found, or hl=0 if not
;      (0 is never a valid label pointer, so it's safe to use as a sentinel)
; in: de = window base, b = window length
; out: if either BCD field's base address is in the window: carry SET, and
;      hl = wDebugAddrLabelBuf, already filled with the decoded value
;      if neither is: carry CLEAR, de and b left exactly as given
CheckBcdFieldsInView:
	push de
	push bc
	ld hl, MONEY_BASE_ADDR
	call .addrInWindow
	pop bc
	pop de
	jr c, .foundMoney
	push de
	push bc
	ld hl, COINS_BASE_ADDR
	call .addrInWindow
	pop bc
	pop de
	jr c, .foundCoins
	scf
	ccf ; carry clear, cleanly, without disturbing anything else
	ret

.foundMoney
	ld hl, wDebugAddrLabelBuf
	ld de, DebugMoneyPrefix
	call .copyPrefix
	ld a, [MONEY_BASE_ADDR]
	call WriteBcdDigits
	ld a, [MONEY_BASE_ADDR+1]
	call WriteBcdDigits
	ld a, [MONEY_BASE_ADDR+2]
	call WriteBcdDigits
	xor a
	ld [hl], a
	ld hl, wDebugAddrLabelBuf
	scf
	ret

.foundCoins
	ld hl, wDebugAddrLabelBuf
	ld de, DebugCoinsPrefix
	call .copyPrefix
	ld a, [COINS_BASE_ADDR]
	call WriteBcdDigits
	ld a, [COINS_BASE_ADDR+1]
	call WriteBcdDigits
	xor a
	ld [hl], a
	ld hl, wDebugAddrLabelBuf
	scf
	ret

; in: hl = dest, de = null-terminated source string
; out: hl advances past the copied text (not including the terminator)
; clobbers: a, de
.copyPrefix
	ld a, [de]
	and a
	ret z
	ld [hli], a
	inc de
	jr .copyPrefix

; in: hl = target address to test, de = window base, b = window length
; out: carry SET if hl is within [de, de+b), else carry CLEAR
; clobbers: a, c
.addrInWindow:
	ld a, l
	sub e
	ld c, a
	ld a, h
	sbc a, d
	and a
	ret nz
	ld a, c
	cp b
	ret

; in: a = a BCD byte (each nibble is a decimal digit 0-9), hl = destination
; out: writes 2 decimal digit characters to [hl], hl advances by 2
; clobbers: a, b -- deliberately not d or e, same reasoning as WriteDecExpr
WriteBcdDigits:
	ld b, a
	swap a
	and $0f
	add $f6
	ld [hli], a
	ld a, b
	and $0f
	add $f6
	ld [hli], a
	ret

DebugMoneyPrefix: db "Money:",0
DebugCoinsPrefix: db "Coins:",0

FindExactAddrLabel:
	ld hl, DebugAddrLabelTable
	ld c, NUM_DEBUG_ADDR_LABELS
.loop
	ld a, c
	and a
	jr z, .noMatch
	ld a, [hl]
	inc hl
	cp e
	jr nz, .skip
	ld a, [hl]
	cp d
	jr z, .found
.skip
	inc hl ; past the hi byte (whether we peeked at it above or not)
	inc hl ; past the label pointer (2 bytes)
	inc hl
	dec c
	jr .loop
.found
	inc hl ; past the hi byte
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret
.noMatch
	ld hl, 0
	ret

DebugNoLabelText:
	db "(no label)",0

DebugAddrLabelTable:
	dw $D347, .label0
	dw $D356, .label1
	dw $D31D, .label2
	dw $D31E, .label3
	dw $D361, .label4
	dw $D362, .label5
	dw $D35E, .label6
	dw $D36E, .label7
	dw $D163, .label8
	dw $D16B, .label9
	dw $D16C, .label10
	dw $D18C, .label11
	dw $D16F, .label12
	dw $D173, .label13
	dw $D18D, .label14
	dw $D18F, .label15
	dw $D191, .label16
	dw $D193, .label17
	dw $D195, .label18
	dw $D188, .label19
	dw $D355, .label20
	dw $D358, .label21
	dw $D359, .label22
	dw $D127, .label23
	dw $DA80, .label24
	dw $D53A, .label25
	dw $D2F7, .label26
	dw $D30A, .label27
	dw $D888, .label28
	dw $D126, .label29
	dw $C100, .label30
	dw $CC28, .label31
	dw $CFC6, .label32
	dw $CD6B, .label33
	dw $D732, .label34
	dw $FFFC, .label35
	dw $D747, .label36
	dw $D5A6, .label37
	dw $D34A, .label38
	dw $D158, .label39
	dw $D367, .label40

.label0: db "wPlayerMoney",0
.label1: db "wObtainedBadges",0
.label2: db "wNumBagItems",0
.label3: db "wBagItems",0
.label4: db "wYCoord",0
.label5: db "wXCoord",0
.label6: db "wCurMap",0
.label7: db "wMapScriptPtr",0
.label8: db "wPartyCount",0
.label9: db "wPartyMon1Species",0
.label10: db "wPartyMon1HP",0
.label11: db "wPartyMon1Level",0
.label12: db "wPartyMon1Status",0
.label13: db "wPartyMon1Moves",0
.label14: db "wPartyMon1MaxHP",0
.label15: db "wPartyMon1Attack",0
.label16: db "wPartyMon1Defense",0
.label17: db "wPartyMon1Speed",0
.label18: db "wPartyMon1Special",0
.label19: db "wPartyMon1PP",0
.label20: db "wOptions",0
.label21: db "wLetterPrintDelay",0
.label22: db "wPlayerID",0
.label23: db "wCurEnemyLVL",0
.label24: db "wNumInBox",0
.label25: db "wNumBoxItems",0
.label26: db "wPokedexOwned",0
.label27: db "wPokedexSeen",0
.label28: db "wGrassMons",0
.label29: db "wMapScriptFlags",0
.label30: db "wSpriteStateData1",0
.label31: db "wMaxMenuItem",0
.label32: db "wTileInFront",0
.label33: db "wJoyIgnore",0
.label34: db "wd732(GodMode)",0
.label35: db "hAntiCrashBuffer",0
.label36: db "wEventFlags",0
.label37: db "wMissableObjFlags",0
.label38: db "wRivalName",0
.label39: db "wPlayerName",0
.label40: db "wCurMapTileset",0
