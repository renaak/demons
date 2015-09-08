	;*****************************************************************
	; initialize enemies
	;*****************************************************************

init_enemies:
	; clear monsters
	ldx #MAX_ENEMIES*2
	lda #0
@clear:	sta ENEMY_X-1,x
	dex
	bne @clear

	lda DUNGEON_LEVEL
	lsr
	clc
	adc #4
	sta $0			; $0 = spawn count = level/2 + 4
@loop:	jsr randomloc
	jsr move
	; store x,y to enemy table
	ldx $0			; X = monster index (1-based)
	tya
	sta ENEMY_X-1,x
	lda CURSOR_Y
	sta ENEMY_Y-1,x
	tax
	;
	jsr rand8
	and #7
	clc
	adc DUNGEON_LEVEL
	tay
	dey			; Y = rand8 & 7 + level - 1
	lda spawns,y
	jsr CHROUT

@skip:	dec $0
	bne @loop
	rts

	;*****************************************************************
	; update enemies
	;*****************************************************************

update_enemies:
	lda #MAX_ENEMIES-1
	sta $0			; $0 = counter
@loop:	ldy $0
	ldx ENEMY_Y,y		; X = row
	beq @skip		; skip if enemy slot unused
	lda ENEMY_X,y
	tay			; Y = column
	jsr move
	lda (COLOR_PTR),y
	and #7
	cmp #COLOR_UNSEEN
	beq @skip		; skip unseen enemies
	ldx #1			; move right
	jsr move_enemy
@skip:	dec $0
	bpl @loop
	rts

	;*****************************************************************
	; moves enemy at cursor towards a direction, in:
	; cursor at enemy
	; $0 = enemy
	;  X = direction (0=up, 1=right, 2=down, 3=left)
	;*****************************************************************

move_enemy:
	; check obstacles
	lda @curs1,x		; move cursor to target
	jsr CHROUT
	ldy CURSOR_X
	lda (LINE_PTR),y
	cmp #SCR_FLOOR
	bne @done		; blocked
	lda (COLOR_PTR),y
	and #7
	cmp #COLOR_UNSEEN
	beq @done		; can't move to unseen cells
	; update enemy coords
	tya
	ldy $0
	sta ENEMY_X,y
	lda CURSOR_Y
	sta ENEMY_Y,y
	; move cursor back
	lda @curs2,x
	jsr CHROUT
	; save old char and color
	ldy CURSOR_X
	lda (LINE_PTR),y	
	pha			; save char
	lda (COLOR_PTR),y
	pha			; save color
	; clear monster
	lda #SCR_FLOOR
	sta (LINE_PTR),y
	lda #COLOR_EXPLORED
	sta (COLOR_PTR),y
	; draw monster
	lda @curs1,x		; move cursor to target
	jsr CHROUT
	pla			; restore color
	sta CUR_COLOR
	pla			; restore char
	ora #64
	jsr CHROUT
@done:	rts

@curs1:	.byte CHR_UP,CHR_RIGHT,CHR_DOWN,CHR_LEFT
@curs2:	.byte CHR_DOWN,CHR_LEFT,CHR_UP,CHR_RIGHT

	;*****************************************************************
	; remove enemy at row X, column Y
	;*****************************************************************

remove_enemy:
	lda #COLOR_EXPLORED
	sta CUR_COLOR
	lda #CHR_FLOOR
	jsr plot
	jsr enemy_at
	lda #0
	sta ENEMY_X,x
	sta ENEMY_Y,x
	rts

	;*****************************************************************
	; returns enemy at row X, column Y, out: X = enemy index
	;*****************************************************************

enemy_at:
	stx $0
	sty $1
	ldx #MAX_ENEMIES-1
@loop:	lda ENEMY_Y,x
	cmp $0
	bne @next
	lda ENEMY_X,x
	cmp $1
	bne @next
	rts			; enemy found
@next:	dex
	bpl @loop
	; monster not found -> error
	.if 1
@err:	inc $900f
	jmp @err
	.endif

	;*****************************************************************
	; data
	;*****************************************************************

	; random spawns, indexed with rand8() & 7 + level - 1
spawns:	.byte CHR_BAT,CHR_RAT,CHR_RAT,CHR_RAT,CHR_BAT,CHR_BAT,CHR_SNAKE
	.byte CHR_RAT,CHR_SNAKE,CHR_SNAKE,CHR_BAT,CHR_RAT,CHR_UNDEAD,CHR_UNDEAD
	.byte CHR_ORC,CHR_ORC,CHR_UNDEAD,CHR_STALKER,CHR_UNDEAD,CHR_STALKER,CHR_SNAKE
	.byte CHR_ORC,CHR_SLIME,CHR_WIZARD,CHR_WIZARD