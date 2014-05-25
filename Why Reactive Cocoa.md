#Why Reactive (Cocoa)?

The first step is acknowledging you have a problem. I didn't really know that I had a problem, or rather, that I was programming in a way lent itself to headaches. I decided to try Reactive Cocoa (RAC) because 1) I had heard a little bit about the Reactive style of programming on the server side from my colleague (without really getting the gist of it) 2) I love learning new hip things; and RAC came with buzzwords! I had very little understanding of what the benefits might be when I began. What I hope to do here is provide some insight as to why (most of our) default style of programming makes things unnecessarily hard on us, and how RAC's Reactive style can improve things considerably.

To start you should probably go read the article ["Inputs and Outputs"](http://blog.maybeapps.com/post/42894317939/input-and-output) by [Josh Aber](https://twitter.com/joshaber). It's an **extremely** well written article that I can only hope to supplement with a slightly different explanation. (Apologies for regurgitating a bit of what he's covered there.)

##Inputs and Outputs
So what does Josh mean when he says it's all Inputs and Outputs? The entirety of our job, the meat and potatoes of what we are doing when we build an app, is waiting for events to happen that provide some sort of information (inputs), and then acting on some combination of those inputs and generating some kind of output. Inputs come in all kinds and provide us with varying levels and types of information:

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

This is just a sampling of the different kinds of inputs we deal with daily. There are certainly reasons for all the different patterns above, not the least of which is the evolution of our craft and tools; but when it comes down to it they are *ALL just telling us some event happened*, and sometimes providing information about that event.

Outputs can be anything, but some typical ones include updating a value on a server, storing something in core data; or most importantly, and most typically, **updating the UI**.

The problem is that we rarely (read: never) are updating our output based on *just one input*. I can't put it any better than the way Josh stated it: 
>"To put it another way, the output at any one time is the result of combining all inputs. The output is a function of all inputs up to that time."

## Paper Tape Computing (Linear)
The issue here is one of time. Time is a pain in the keister (keeping this G rated). Basically we program in linear fashion, never wandering all that far from the way things were done on [paper tape computers](https://www.youtube.com/watch?v=uqyVgrplrno). Basically we have an understanding that there is a run loop, and that our code is going to be placed on a timeline and executed in linear fashion (ignoring multiple processes for the sake of argument.)