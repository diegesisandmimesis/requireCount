//
// requireCount.h
//

#define dobjCount literalCount->numMatch

#define gActionCount ((gAction && gAction.numMatch) \
	? gAction.numMatch.getval : nil)
#define requireCount (_requireCount())

#define replaceActionWithCount(action, objs...) \
	_replaceActionWithCount(gActor, action##Action, gActionCount, ##objs)

#define DefineTCAction(name) \
	DefineTActionSub(name, TCAction)

#define REQUIRE_COUNT_H
