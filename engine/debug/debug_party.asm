SetGodmodeTeam:
	ld de, GodmodeTeam
.loop
	ld a, [de]
	cp -1
	ret z
	ld [wcf91], a
	inc de
	ld a, [de]
	ld [wCurEnemyLVL], a
	inc de
	push de                ; preserve our GodmodeTeam read pointer across
	                        ; AddPartyMon and our own nickname-writing below
	call AddPartyMon
	; _AddPartyMon skips the "give a nickname?" prompt whenever
	; wMonDataLocation != 0 (see DebugStart, which deliberately sets it to
	; $10 to skip exactly this), but skipping the prompt also skips the
	; only code that ever writes a nickname at all -- there's no fallback
	; to the species name elsewhere, so without this the mon has no name
	; whatsoever. Write the default species name as the nickname ourselves.
	ld hl, wPartyMonNicks
	ldh a, [hNewPartyLength]
	dec a
	push af
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, GodmodeNames
	pop af
	call SkipFixedLengthTextEntries
	ld bc, NAME_LENGTH
	call CopyData
	pop de
	jr .loop
	
GodmodeTeam:
	db MEW, 5
	db VULPIX, 5
	db PIKACHU, 5
	db MEWTWO, 5
	db ARTICUNO, 5
	db -1

GodmodeNames:
	db "MEW@@@@@@@@"
	db "VULPIX@@@@@"
	db "PIKACHU@@@@"
	db "MEWTWO@@@@@"
	db "ARTICUNO@@@"

DebugStart:
IF DEF(_DEBUG)
	ld a, $10 ; still player's party (low nybble 0), but nonzero overall so
	          ; _AddPartyMon skips the "give a nickname?" prompt for all 5
	          ; Godmode team members -- the starter you pick afterward at
	          ; Oak's Lab is unaffected, since that's a separate code path
	          ; that sets wMonDataLocation to true 0 itself
	ld [wMonDataLocation], a
	
	call SetGodmodeTeam
	
	ld hl, wPartyMon1Moves
	ld a, FLY
	ld [hli], a
	ld a, CUT
	ld [hli], a
	ld a, SURF
	ld [hli], a
	ld a, STRENGTH
	ld [hl], a
	ld hl, wPartyMon1PP
	ld a, 15
	ld [hli], a
	ld a, 30
	ld [hli], a
	ld a, 15
	ld [hli], a
	ld [hl], a

	; Fly anywhere.
	dec a ; $ff
	ld [wTownVisitedFlag], a
	ld [wTownVisitedFlag + 1], a

	; Get all badges except Earth Badge.
	ld a, $ff ^ (1 << BIT_EARTHBADGE)
	ld [wObtainedBadges], a

	; Set text speed to Fast, preserving the battle style/animation bits
	; (upper nybble of wOptions) rather than overwriting the whole byte.
	ld a, [wOptions]
	and $f0
	or 1 ; text speed: 1 = Fast, 3 = Medium, 5 = Slow
	ld [wOptions], a

	; Get some debug items.
	ld hl, wNumBagItems
	ld de, DebugItemsList
.items_loop
	ld a, [de]
	cp -1
	jr z, .items_end
	ld [wcf91], a
	inc de
	ld a, [de]
	inc de
	ld [wItemQuantity], a
	call AddItemToInventory
	jr .items_loop
.items_end

	; Rival chose Squirtle,
	; Player chose Charmander.
	ld hl, wRivalStarter
	ld a, STARTER2
	ld [hli], a
	inc hl ; hl = wPlayerStarter
	ld a, STARTER1
	ld [hl], a

	ret

DebugItemsList:
    db DEBUG, 1
	db BICYCLE, 1
	db FULL_RESTORE, 99
	db FULL_HEAL, 99
	db ESCAPE_ROPE, 99
	db RARE_CANDY, 99
	db MASTER_BALL, 99
	db TOWN_MAP, 1
	db SECRET_KEY, 1
	db CARD_KEY, 1
	db S_S_TICKET, 1
	db LIFT_KEY, 1
	db -1 ; end

DebugUnusedList:
	db -1 ; end
ELSE
	ret
ENDC

