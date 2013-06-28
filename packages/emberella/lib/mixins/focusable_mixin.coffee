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

  focusIn: (e) ->
    e?.stopPropagation()
    set @, 'hasFocus', true

  focusOut: (e) ->
    e?.stopPropagation()
    set @, 'hasFocus', false
