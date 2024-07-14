#charset "us-ascii"
//
// requireCount.t
//
#include <adv3.h>
#include <en_us.h>

#include "requireCount.h"

// Module ID for the library
requireCountModuleID: ModuleID {
        name = 'Require Count Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

modify playerMessages
	askMissingCount(actor, action, which) {
		reportQuestion('<.parser>\^How many do you want '
			+ (actor.referralPerson == ThirdPerson
				? actor.theName : '')
			+ ' to '
			+ action.getQuestionInf(which) + '?<./parser> ');
	}
;

_requireCount() {
	if(!gAction.numMatch || (gAction.numMatch.getval == 0)) {
		gActor.getParserMessageObj().askMissingCount(gActor, gAction,
			nil);
		tryAskingForCount();
	}
}

tryAskingForCount() {
	local n, str;

	str = readMainCommandTokens(rmcAskObject);

	if(gTranscript)
		gTranscript.activate();

	if(str == nil)
		throw new ReplacementCommandStringException(nil, nil, nil);

	str = str[1];

	if(rexMatch('^<space>*(<Digit>+)<space>*$', str) == nil)
		throw new ReplacementCommandStringException(str, nil, nil);

	n = toInteger(rexGroup(1)[3]);

	gAction.retryWithMissingCount(gAction, n);
}

modify Action
	retryWithMissingCount(orig, n) {
		local action;

		action = createForRetry(orig);
		action.numMatch = new NumberProd();
		action.numMatch.getval = n;
		initForMissingCount(orig);
		resolveAndReplaceAction(action);
	}

        initForMissingCount(orig) {
		local origDobj;

		origDobj = orig.getDobj();
		dobjMatch = new PreResolvedProd(origDobj != nil
			? origDobj : orig.dobjList_);
	}
;

_replaceActionWithCount(actor, actionClass, count, [objs]) {
	local action;

	action = actionClass.createActionInstance();
	action.setResolvedObjects(objs...);
	action.numMatch = new NumberProd();
	action.numMatch.getval = toInteger(count);
	execNestedAction(true, nil, actor, action);
	exit;
}
