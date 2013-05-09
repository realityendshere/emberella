###
@module emberella
@submodule emberella-views
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set

###
  `Emberella.RangeInput` is a simple wrapper for `<input type="range" />` with
  support for change and scroll wheel events.

  WebKit only.

  @class RangeInput
  @namespace Emberella
###

# TODO: Add documentation
# TODO: Support other browsers

Emberella.RangeInput = Ember.View.extend
  classNames: ['ember-range']

  value: 0.5
  minimum: 0
  maximum: 1
  step: 0.01
  scrollSpeed: 0.2

  template: Ember.Handlebars.compile '<input type="range" {{bindAttr min="view.minimum"}} {{bindAttr max="view.maximum"}} {{bindAttr step="view.step"}} {{bindAttr value="view.value"}} />'

  change: (e) ->
    target = e.target
    set(@, 'value', +target.value)
    true

  mouseScroll: (e) ->
    e.stopPropagation()
    e.preventDefault()

    evt = e.originalEvent
    min = get(@, 'minimum')
    max = get(@, 'maximum')
    step = get(@, 'step')
    scrollSpeed = get(@, 'scrollSpeed')

    deltaX = evt.wheelDeltaX * scrollSpeed
    deltaX = -1 * deltaX unless evt.webkitDirectionInvertedFromDevice

    deltaY = evt.wheelDeltaY * scrollSpeed
    deltaY = -1 * deltaY if evt.webkitDirectionInvertedFromDevice
    delta = deltaX + deltaY

    newVal = parseInt(get(@, 'value'), 10) + (delta * step)
    value = Math.round(newVal / step) * step

    if value < min
      set(@, 'value', min)
    else if value > max
      set(@, 'value', max)
    else
      set(@, 'value', value) unless isNaN value

    true
