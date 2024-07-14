//
// requireCount.h
//

#define requireCount (_requireCount())

#define replaceActionWithCount(action, count, objs...) \
	_replaceActionWithCount(gActor, action##Action, count, ##objs)

#define REQUIRE_COUNT_H
