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
		action() { replaceAction(Draw, deck); }
	}
	dobjFor(DrawCount) {
		verify() { dangerous; }
		action() {
			replaceActionWithCount(DrawCount, deck);
		}
	}
;

startRoom: Room 'Void' "This is a featureless void. ";
+me: Person;
+deck: Thing 'deck (of) (card)/cards' 'deck of cards'
	"It's a deck of playing cards. "
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
++CardUnthing;
