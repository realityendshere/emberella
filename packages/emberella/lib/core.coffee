root = window
Emberella = root.Emberella = Ember.Namespace.create()
Emberella.VERSION = '0.0.2'


# Use HTMLBars compiler if available
# Eventually, everything will probably go all component-y and templates will
# be pre-compiled by Tomsters with fairy wings and pointy hats. When we get to
# that point, the entire Emberella premise will change and these 2 lines of
# code won't matter.

if Ember.typeOf(Ember.HTMLBars.compile) is 'function' and Ember.typeOf(Ember.Handlebars.compile) isnt 'function'
  Ember.Handlebars.compile = Ember.HTMLBars.compile


Ember.libraries?.register('Emberella', Emberella.VERSION)
