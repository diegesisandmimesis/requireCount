//
// requireCount.h
//

#define literalCount singleCount->num_
/*
#define singleCount countNounPhrase->quant_
*/

#define gActionCount ((gAction && gAction.numMatch) \
	? gAction.numMatch.getval : nil)
#define requireCount (_requireCount())

#define replaceActionWithCount(action, objs...) \
	_replaceActionWithCount(gActor, action##Action, (gAction.numMatch ? gAction.numMatch.getval : nil), ##objs)

/*
#define DefineTActionWithCount(name) \
	DefineTActionSub(name##WithoutCount, TAction); \
	modify Thing dobjFor(name##WithoutCount) { \
		action() { replaceAction(name, self); } \
	}; \
	DefineTActionSub(name, TActionWithCount)
*/

#define REQUIRE_COUNT_H
