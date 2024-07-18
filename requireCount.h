//
// requireCount.h
//

// Macro for VerbRule declarations.  Roughly equivalent to singleNumber
// from adv3.
#define dobjCount nounCount->numMatch

// Retuns the count associated with gAction, or nil if there isn't one.
#define gActionCount ((gAction && gAction.numMatch) \
	? gAction.numMatch.getval : nil)

// Macro for calling the _requireCount() method.
#define requireCount (_requireCount())

// Macro for replacing an action with a count.
#define replaceActionWithCount(action, objs...) \
	_replaceActionWithCount(gActor, action##Action, gActionCount, ##objs)

// Macro for declaring actions that take counts.
#define DefineTCAction(name) \
	DefineTActionSub(name, TCAction)

#define REQUIRE_COUNT_H
