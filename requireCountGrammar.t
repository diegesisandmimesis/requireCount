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

class TActionWithCount: TAction
	useDobjListForCount = true

	askDobjResponseProd = nounListWithCount

	resolveNouns(srcActor, dstActor, results) {
		inherited(srcActor, dstActor, results);

		if(useDobjListForCount != true)
			return;

		if(!dobjList_ || !dobjList_.length)
			return;

		numMatch = new NumberProd();
		numMatch.getval = dobjList_.length;
		dobjList_ = [ dobjList_[1] ];
	}
;

grammar nounCount(empty): [badness 400] : EmptyLiteralPhraseWithCountProd;

grammar nounCount(digits): tokInt->num_ : LiteralCountProd
	getval() { return(toInteger(num_)); }
	getStrVal() { return(num_); }
;

grammar nounCount(spelled): spelledNumber->num_ : LiteralCountProd
	getval() { return num_.getval(); }
;

class LiteralCountProd: NumberProd;
class EmptyLiteralPhraseWithCountProd: EmptyLiteralPhraseProd;

grammar nounListWithCount(count):
	(nounCount->num_ indetSingularNounPhrase->np_)
	| (nounCount->num_ indetPluralNounPhrase->np_)
	: NounListWithCountProd;

class NounListWithCountProd: NounListProd
	resolveNouns(resolver, results) {
		return(np_.resolveNouns(resolver, results));
	}
;
