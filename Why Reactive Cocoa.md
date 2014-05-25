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

Outputs can be anything, but some typical ones include updating a value on a server, storing something in core data; or most importantly, and most typically, **updating the UI**.

The problem is that we rarely (read: never) are updating our output based on *just one input*. I can't put it any better than the way Josh stated it: 
>"To put it another way, the output at any one time is the result of combining all inputs. The output is a function of all inputs up to that time."

## Paper Tape Computing (Linear Execution)
The issue here is one of **time**. Time is a pain in the keister (keeping this G rated). Basically, we program in linear fashion, never wandering all that far from the way things were done on [paper tape computers](https://www.youtube.com/watch?v=uqyVgrplrno). We have an understanding that there is a run loop, and that our code is going to be placed on a time line and executed in order (ignoring multiple processes for the sake of argument.) Even our awesome block callbacks and delegates are just giving us another snippet of time on the time line where we can execute code, as shown in this beautiful (and super simplified) diagram.

![Taking turns on the paper tape computer][code-timeline]

The problem is that events are occuring *as time is passing*. When any one of those events occurs, We may need to generate output. To do that we need to combine the new information from this event with all the information from past relevant events that might affect my new output. (Let's say we're updating the screen.)

![Events over time][events]

But how do we do that? There's no elegant mechanism provided for accessing past events, or combining the results of a bunch of events. We are left to our own devices to come up with a solution. What's the solution we all are immediately trained to jump to?

##STATE
State is what makes our job as programmers VERY hard sometimes. To be honest, I didn't recognize this at all. That is to say, I knew when I had lots of different variables affecting my UI that it really became hard to manage; but I didn't recognize it in the philisophical, definable way. It's so engrained in me that I just thought it was part of the deal with programming, and that maybe I wasn't the best programmer for constantly struggling with it. 

This is not the case. **Everyone sucks at managing state.** It is the source of an endless amount of bugs and blank stares. "I understand WHY it crashed. I just don't understand how the user could have possibly gotten it in that state." &#8592; Programmer adds another state check.

So what is state? Are we just talking about enums and state machines like `TCQuestionDetailViewControllerState`? Nope. This is all state:

``` Objective-C
@interface TCQuestionDetailViewController ()
@property (nonatomic, strong) TCQuestion *question;
@property (nonatomic, strong) NSArray *answers;
@property (nonatomic, strong) TCUser *me;
@property (nonatomic, assign) NSInteger commentPage;
@property (nonatomic, strong) NSMutableOrderedSet *comments;
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

The problem here is that every time you add another state, you are increasing the possible number of combinations in an **EXPONENTIAL** manner. And that's even assuming your states are just BOOLs. I had an "aha!" moment when I saw a slide in a talk by [Justin Spahr-Summers](http://twitter.comjspahrsummers).

![State combinations increasing exponentially][state]

I looked at my code, like the interface above, and realized I was giving myself an unbelievably difficult task, requiring super-geek like abilities to pull off (to the tune of 4000+ different combinations I needed to handle if they were all relevant to the output). 

To make matters worse, this type of code will often produce UI only bugs that are incredibly hard, if not impossible, to identify in any automated way. After a few times through this wringer, we've probably all ended up writing centralized update methods like this that end up littered throughout our code: `updateViewCommentStatus` `updateChangeAnswerButtonText`. Any time we add another event, we make sure it's updating all the appropriate states and throw in the appropriate centralized update methods.





[code-timeline]: images/code-timeline.png "Taking turns on the paper tape computer"
[events]: images/events.png "We're all just dots on this groovy timeline, man."
[state]: images/state.png "Alright. Shut it down. We blew it."
