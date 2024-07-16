#charset "us-ascii"
//
// requireCount.t
//
//	A TADS3/adv3 module providing a mechanism for requiring a count
//	in actions.
//
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

// Library message for the "how many" question.
// Similar to askMissingObject() in adv3/en_us/msg_neu.t
modify playerMessages
	askMissingCount(actor, action, which, obj) {
		reportQuestion('<.parser>\^How many '
			+ (obj ? obj.pluralName + ' ': '')
			+ 'do you want '
			+ (actor.referralPerson == ThirdPerson
				? actor.theName : '')
			+ ' to '
			+ action.getQuestionInf(which)
			+ '?<./parser> ');
	}
;

// Global function for (maybe) displaying the question and then
// handling the response.
// The requireCount macro points to this function.
_requireCount() {
	// We check to see if we already have a count on the action.
	// If we do, we take no action.
	if(!gAction.numMatch || (gAction.numMatch.getval == 0)) {
		// Display the prompt.
		gActor.getParserMessageObj().askMissingCount(gActor, gAction,
			nil, gDobj);

		// Get the player input.
		tryAskingForCount();
	}
}

// A little mini-parser for handling the response to the number question.
// We check to see if the response is just a number.  If so, we try to
// re-run the command that produced the question with the number added.
// If the response DOES NOT look like a number we punt it back to the
// parser and try to handle it as a normal command.
// This is similar to tryAskingForObject() in adv3/parser.t
tryAskingForCount() {
	local str;

	// Display a normal prompt and handle input normally.
	str = readMainCommandTokens(rmcAskObject);

	// Re-enable the transcript if we have one.
	if(gTranscript)
		gTranscript.activate();

	// readMainCommandTokens() returning nil means it handled the
	// command already, so we treat it as if like an empty command
	// line (because there's nothing for us to do).
	if(str == nil)
		throw new ReplacementCommandStringException(nil, nil, nil);

	// This will be the input string.
	str = str[1];

	// If the input wasn't a number (with or without whitespace) then
	// we're not going to handle it here, and we just punt it back
	// to the parser.
	if(rexMatch('^<space>*(<Digit>+)<space>*$', str) == nil)
		throw new ReplacementCommandStringException(str, nil, nil);

	// The input was a number, so we use our bespoke retry
	// method on Action.
	gAction.retryWithMissingCount(gAction, toInteger(rexGroup(1)[3]));
}

modify Action
	// Add a retry method for re-running an action with a count.
	// Similar to retryWithMissingLister() from adv3/action.t
	// "orig" is the action to copy, "n" is the count.
	retryWithMissingCount(orig, n) {
		local action;

		// Create a copy of the given action.
		action = createForRetry(orig);

		// Set the value of numMatch on the action.
		action.numMatch = new NumberProd();
		action.numMatch.getval = n;

		action.initForMissingCount(orig);
		resolveAndReplaceAction(action);
	}

	// Stub method.
	initForMissingCount(orig) {}

	// Copy the dobj information, if any, from the original action.
	_initForMissingDobj(orig) {
		local origDobj;

		origDobj = orig.getDobj();
		dobjMatch = new PreResolvedProd(origDobj != nil
			? origDobj : orig.dobjList_);
	}

	// Copy the iobj information, if any, from the original action.
	_initForMissingIobj(orig) {
		local origIobj;

		origIobj = orig.getIobj();
		iobjMatch = new PreResolvedProd(origIobj != nil
			? origIobj : orig.iobjList_);
	}
;

modify TAction
	// With a TAction we need to set the direct object(s) on the
	// action.
        initForMissingCount(orig) {
		_initForMissingDobj(orig);
	}
;

modify TIAction
	// For a TIAction we set both the direct and indirect objects.
	initForMissingCount(orig) {
		_initForMissingDobj(orig);
		_initForMissingIobj(orig);
	}
;

// Global method for replacing the current action with another action
// with a count.
// Used by the replaceActionWithCount macro.
_replaceActionWithCount(actor, actionClass, count, [objs]) {
	local action;

	action = actionClass.createActionInstance();
	action.setResolvedObjects(objs...);
	action.numMatch = new NumberProd();
	action.numMatch.getval = toInteger(count);
	execNestedAction(true, nil, actor, action);
	exit;
}
