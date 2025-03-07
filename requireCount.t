#charset "us-ascii"
//
// requireCount.t
//
//	A TADS3/adv3 module providing a mechanism for requiring a count
//	in actions.
//
//
// USAGE
//
//	Declare an Action with the DefinteTActionWithCount macro, then
//	a VerbRule for it containing the singleDobjWithCount or
//	dobjListWithCount macro:
//
//		DefineTActionWithCount(Foozle);
//		VerbRule(Foozle)
//			'foozle' dobjListWithCount
//			: FoozleAction
//			verbPhrase = 'foozle/foozling (what)'
//		;
//
//	Then on Things you can use requireCount to prompt for a count if
//	one is missing:
//
//		pebble: Thing '(small) (round) pebble' 'pebble'
//			"A small, round pebble. "
//			dobjFor(Foozle) {
//				action() {
//					requireCount;
//					defaultReport('{You/He} foozle{s}
//						<<spellInt(gActionCount)>>
//						pebbles. ');
//				}
//			}
//		;
//
//	Then if a player tries >FOOZLE PEBBLE (without a count):
//
//		>FOOZLE PEBBLE
//		How many pebbles do you want to foozle?
//
//		>10
//		You foozle ten pebbles.
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
	// Check to see if we've already got an action/dobj count
	// hidden in the dobj match.  This will happen if the player
	// enters a bare verb (>FOOZLE) and responds to the
	// object prompt ("What do you want to foozle?") with a count
	// and a noun phrase (">10 PEBBLES")
	if(!gActionCount && (gActionDobjMatchCount != nil)) {
		gAction.numMatch = new NumberProd();
		gAction.numMatch.getval = gActionDobjMatchCount;
	}

	// Some productions squash numMatch, so as a fallback we can use
	// a bespoke property on Action to pass a count.
	if(!gActionCount && (gAction._retryCount != nil)) {
		gAction.numMatch = new NumberProd();
		gAction.numMatch.getval = gAction._retryCount;
	}

	// We check to see if we already have a count on the action.
	// If we do, we take no action.
	if(!gActionCount) {
		// Display the prompt.
		gActor.getParserMessageObj().askMissingCount(gActor, gAction,
			nil, gDobj);

		// Get the player input.
		tryAskingForCount();
	}

	// See if we need to require as many in-game objects as the
	// count.
	if(gAction.requireRealCount &&
		(gActionCount > gAction.savedDobjList.length)) {

		// Special case.  The count is larger than the length of
		// the dobjList, but because _retryCount is set that
		// PROBABLY means that we got here via the three-step
		// interactive process (>FOOZLE, "What do you want to foozle?",
		// >PEBBLE, "How many pebbles do you want to foozle?", >5),
		// and if that happens we'll can end up with a single dobj
		// even if there are more objects in scope that would've
		// matched if we started out with a count.  So we do
		// another special check here, consisting of trying to
		// re-(re-)run the command
		if((gAction.savedDobjList.length == 1)
			&& (gAction._retryCount != nil)) {
			throw new ReplacementCommandStringException(
				gAction.getOrigText() + ' '
				+ toString(gActionCount) + ' '
				+ gDobj.pluralName, nil, nil);
		}

		new BasicResolveResults().insufficientQuantity(
			gAction.dobjList_[1].np_.getOrigText(),
			gAction.dobjList_, gActionCount);
	}
}

// A little mini-parser for handling the response to the number question.
// We check to see if the response is just a number.  If so, we try to
// re-run the command that produced the question with the number added.
// If the response DOES NOT look like a number we punt it back to the
// parser and try to handle it as a normal command.
// This is similar to tryAskingForObject() in adv3/parser.t
tryAskingForCount() {
	local n, str;
	//local n, str, toks;

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

	// Input tokens.
	//toks = str[2];

	// Input String.
	str = str[1];

	// If the input was just a number and whitespace we can immediately
	// punt this off to our logic for handling it in Action.
	if(rexMatch('^<space>*(<Digit>+)<space>*$', str) != nil) {
		// The input was a number, so we use our bespoke retry
		// method on Action.
		gAction.retryWithMissingCount(gAction,
			toInteger(rexGroup(1)[3]));
		return;
	}

	// Next we check to see if the input is just a spelled-out number.
	n = spelledNumber.parseTokens(Tokenizer.tokenize(
		rexReplace('<^Alpha|Space>', str, ' ')), cmdDict);

	if(n.length == 1) {
		gAction.retryWithMissingCount(gAction, n[1].num_.getval());
		return;
	}

	// Try seeing if the input looks like a noun phrase with a count,
	// which will happen if the player responds to the "how many pebbles
	// do you want to [action]?" with "10 pebbles" instead of just
	// "10".
	// We don't check the return value because if the input looks
	// like a noun phrase it'll try to exit the current command
	// and execute the new one.
	_tryAskingForCountPhrase(str);

	// Everything is terrible, give up.
	// We punt the command string back to the parser via exception.
	throw new ReplacementCommandStringException(str, nil, nil);
}


_tryAskingForCountPhrase(str) {
	local matchList, rankings, res, toks;

	toks = Tokenizer.tokenize(str);

	// See if the input looks like a noun phrase with a count.
	matchList = _nounListWithCount.parseTokens(toks, cmdDict);

	// Nope, bail.
	if(!matchList || !matchList.length) {
		return;
	}

	// Ask the current actions dobj resolver to figure out
	// if the thing that looks like a noun phrase with a count
	// makes sense in context.
	res = gAction.getDobjResolver(gIssuingActor, gActor, true);
	rankings = MissingObjectRanking.sortByRanking(matchList, res);

	// Didn't work, bail.
	if((rankings[1].nonMatchCount != 0)
		&& (rankings[1].miscWordListCount != 0)) {
		return;
	}

	// Everything else worked, but somehow or other we reached this
	// point without actually getting a count out of it.  This
	// should never happen.
	if(!rankings[1].match.num_) {
		return;
	}

	// Retry the old command with the new count.
	gAction.retryWithMissingCount(gAction,
		rankings[1].match.num_.getval());
}

_debugObject(obj) {
	local l;

	aioSay('\n<<toString(obj)>>:\n ');
	l = obj.getPropList();
	l = l.sort(nil, { a, b: toString(a).compareTo(toString(b)) });
	l = l.subset({ x: obj.propDefined(x, PropDefDirectly) });
	l.forEach(function(o) {
		aioSay('\n\t<<toString(o)>>: <<toString(obj.(o))>>\n ');
	});
}

modify Action
	// Somewhat kludgy fallback.  Some productions appear to squash
	// numMatch (so it gets lost between here and the check in
	// _requireCount()), so here we use our own property to pass
	// the count when all else fails.
	_retryCount = nil

	// Add a retry method for re-running an action with a count.
	// Similar to retryWithMissingLister() from adv3/action.t
	// "orig" is the action to copy, "n" is the count.
	retryWithMissingCount(orig, n) {
		local action;

		// Create a copy of the given action.
		action = createForRetry(orig);

		// Copy the object data.
		action.initForMissingCount(orig);

		// Our kludge to deal with productions that lose numMatch.
		action._retryCount = n;

		// Set the value of numMatch on the action.
		action.numMatch = new NumberProd();
		action.numMatch.getval = n;

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
