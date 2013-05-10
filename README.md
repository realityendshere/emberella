# Emberella

[Ember](http://emberjs.com) is an incredibly useful Javascript framework that
has helped me and my colleagues craft and ship several web-based tools to our
client. It is my hope to offer a grab bag of useful components for the Ember
framework here.

## Is it "Good"?

Although I've followed the development of [Ember](http://emberjs.com) since its
beginnings, I have only recently had the opportunity to develop apps with it.
I built the miscellaneous components included in this package as I was learning
the intricacies and hidden gems Ember has to offer. Similarly, Ember itself has
evolved quickly over the last few months.

While I've made every effort to refactor and update these components as I learn
new tricks and the framework matures and will be using them in at least one or
two of my own apps, all of these modules should be considered experimental.

## What's Included?

Right now, a grab bag of code.

### Controller(s)

`Emberella.SparseArrayController`

In cases where a finite but large amount of data must be fetched from the
server (or wherever your app's data persists), it's not always practical to
load all the data up front. This controller lazily loads individual records or
"pages" of records on demand.

This component can be "taught" how to fetch data by extending the class with
your own `didRequestIndex`, `didRequestRange`, and `didRequestLength` methods.

While waiting for data to load, the SparseArrayController will return
placeholder objects. Loaded records are "cached" in a sparse array until the
`reset` or `unset` methods get called.

### Helper(s)

**function_helpers**

Sometimes the best way to boost performance is to slow things down. I found
myself throttling and debouncing various methods through these components to
reduce excessive network chatter or to prevent computationally intensive tasks
from running amok.

The function helpers mixin includes the `throttle` and `debounce` methods from
Underscore.js.

### Mixins

`Emberella.DraggableMixin`

Extend a view with this mixin to establish some patterns for responding to the
`dragStart` and `dragEnd` DOM events. Namely, adding and removing class names
from the draggable view element.

`Emberella.DroppableMixin`

Extend a view with this mixin to make it a drop target for draggable views or
even files from the desktop. Adds handling for the variety of drag and drop
events critical to making a drop target function as expected.

`Emberella.FocusableMixin`

Extend a view with this mixin to enable it to respond to focus and blur events
and become the target of keyboard events (or other events reserved for
elements that can become the window's active element).

`Emberella.KeyboardControlMixin`

Extend a view with this mixin (and `Emberella.FocusableMixin`) to allow it to
respond to keyboard input. Maps common control keys to easy to remember methods
(e.g. `backspacePressed`, `leftArrowPressed`, `escPressed`) so you don't have
to lookup the key codes.

The alpha-numeric and punctuation keys do still require a key code reference;
if a key isn't mapped to a developer-friendly name, the keyboard event will be
sent along to a method like `key65Pressed`.

`Emberella.QueueableMixin`

Extend an array controller with this mixin to add a processing queue.

If processing an object is computationally intensive (e.g. image processing)
or uses to much of a limited resource (e.g. server connections, bandwidth),
then each item can wait in the queue until its turn to be processed. Items are
processed in the order they are received.

I use this mixin to manage file uploads. If the user wishes to upload 1000
files at once, I place them in a queue and send files to the server a few at a
time.

`Emberella.RemoteQueryBindingsMixin`

Extend a controller with this mixin to map specified controller properties
into a query object to be transformed into request parameters to be sent to
the server.

`Ember.ResizeHandler`

Extend a view with this mixin to allow it to react to window resize events.

Copied from https://github.com/Addepar/ember-table/blob/master/src/utils/resize_handler.coffee

`Ember.ScrollHandlerMixin`

Extend a view with this mixin to allow it to react to scroll events.

Copied from https://github.com/Addepar/ember-table/blob/master/src/utils/utils.coffee

`Emberella.SelectableMixin`

Extend an array controller with this mixin to enable it to manage a set of
selected content members.

`Ember.StyleBindingsMixin`

Extend a view with this mixin to map the values of specified properties to
an inline style attribute on the view's DOM element.

Copied from https://github.com/Addepar/ember-table/blob/master/src/utils/style_bindings.coffee

### Views

`Emberella.ListView`

My colleagues and I gave both `Ember.ListView` and `Ember.TableView` a try.

* [Ember Table View by Addepar](https://github.com/Addepar/ember-table)
* [Ember List View](https://github.com/emberjs/list-view)

Both of these projects are incredibly awesome and promising. As with anything
cutting edge, these projects didn't quite suit the needs of our apps. We needed
support for...

* responsive layouts
* a grid listing
* more scrolling options
* and the ability to defer data fetching until the user's scrolling speed slowed

Using both of these projects as inspiration, `Emberella.ListView` offers some
level of support for all of these features. Eventually, once these concepts
are tested, I hope they can be incorporated into the Ember List View project.

So, what is `Emberella.ListView`? It's an incremental loading list. That is,
it builds enough listing views to fill the viewable area and reuses them to
create the illusion of scrolling through a massively large list of items. If
your app must (or may) display a long list of records, well, that's what this
view is built for. And it can seemingly display thousands of rows (I got up to
one million rows in my own experiments) without killing performance.

`Emberella.ListItemView`

An individual listing for an `Emberella.ListView`.

`Emberella.GridView`

Extends `Emberella.ListView` with support for columns. If your app needs to
display a long list of records in a grid layout (e.g. a grid of photos), well,
that is what this view is supposed to do.

`Emberella.GridItemView`

An individual listing for an `Emberella.GridView`.

`Emberella.FlexibleTextArea`

A text area with the ability to grow vertically as the line count of its value
grows.

`Emberella.ImageView`

If an `<img>`'s src attribute is bound to a property that frequently changes
value, you may notice the image referenced by the previous src continues to be
visible until the image specified by the new src value loads into the browser.

This view adds class names and event handling to (with styling) hide or the
adjust the `<img>` element in response to updates to the src attribute.
Additionally, the `Emberella.ImageView` will alert its parent each time a new
image is about to be fetched and when loading is complete.

`Emberella.RangeInput`

A wrapper for a "range" type input.

`Emberella.StarRating`

Want to give something 5 stars? That's what this view is for. You'll need to
provide your own stars and styles for the time being.

## Getting Starting with Emberella

These components are somewhat battle-tested in (non-public) production apps.
But they currently lack unit testing coverage, verified cross-browser support,
and complete examples and documentation. They are experimental!

As such, I will continue to investigate a means for more easily installing this
package of scripts into your projects.

Until I figure that part out, please feel free to clone the project and grab
what you need for your app from the `packages/emberella/lib` directory.

Of course, like most developers, I am busy building apps in exchange for
monetary compensation; I can't say I'll always be available to respond to
issues, questions, or concerns in a timely matter.

But, since other colleagues of mine will also be using Emberella, I am sure we
will stumble across common questions and needs that will promote enhancements,
bug fixes, tests, and documentation that will make this an even more useful
package of components.

I appreciate your patience and understanding.

## Why is it Called "Emberella"?

I wanted to namespace these components somehow. So, I looked at a thesaurus and
found that "cinder" is a synonym for "ember".

Cinderella -> Emberella. Yup.

I hope the name doesn't step on anyone's toes...

## Much To Do

I can't list everything here. But here are some major TODOs.

* More/better documentation to explain how to use this stuff
* Examples that showcase these components
* Unit tests
* Refactoring of components I built awhile ago with less experience
* Adding some packaging to make it easy to install Emberella in your app

## Many to Thank

The apps I am building today would not already exist were it not for the Ember
framework. Thanks to the Ember Core Team and the project's contributors.

A special thanks to Erik Bryn and the folks behind `Ember.ListView`. (Erik gets
the extra thanks for answering all my crazy questions.)

Thanks to Addepar for sponsoring `Ember.TableView`.

And thanks to my colleagues for using these things in your own apps!
