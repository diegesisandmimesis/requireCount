//
// requireCount.h
//

// Macro for VerbRule declarations.  Roughly equivalent to singleNumber
// from adv3.
#define dobjCount nounCount->numMatch

// Retuns the count associated with gAction, or nil if there isn't one.
#define gActionCount ((gAction && gAction.numMatch) \
	? gAction.numMatch.getval : nil)

#define gActionDobjMatchCount ((gAction && gAction.dobjMatch \
	&& gAction.dobjMatch.newMatch \
	&& (gAction.dobjMatch.newMatch.num_ != nil)) \
	? gAction.dobjMatch.newMatch.num_.getval() : nil)

// Macro for calling the _requireCount() method.
#define requireCount (_requireCount())

// Macro for replacing an action with a count.
#define replaceActionWithCount(action, objs...) \
	_replaceActionWithCount(gActor, action##Action, gActionCount, ##objs)

// Macro for declaring actions that take counts.
#define DefineTActionWithCount(name) \
	DefineTActionSub(name, TActionWithCount)

#define REQUIRE_COUNT_H
