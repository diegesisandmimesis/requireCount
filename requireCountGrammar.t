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
	askDobjResponseProd = _nounListWithCount

	savedDobjList = nil

	resolveNouns(srcActor, dstActor, results) {
		local n;

		inherited(srcActor, dstActor, results);

		if(dobjMatch && dobjMatch.num_) {
			n = dobjMatch.num_.getval();
aioSay('\ndobjMatch = <<toString(n)>>\n ');
		} else if(numMatch == nil) {
			n = dobjList_.length;
aioSay('\ndobjList_ = <<toString(n)>>\n ');
		} else {
			n = gActionCount;
aioSay('\nactionCount = <<toString(n)>>\n ');
		}

		if(n != nil) {
			numMatch = new NumberProd();
			numMatch.getval = n;
		}

/*
if(numMatch.getval && dobjList_ && (dobjList_.length < numMatch.getval)) {
	results.insufficientQuantity(getDobjInfo().np_.getOrigText(), dobjList_, numMatch.getval());
}
*/
		if(dobjList_ && dobjList_.length) {
			savedDobjList = dobjList_;
			dobjList_ = [ dobjList_[1] ];
		}
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

grammar _nounListWithCount(count):
	(nounCount->num_ indetSingularNounPhrase->np_)
	| (nounCount->num_ indetPluralNounPhrase->np_)
	: NounListWithCountProd;

grammar _nounListWithCount(empty): [badness 500] : EmptyNounPhraseProd;

grammar _nounWithCount(count):
	nounCount->num_ singleNounOnly->np_
	//nounCount->num_ indetSingularNounPhrase->np_
	: LayeredNounPhraseWithCountProd;

//grammar _nounWithCount(empty): [badness 500] : EmptyNounPhraseProd;
grammar _nounWithCount(empty): [badness 500] : EmptyNounPhraseProd;

class NounListWithCountProd: NounListProd
	resolveNouns(resolver, results) {
aioSay('\nreturn = <<toString(np_.resolveNouns(resolver, results))>>\n ');
		return(np_.resolveNouns(resolver, results));
	}
;

class LayeredNounPhraseWithCountProd: LayeredNounPhraseProd
	resolveNouns(resolver, results) {
aioSay('\nnum_ = <<toString(num_ ? num_.getval() : nil)>>\n ');
aioSay('\nreturn = <<toString(np_.resolveNouns(resolver, results))>>\n ');
		return(np_.resolveNouns(resolver, results));
	}
;
