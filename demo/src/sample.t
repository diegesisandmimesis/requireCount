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

// Stock messages for our new actions.
modify playerActionMessages
	// Generic failure message for >DRAW
	cantDrawThat = '{You/He} can\'t draw {that dobj/him}. '

	// Success message for >DRAW CARDS
	okayDrawCards(n) {
		return('{You/He} draw{s} <<spellInt(n)>> card<<((n == 1)
			? '' : 's')>>. ');
	}

	// Generic failure message for >FOOZLE
	cantFoozleThat = '{You/He} can\'t foozle that. '

	okayFoozle(n, obj) {
		return('{You/He} foozle{s} <<spellInt(n)>>
			<<(n != 1) ? obj.pluralName : obj.name>>. ');
	}
;

// First, a TActionWithCount that DOES NOT rely on the actual
// object count.
// In this case the "cards" are just a bookkeeping thing, not objects
// that are individually modelled in-game.
// So we define a deck we can draw cards from, but we can draw 20 cards
// despite there only being a single card Unthing there to handle the
// vocabulary.
DefineTActionWithCount(Draw);
VerbRule(Draw)
	// IMPORTANT:  We use singleDobjWithCount.  In general this
	//	is what you want to use when the objects the account
	//	applies to are "virtual".  In this case there's a single
	//	in-game object that "cards" applies to, but we want
	//	something like >DRAW 10 CARDS to still work.
	'draw' singleDobjWithCount
	: DrawAction
	verbPhrase = 'draw/drawing (what)'
;

// Default handler for the new verb.
modify Thing dobjFor(Draw) { verify() { illogical(&cantDrawThat); } };

// Not actually used in this demo.
class Card: Thing '(blank) playing card' 'playing card'
	"A blank playing card. "
	isEquivalent = true
;

// Unthing for handling vocabulary associated with individual playing
// cards.  In our case this is specifically for >DRAW CARD.
// Main thing that we do is catch the action and remap it to >DRAW CARDS
// where "cards" will be the plural Unthing living in the deck object.
class CardsUnthing: Unthing '(playing) card*cards' 'card'
	// As a simulation object, our cards are just barely implemented.
	notHereMsg = 'The only thing you can do with the cards is
		<b>&gt;DRAW</b> them. '

	dobjFor(Draw) {
		verify() { dangerous; }
		action() {
			// Macro to handle displaying the "How many?" question
			// prompt and parsing the player response.
			requireCount;

			// The way requireCount works we know that if we've
			// reached this point we'll have a numMatch to use.
			defaultReport(&okayDrawCards, gActionCount);
		}
	}
;

// A generic action with a count.
DefineTActionWithCount(Foozle);
VerbRule(Foozle)
	// This time we use dobjListWithCount.  This is for when we
	// want the count for the action to correspond to the number of
	// in-game objects available.
	'foozle' dobjListWithCount
	: FoozleAction
	verbPhrase = 'foozle/foozling (what)'
;

// Generic handler for >FOOZLE.
modify Thing dobjFor(Foozle) { verify() { illogical(&cantFoozleThat); } };

// A class for objects that accept >FOOZLE.
class FoozleThing: Thing
	dobjFor(Foozle) {
		verify() {}
		action() {
			// More or less identical to the >DRAW example
			// above.
			requireCount;
			defaultReport(&okayFoozle, gActionCount, self);
		}
	}
;

// Our >FOOZLE-able objects.
class Pebble: FoozleThing '(small) (round) pebble*pebbles' 'pebble'
	"A small, round pebble. "
	isEquivalent = true
;

class Rock: FoozleThing '(ordinary) rock*rocks' 'rock'
	"An ordinary rock. "
	isEquivalent = true
;

startRoom: Room 'Void' "This is a featureless void. ";
+me: Person;
+deck: Thing '(card) (cards) (of) deck' 'deck of cards'
	"It's a deck of playing cards. "

	cards = (contents.valWhich({ x: x.ofKind(CardsUnthing) }))

	dobjFor(Draw) {
		verify() { dangerous; }
		action() { replaceActionWithCount(Draw, deck.cards); }
	}
;
++CardsUnthing;
+Pebble;
+Pebble;
+Pebble;
+Rock;
+Rock;
+Rock;
