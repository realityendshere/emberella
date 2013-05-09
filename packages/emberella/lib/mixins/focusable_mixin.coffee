Emberella = window.Emberella
get = Ember.get
set = Ember.set

Emberella.FocusableMixin = Ember.Mixin.create

  ###
    @property isFocusable
    @type Boolean
    @default true
    @final
  ###
  isFocusable: true

  attributeBindings: ['tabindex']

  tabindex: 0

  classNameBindings: [ 'hasFocus:focused' ]

  hasFocus: false

  focusIn: ->
    set @, 'hasFocus', true

  focusOut: ->
    set @, 'hasFocus', false
