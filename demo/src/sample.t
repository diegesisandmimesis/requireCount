#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the requireCount library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "requireCount.h"

versionInfo: GameID;
gameMain: GameMainDef initialPlayerChar = me;

DefineTAction(Draw);
VerbRule(Draw)
	'draw' singleDobj : DrawAction
	verbPhrase = 'draw/drawing (what)'
;

DefineTAction(DrawCount);
VerbRule(DrawCount)
	'draw' singleNumber dobjList : DrawCountAction
	verbPhrase = 'draw/drawing (what)'
;

modify Thing
	dobjFor(Draw) {
		verify() {
			illogical('{You/He} can\'t draw {that dobj/him}. ');
		}
	}
	dobjFor(DrawCount) { action() { replaceAction(Draw, self); } }
;

class Card: Thing '(blank) playing card' 'playing card'
	"A blank playing card. "
	isEquivalent = true
;

class CardUnthing: Unthing '(single) (individual) playing card' 'card'
	notHereMsg = 'Nope. '
	dobjFor(Draw) {
		verify() { dangerous; }
		action() { replaceAction(Draw, deck.cards); }
	}
	dobjFor(DrawCount) {
		verify() { dangerous; }
		action() {
			replaceActionWithCount(DrawCount, deck.cards);
		}
	}
;

class CardsUnthing: CardUnthing 'playing cards' 'cards'
	isPlural = true
	dobjFor(Draw) {
		verify() {}
		action() { replaceAction(DrawCount, self); }
	}
	dobjFor(DrawCount) {
		verify() {}
		action() {
			local n;

			requireCount;

			n = gAction.numMatch.getval();
			defaultReport('{You/He} draw{s} <<spellInt(n)>>
				card<<((n == 1) ? '' : 's')>>. ');
		}
	}
;

startRoom: Room 'Void' "This is a featureless void. ";
+me: Person;
+deck: Thing 'deck (of) (card)/cards' 'deck of cards'
	"It's a deck of playing cards. "
	cards = (contents.valWhich({ x: x.ofKind(CardsUnthing) }))
	dobjFor(Draw) {
		verify() { }
		action() { replaceAction(Draw, cards); }
	}
	dobjFor(DrawCount) {
		verify() { }
		action() {
			replaceActionWithCount(DrawCount, deck.cards);
		}
	}
;
++CardUnthing;
++CardsUnthing;
+pebble: Thing '(small) (round) pebble*pebbles' 'pebble'
	"A small, round pebble. "
	dobjFor(Foozle) {
		verify() {}
		action() {
			requireCount;
			defaultReport('{You/He} foozle{s}
				<<spellInt(gActionCount)>> pebbles. ');
		}
	}
;
+rock: Thing '(ordinary) rock' 'rock'
	"An ordinary rock. "
	dobjFor(Foozle) {
		verify() {}
		action() {
			requireCount;
			defaultReport('{You/He} foozle{s}
				<<spellInt(gActionCount)>> pebbles. ');
		}
	}
;


DefineTAction(Foozle);
/*
DefineTActionWithCount(Foozle);
VerbRule(FoozleWithoutCount)
	'foozle' dobjList
	: FoozleWithoutCountAction
	verbPhrase = 'foozle/foozling (what)'
;
*/
VerbRule(Foozle)
	'foozle' literalCount dobjList
	: FoozleAction
	verbPhrase = 'foozle/foozling (what)'
;

modify Thing
	dobjFor(Foozle) {
		verify() { illogical('{You/He} can\'t foozle that. '); }
	}
;

