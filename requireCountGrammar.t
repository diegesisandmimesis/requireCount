#charset "us-ascii"
//
// requireCountGrammar.t
//
//	Grammar rules and production classes.
//
//
#include <adv3.h>
#include <en_us.h>

#include "requireCount.h"

// Class for TActions with required counts.
class TActionWithCount: TAction
	// If true, then the action will fail if there aren't enough
	// in-game objects to cover the count.
	requireRealCount = nil

	// If true, the dobjList will be truncated to a single object.
	// The full original list will always be saved as savedDobjList
	// regardless of this value.
	truncateDobjList = true

	// Base production to use for handling missing dobjs.
	askDobjResponseProd = _nounListWithCount

	// Saved copy of the dobjList_ before truncation.
	// Maybe a misfeature, see discussion below.
	savedDobjList = nil

	resolveNouns(srcActor, dstActor, results) {
		local n;

		// Do whatever we'd normally do.
		inherited(srcActor, dstActor, results);

		// Various ways we might get our count out of the grammar.
		if(dobjMatch && dobjMatch.num_) {
			n = dobjMatch.num_.getval();
		} else if(numMatch == nil) {
			n = dobjList_.length;
		} else {
			n = gActionCount;
		}

		// If we got a count above, try to remember it.
		if(n != nil) {
			numMatch = new NumberProd();
			numMatch.getval = n;
		}

		// Maybe a misfeature.  Here we truncate our dobj list
		// so we only "really" apply to one of them.
		// This is done in the assumption that a)  the actions we
		// care about only want to output once, regardless of
		// how many objects they're referring to, and b)  the objects
		// aren't necessarily going to be pre-existing simulation
		// objects (and if they are, they're probably all
		// indistinguishable).
		// So the model is that the action handler on the object
		// is going to get the count and do whatever it wants to do
		// independent of how the *parser* has decided to resolve
		// the nouns (i.e., if we're implementing a bucket of
		// infinite pebbles and the player tries to >TAKE 10 PEBBLES,
		// in the action handler we care about the number and the
		// object type, but we don't care about whether or not
		// the parser managed to map the noun phrase to a list of
		// ten in-game pebbles).
		// If we DO care about that, the savedDobjList property will
		// retain whatever the parser DID manage to work out.
		if(dobjList_ && dobjList_.length) {
			savedDobjList = dobjList_;
			if(truncateDobjList)
				dobjList_ = [ dobjList_[1] ];
		}
	}
;

//
// Numeric count grammar.
// Used by all the other count grammar rules.
//

// Production classes for the grammar rules below.
class LiteralCountProd: NumberProd;
class EmptyLiteralPhraseWithCountProd: EmptyLiteralPhraseProd;

// Empty count.
grammar nounCount(empty): [badness 400] : EmptyLiteralPhraseWithCountProd;

// Numeric count.
grammar nounCount(digits): tokInt->num_ : LiteralCountProd
	getval() { return(toInteger(num_)); }
	getStrVal() { return(num_); }
;

// Spelled-out count.
grammar nounCount(spelled): spelledNumber->num_ : LiteralCountProd
	getval() { return num_.getval(); }
;



//
// Noun list grammar.
// Used by VerbRules that use dobjListWithCount.
//

// Class for the grammar rules that follow.
class NounListWithCountProd: NounListProd
	resolveNouns(resolver, results) {
		return(np_.resolveNouns(resolver, results));
	}
;

// Matches [count] [noun phrase].
grammar _nounListWithCount(count):
	(nounCount->num_ indetSingularNounPhrase->np_)
	| (nounCount->num_ indetPluralNounPhrase->np_)
	: NounListWithCountProd;

// Matches an empty noun phrase.
grammar _nounListWithCount(empty): [badness 500] : EmptyNounPhraseProd;



//
// Noun grammar.
// This is for VerbRule declarations that use singleDobjWithCount
//

// Class for the grammar rules below.
class LayeredNounPhraseWithCountProd: LayeredNounPhraseProd
	resolveNouns(resolver, results) {
		return(np_.resolveNouns(resolver, results));
	}
;

// Matches a count followed by a single noun.
grammar _nounWithCount(count):
	nounCount->num_ singleNounOnly->np_
	: LayeredNounPhraseWithCountProd;

// Matches an empty noun phrase.
grammar _nounWithCount(empty): [badness 500] : EmptyNounPhraseProd;
