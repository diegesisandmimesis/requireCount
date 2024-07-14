//
// requireCount.h
//

#define requireCount (_requireCount())

#define replaceActionWithCount(action, objs...) \
	_replaceActionWithCount(gActor, action##Action, (gAction.numMatch ? gAction.numMatch.getval : nil), ##objs)

#define REQUIRE_COUNT_H
