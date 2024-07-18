#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the requireCount library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "requireCount.h"

versionInfo: GameID;
gameMain: GameMainDef initialPlayerChar = me;

DefineTAction(Draw);
VerbRule(Draw)
	'draw' singleNumber dobjList : DrawAction
	verbPhrase = 'draw/drawing (what)'
;

/*
DefineTAction(DrawCount);
VerbRule(DrawCount)
	'draw' singleNumber dobjList : DrawCountAction
	verbPhrase = 'draw/drawing (what)'
;
*/

modify Thing
	dobjFor(Draw) {
		verify() {
			illogical('{You/He} can\'t draw {that dobj/him}. ');
		}
	}
	//dobjFor(DrawCount) { action() { replaceAction(Draw, self); } }
;

class Card: Thing '(blank) playing card' 'playing card'
	"A blank playing card. "
	isEquivalent = true
;

class CardUnthing: Unthing '(single) (individual) playing card' 'card'
	notHereMsg = 'Nope. '
	dobjFor(Draw) {
		verify() { dangerous; }
		action() { replaceActionWithCount(Draw, deck.cards); }
	}
/*
	dobjFor(DrawCount) {
		verify() { dangerous; }
		action() {
			replaceActionWithCount(DrawCount, deck.cards);
		}
	}
*/
;

class CardsUnthing: CardUnthing 'playing cards' 'cards'
	isPlural = true
/*
	dobjFor(Draw) {
		verify() {}
		action() { replaceAction(DrawCount, self); }
	}
*/
	dobjFor(Draw) {
		verify() {}
		action() {
			local n;

			requireCount;

			n = gAction.numMatch.getval();
			defaultReport('{You/He} draw{s} <<spellInt(n)>>
				card<<((n == 1) ? '' : 's')>>. ');
		}
	}
;

startRoom: Room 'Void' "This is a featureless void. ";
+me: Person;
+deck: Thing 'deck (of) (card)/cards' 'deck of cards'
	"It's a deck of playing cards. "
	cards = (contents.valWhich({ x: x.ofKind(CardsUnthing) }))
/*
	dobjFor(Draw) {
		verify() { }
		action() { replaceAction(Draw, cards); }
	}
*/
	dobjFor(Draw) {
		verify() { }
		action() {
			replaceActionWithCount(Draw, deck.cards);
		}
	}
;
++CardUnthing;
++CardsUnthing;
+pebble: FoozleThing '(small) (round) pebble*pebbles' 'pebble'
	"A small, round pebble. "
;
+rock: FoozleThing '(ordinary) rock*rocks' 'rock'
	"An ordinary rock. "
;

DefineTCAction(Foozle);
VerbRule(Foozle)
	'foozle' dobjCount singleDobj
	: FoozleAction
	verbPhrase = 'foozle/foozling (what)'
;

modify Thing
	dobjFor(Foozle) {
		verify() { illogical('{You/He} can\'t foozle that. '); }
	}
;

class FoozleThing: Thing
	dobjFor(Foozle) {
		verify() {}
		action() {
			requireCount;
			defaultReport('{You/He} foozle{s}
				<<spellInt(gActionCount)>>
				<<(gActionCount != 1) ? pluralName : name>>. ');
		}
	}
;



replace tryAskingForObject(issuingActor, targetActor,
                   resolver, results, responseProd)
{
    /* 
     *   Prompt for a new command.  We'll use the main command prompt,
     *   because we want to pretend that we're asking for a brand new
     *   command, which we'll accept.  However, if the player enters
     *   something that looks like a response to the missing-object query,
     *   we'll handle it as an answer rather than as a new command.  
     */
    local str = readMainCommandTokens(rmcAskObject);

    /* re-enable the transcript, if we have one */
    if (gTranscript)
        gTranscript.activate();

    /* 
     *   if it came back nil, it means that the preparser fully processed
     *   the input, which means we have nothing more to do here - simply
     *   treat this is a nil replacement command 
     */
    if (str == nil) {
aioSay('\n===FOO 4===\n ');
        throw new ReplacementCommandStringException(nil, nil, nil);
}
    
    /* extract the input line and tokens */
    local toks = str[2];
    str = str[1];

    /* keep going as long as we get replacement token lists */
    for (;;)
    {    
        /* try parsing it as an object list */
        local matchList = responseProd.parseTokens(toks, cmdDict);
        
        /* 
         *   if we didn't find any match at all, it's probably a brand new
         *   command - go process it as a replacement for the current
         *   command 
         */
        if (matchList == [])
        {
            /* 
             *   they didn't enter something that looks like a valid
             *   response, so assume it's a brand new command - parse it
             *   as a new command by throwing a replacement command
             *   exception with the new string 
             */
aioSay('\n===FOO 1===\n ');
            throw new ReplacementCommandStringException(str, nil, nil);
        }

        /* if we're in debug mode, show the interpretations */
        dbgShowGrammarList(matchList);
        
        /* create an interactive sub-resolver for resolving the response */
        local ires = new InteractiveResolver(resolver);

        /* 
         *   rank them using our response ranker - use the original
         *   resolver to resolve the object list 
         */
        local rankings = MissingObjectRanking.sortByRanking(matchList, ires);

        /*
         *   If the best item has unknown words, try letting the user
         *   correct typos with OOPS.  
         */
        if (rankings[1].nonMatchCount != 0
            && rankings[1].unknownWordCount != 0)
        {
            try
            {
                /* 
                 *   complain about the unknown word and look for an OOPS
                 *   reply 
                 */
                tryOops(toks, issuingActor, targetActor,
                        1, toks, rmcAskObject);
            }
            catch (RetryCommandTokensException exc)
            {
                /* get the new token list */
                toks = exc.newTokens_;

                /* replace the string as well */
                str = cmdTokenizer.buildOrigText(toks);

                /* go back for another try at parsing the response */
                continue;
            }
        }

        /*
         *   If the best item we could find has no matches, check to see
         *   if it has miscellaneous noun phrases - if so, it's probably
         *   just a new command, since it doesn't have anything we
         *   recognize as a noun phrase.  
         */
        if (rankings[1].nonMatchCount != 0
            && rankings[1].miscWordListCount != 0)
        {
            /* 
             *   it's probably not an answer at all - treat it as a new
             *   command 
             */
aioSay('\n===FOO 2===\n ');
            throw new ReplacementCommandStringException(str, nil, nil);
        }

        /* the highest ranked object is the winner */
        local match = rankings[1].match;

        /* 
         *   Check to see if this looks like an ordinary new command as
         *   well as a noun phrase.  For example, "e" looks like the noun
         *   phrase "east wall," in that "e" is a synonym for the adjective
         *   "east".  But "e" also looks like an ordinary new command.
         *   
         *   We'd have to be able to read the user's mind to know which
         *   they mean in such cases, so we have to make some assumptions
         *   to deal with the ambiguity.  In particular, if the phrasing
         *   has special syntax that makes it look like a particularly
         *   close match to the query phrase, assume it's a query response;
         *   otherwise, assume it's a new command.  For example:
         *   
         *.    >dig
         *.    What do you want to dig in?  [sets up for "in <noun>" reply]
         *   
         *   If the user answers "IN THE DIRT", we have a match to the
         *   special syntax of the reply (the "in <noun>" phrasing), so we
         *   will assume this is a reply to the query, even though it also
         *   matches a valid new command phrasing for ENTER DIRT.  If the
         *   user answers "E" or "EAST", we *don't* have a match to the
         *   special syntax, but merely an ordinary noun phrase match, so
         *   we'll assume this is an ordinary GO EAST command.
         */
        local cmdMatchList = firstCommandPhrase.parseTokens(toks, cmdDict);
        if (cmdMatchList != [])
        {
            /* 
             *   The phrasing looks like it's a valid new command as well
             *   as a noun phrase reply.  Check the query reply match for
             *   special syntax that would distinguish it from a new
             *   command; if it doesn't match any special syntax, assume
             *   that it is indeed a new command instead of a query reply.
             */
            if (!match.isSpecialResponseMatch) {
aioSay('\n===FOO 3===\n ');
                throw new ReplacementCommandStringException(str, nil, nil);
		}
        }

        /* show our winning interpretation */
        dbgShowGrammarWithCaption('Missing Object Winner', match);

        /* 
         *   actually resolve the response to objects, using the original
         *   results and resolver objects 
         */
        local objList = match.resolveNouns(ires, results);

aioSay('\n===FOO===\n ');

aioSay('\n\tmatch = <<toString(match)>>\n ');
aioSay('\n\tobjList = <<toString(objList)>>\n ');
        /* stash the resolved object list in a property of the match tree */
        match.resolvedObjects = objList;


        /* return the match tree */
        return match;
    }
}
