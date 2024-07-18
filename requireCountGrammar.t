#charset "us-ascii"
//
// requireCountGrammar.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "requireCount.h"

class TCAction: TAction
	resolveNouns(srcActor, dstActor, results) {
		inherited(srcActor, dstActor, results);
	}
	askDobjResponseProd = fooList
	//askDobjResponseProd = nounList
;

grammar literalCount(empty): [badness 400] : EmptyLiteralPhraseWithCountProd;

grammar literalCount(digits): tokInt->num_ : LiteralCountProd
	getval() { return(toInteger(num_)); }
	getStrVal() { return(num_); }
;

grammar literalCount(spelled): spelledNumber->num_ : LiteralCountProd
	getval() { return num_.getval(); }
;

class LiteralCountProd: NumberProd;
class EmptyLiteralPhraseWithCountProd: EmptyLiteralPhraseProd;

class CountNounProd: NounPhraseProd, AmbigResponseKeeper;
class CountQuantifiedPluralProd: QuantifiedPluralProd;

/*
grammar qualifiedSingularNounPhrase(count):
	literalCount->num_ indetSingularNounPhrase->np_
	: CountNounProd
;
*/


grammar qualifiedPluralNounPhrase(count):
	literalCount->num_ indetPluralOnlyNounPhrase->np_
	: CountQuantifiedPluralProd

	resolveNouns(resolver, results) {
		numMatch = new NumberProd();
		if(num_)
			numMatch.getval = num_.getval();
		quant_ = num_;

		return(inherited(resolver, results));
	}
;

grammar fooList(terminal): terminalNounPhrase->np_ : FooListProd;
grammar fooList(nonTerminal): completeNounPhrase->np_ : FooListProd;
grammar fooList(list): nounMultiList->lst_ : FooListProd;

class FooListProd: NounListProd
	resolveNouns(resolver, results) {
		return(np_.resolveNouns(resolver, results));
	}
;
