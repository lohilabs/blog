#Why Reactive (Cocoa)?

The first step is acknowledging you have a problem. I didn't really know that I had a problem, or rather, that I was programming in a way that lent itself to headaches. I decided to try ReactiveCocoa (RAC) because:

1. I had heard a little bit about the Reactive style of programming on the server side from my colleague (though not really getting the gist of it) 
2. I love learning new hip things; and RAC came with buzzwords! 

I had very little understanding of what the benefits might be when I began. What I hope to do here is provide some insight as to why (most of) our default style of programming makes things unnecessarily hard on us, and how RAC's Reactive style can improve things considerably.

To start you should probably go read the article ["Inputs and Outputs"](http://blog.maybeapps.com/post/42894317939/input-and-output) by [Josh Aber](https://twitter.com/joshaber). It's an **extremely** well written article that I can only hope to supplement with a slightly different explanation. (Apologies for regurgitating a bit of what he's covered there.)

##Inputs and Outputs
So what does Josh mean when he says it's all Inputs and Outputs? The entirety of our job, the meat and potatoes of what we are doing when we build an app, is waiting for events to happen that provide some sort of information (inputs), and then acting on some combination of those inputs and generating some kind of output. Inputs come in all kinds. They provide us with varying levels and types of information:

```Objective-C
// delegate methods
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
}
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}
// block based callbacks
[TCAPI getCategoriesModifiedSince:date onComplete:^(NSArray *objects, RKObjectRequestOperation *operation, NSError *error) {
}];
// target action
- (IBAction)doneAction:(id)sender {
}
// even timers
[NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(spinIt:) userInfo:nil repeats:YES];
```

This is just a sampling of the different kinds of inputs we deal with daily. They can be as simple as "Hey this happened", or be accompanied by a lot of detail about the event (the user scrolled exactly this much). There are certainly reasons for all the different patterns above, not the least of which is the evolution of our craft and tools; but when it comes down to it they are *ALL just telling us some event happened*, and sometimes providing information about that event.

Outputs can be anything, but a few typical examples include updating a value on a server, storing something in core data; or most importantly, and most typically, **updating the UI**.

The problem is that we rarely (read: never) are updating our output based on *just one input/event*. I can't put it any better than the way Josh stated it: 
>"To put it another way, the output at any one time is the result of combining all inputs. The output is a function of all inputs up to that time."

## Paper Tape Computing (Linear Programming)
The issue here is one of **time**. Time is a pain in the keister. Basically, we program in linear fashion, never wandering all that far from the way things were done on [paper tape computers](https://www.youtube.com/watch?v=uqyVgrplrno). We have an understanding that there is a run loop, and that our code is going to be placed on a time line and executed in order (ignoring multiple processes for the sake of argument.) Even our awesome block callbacks and delegates are just giving us another snippet of time on the time line where we can execute code, as shown in this beautiful (and super simplified) diagram.

![Taking turns on the paper tape computer][code-timeline]

If all these events (inputs) would just occur at the exact same time our lives would be much easier. The problem is that events are occuring *as time is passing*. When any one of those events occurs, we may need to generate output. To do that, we need to combine the new information from this event with all the information from past relevant, but divorced events that might affect our new output. (In this instance we're updating the screen.)

![Events over time][events]

But how do we do that? There's no elegant mechanism provided for accessing past events, or combining the results of a bunch of events. We are left to our own devices to come up with a solution. What's the solution we all are immediately trained to jump to?

##STATE
State is what makes our job as programmers VERY hard sometimes. To be honest, I didn't recognize this at all. That is to say, I knew when I had lots of different events and variables affecting my UI that it became really hard to manage; but I didn't recognize it in a philisophical, definable way. It's so engrained in me that I just thought it was part of the deal with programming, and that maybe I wasn't the best programmer for constantly struggling with it. 

This is not the case. **Everyone sucks at managing state.** It is the source of an endless amount of bugs and blank stares. "I understand WHY it crashed. I just don't understand how the user could have possibly gotten it in that state." &#8592; Programmer adds another state check.

So what is state? Are we just talking about enums and state machines like `TCQuestionDetailViewControllerState`? Nope. This is all state:

``` Objective-C
@interface TCQuestionDetailViewController ()
@property (nonatomic, strong) TCQuestion *question;
// .. even more properties
@property (nonatomic, assign) TCQuestionDetailViewControllerState state;
@property (nonatomic, assign) BOOL didAnswerQuestion;
@property (nonatomic, assign) BOOL questionFullyLoaded;
@property (nonatomic, assign) BOOL inResultsView;
@property (nonatomic, assign) BOOL isInModal;
@property (nonatomic, assign) BOOL loadingNextPageOfComments;
@property (nonatomic, assign) BOOL commentsAreShowing;
@property (nonatomic, assign) BOOL commentsLoadingShowing;
@property (nonatomic, assign) BOOL flippingAnswers;
@property (nonatomic, assign) BOOL isOwnerOfQuestion;
@property (nonatomic, assign) BOOL keyboardShowing;
@end
```

That should have made you cringe. I'm SURE you've seen (and written) similar code. If not you are either lying, or a WAY better programmer than I am. See UI's are often very complex in code even when they appear simple to the user. In fact, the very reason a user may LOVE your app is the amount of power it delivers in an extremely simple interface.
> Value is created by swallowing complexity for the user.  *- CEO of my first startup*

The problem here is that every time you add another state, you are increasing the possible number of combinations in an **EXPONENTIAL** manner. And that's assuming your states are just BOOLs. I had an "aha!" moment when I saw a slide in a talk by [Justin Spahr-Summers](http://twitter.comjspahrsummers).

![State combinations increasing exponentially][state]

I looked at my code, like the interface above, and realized I was giving myself an unbelievably difficult task, requiring super-geek like abilities to pull off (to the tune of 4000+ different combinations I needed to handle if they were all relevant to the output). Obviously this is HIGHLY error prone.

To make matters worse, this type of code will often produce UI only bugs that are incredibly hard, if not impossible, to identify in any automated way. After a few times through this wringer, we've probably all ended up writing centralized update methods like this that end up littered throughout our code: `updateViewCommentStatus` `updateChangeAnswerButtonText`. Any time we add another event (input), we make sure it's updating all the appropriate states and throw in the appropriate centralized update methods. Now our previously clean looking timeline is getting unmanagable:

![State change timeline][state-change]

How can we possibly keep this all straight in our heads? We are expending an awful lot of brain power dealing with the consequences of this linear code execution thing, this modern version of the paper tape computer. Despite the power of computers today, we are still doing a heck of a lot of work on their behalf. We're programming to the way the computer hardware works; to the way that the run loop is creating a timeline and the cpu is processing bits in a single file. We are architecting our code around low level implementation details of computing. What if we were to harness the power of the computer, let it do more of the work, and allow ourselves to think and design our apps in a more sane manner?

What if we abstract away the whole pesky notion of time and let the computer track state over time for us? Seems like something the computer would be good at.

## Non-Linear Programming

I'm not a classically trained, CS Degree wielding programmer. I did a lot of multimedia before ending up programming for my day job. It has it's plusses and minuses, but it's allowed me some outside perspective on things. For instance I've seen this whole non-linear concept play out a couple times. 

Photoshop didn't used to have non destructive editing. You would make your edits (inputs) over time and your only recourse for change was your undo history. When computers became powerful enough, the timeline intrinsic to the linear editing process was replaced by a lot of non-destructive layers and filters. You didn't have to worry about the order you did things (as much). The computer handled combining all the inputs (filters, masks, etc) for you as long as you leveraged them properly.

The same thing occured with video editing and compositing. Initially it was done with destructive edits, where you were literally altering the original video file and could only go back so far as undo allowed (or to your last backup). Then the whole process went non-linear and we were given non-destructive filters and the ability to adjust your edits an infinite amount of times.

This change to non-linear tools allow for amazing levels of flexibility and creativity, giving the artists several orders of magnitude more power to realize their visions.

Even auto-layout is a great example of moving towards a non-linear (and reactive) approach. Instead of waiting for certain events to occur, then checking the status of a bunch of views and manually updating frames, you just **describe** what the relationships between all the views are ahead of time and let the computer do the work.

##Compositional Event System

Recently [Jon Sterling](https://twitter.com/jonsterling) mentioned the term "Compositional Event System" in a twittergument about the term used to define RAC and similar styles of programming. I think it fits really well. Much like the shifts in the multimedia tools above, what we really want to do is remove (for the most part) the need to deal with the timeline of when events (inputs) happened, and therefor the need to manually keep track of them with state. We want to make the computer do that for us.

We don't care WHEN events (inputs) happen. We want to get away from that crazy timeline we were managing above, to a system where we just describe up front what happens to our UI (output) whenever a certain combination of inputs occur. We want to define the relationship between events (inputs), define their subsequent outputs, and then let the computer **react** appropriately whenever those events occur. Yes state still exists somewhere in this event system, but it's abstracted away from our day to day work (mostly).

When you think about it, this concept is actually very simple, and not entirely foreign. Inputs and outputs:

![A home-made 4-bit computer logic board with lights][logic-board]
[Original site](http://www.waitingforfriday.com/index.php/4-Bit_Computer)

##ReactiveCocoa

So how does ReactiveCocoa abstract away the timeline for us and step into the world of Non-Linear Programming? It does this by wrapping all those patterns of input from above in one unified interface called a Signal. Then it gives us operators so that we can combine, split, and filter those events.

...


[code-timeline]: images/code-timeline.png "Taking turns on the paper tape computer"
[events]: images/events.png "We're all just dots on this groovy timeline, man."
[state]: images/state.png "Alright. Shut it down. We blew it."
[state-change]: images/state-change.png "Take Illustrator away from this guy."
[logic-board]: images/logic-board.jpg "Man that seems satisfying."