RedsHouse1F_Script:
	jp EnableAutoTextBoxDrawing

RedsHouse1F_TextPointers:
	dw RedsHouse1FMomText
	dw RedsHouse1FTVText

RedsHouse1FMomText:
	text_asm
	ld a, [wd72e]
	bit 3, a ; received a Pokémon from Oak?
	jr nz, .heal
	ld a, [wPlayerGender]
	and a
	jr nz, .girl
	ld hl, MomWakeUpText
	call PrintText
	jr .done
.girl
    ld hl,MomWakeUpText2
    call PrintText
    jr .done
.heal
	call MomHealPokemon
.done
	jp TextScriptEnd

MomWakeUpText:
	text_far _MomWakeUpText
	text_end
MomWakeUpText2:
    text_far _MomWakeUpText2
    text_end

MomHealPokemon:
	ld hl, MomHealText1
	call PrintText
	call GBFadeOutToWhite
	call ReloadMapData
	predef HealParty
	ld a, MUSIC_PKMN_HEALED
	ld [wNewSoundID], a
	call PlaySound
.next
	ld a, [wChannelSoundIDs]
	cp MUSIC_PKMN_HEALED
	jr z, .next
	ld a, [wMapMusicSoundID]
	ld [wNewSoundID], a
	call PlaySound
	call GBFadeInFromWhite
	ld hl, MomHealText2
	jp PrintText

MomHealText1:
	text_far _MomHealText1
	text_end
MomHealText2:
	text_far _MomHealText2
	text_end

RedsHouse1FTVText:
	text_asm
	ld a, [wSpritePlayerStateData1FacingDirection]
	cp SPRITE_FACING_UP
	ld hl, TVWrongSideText
	jr nz, .got_text
	ld a, [wPlayerGender]
	and a
	jr nz, .girl2
	ld hl, StandByMeText
	call PrintText
	jr .done
.girl2
    ld hl,WizOfOzText
    call PrintText
    jr .done
.got_text
	call PrintText
	jp TextScriptEnd
.done
    jp TextScriptEnd

StandByMeText:
	text_far _StandByMeText
	text_end

WizOfOzText:
    text_far _WizOfOzText
    text_end

TVWrongSideText:
	text_far _TVWrongSideText
	text_end
