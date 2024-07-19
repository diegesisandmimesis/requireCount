#charset "us-ascii"
//
// bucketTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the requireCount library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f bucketTest.t3m
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

// A >TAKE command with a count, for a dispenser-type thing.
DefineTActionWithCount(TakeCount);
VerbRule(TakeCount)
	'take' dobjListWithCount
	: TakeCountAction
	verbPhrase = 'take/taking (what)'
;

// By default, treat TakeCount like Take.
modify Thing
	dobjFor(TakeCount) { action() { replaceAction(Take, self); } }
;

// Pebble class.  Just something to take.
class Pebble: Thing '(small) (round) pebble*pebbles' 'pebble'
	"A small, round pebble. "
	isEquivalent = true
;

startRoom: Room 'Void' "This is a featureless void. ";
+me: Person;
// A bucket.  Despite the name, it's not a container.
+bucket: Thing '(of) (infinite) (pebbles) bucket' 'bucket of infinite pebbles'
	"It's a bucket containing infinite pebbles. "
	iobjFor(PutIn) {
		verify() {
			illogical('{You/He} can\'t put anything in the
				bucket, it\'s already full of an infinite
				number of pebbles. ');
		}
	}
;
++Component 'pebble*pebbles' 'pebbles'
	"They're infinite. "
	dobjFor(Take) {
		verify() {}
		action() { replaceAction(TakeCount, self); }
	}
	dobjFor(TakeCount) {
		action() {
			local i, n, obj;

			requireCount;

			n = gActionCount;
			for(i = 0; i < n; i++) {
				obj = Pebble.createInstance();
				obj.moveInto(gActor);
			}
			defaultReport('{You/He} take{s} <<spellInt(n)>>
				pebble<<(n == 1) ? '' : 's'>>. ');
		}
	}
;
