###
@module emberella
@submodule emberella-mixins
###

Emberella = window.Emberella
jQuery = window.jQuery
get = Ember.get
set = Ember.set

###
  `Emberella.DraggableMixin` adds drag event handling to a view class.

  This mixin is rough around the edges and is not verified to work
  across browsers.

  @class DraggableMixin
  @namespace Emberella
###

Emberella.DraggableMixin = Ember.Mixin.create
  ###
    @property isDraggable
    @type Boolean
    @default true
    @final
  ###
  isDraggable: true #quack like a duck

  ###
    A list of element attributes to keep in sync with properties of this
    view instance.

    @property attributeBindings
    @type Array
    @default ['draggable']
  ###
  attributeBindings: ['draggable']

  ###
    Set draggable attribute value of host element.

    @property draggable
    @type String
    @default 'true'
  ###
  draggable: 'true'

  ###
    The class name to apply to the element being dragged.

    @property draggingClass
    @type String
    @default 'dragging'
  ###
  draggingClass: 'dragging'

  init: ->
    # We will stash a 'global' reference to the view instance being dragged.
    set(Emberella, '_draggableView', null) unless get(Emberella, '_draggableView')
    @_super()

  ###
    Handle the start of a drag interaction. (DOM Event)

    @event dragStart
  ###
  dragStart: (e) ->
    $target = jQuery(e.target)
    $target.addClass(get(@, 'draggingClass'))
    e.dataTransfer.setData('view', Ember.guidFor(@))
    set(Emberella, '_draggableView', @)
    @trigger 'didDragStart', e

  ###
    Handle the end of a drag interaction. (DOM Event)

    @event dragEnd
  ###
  dragEnd: (e) ->
    set(Emberella, '_draggableView', null)
    $target = jQuery(e.target)

    draggingClass = get @, 'draggingClass'
    dragOverClass = get @, 'dragOverClass'

    if draggingClass? and jQuery.trim(draggingClass) isnt ''
      draggingSelector = ['.', draggingClass].join('')
      jQuery(draggingSelector).removeClass(draggingClass)

    if dragOverClass? and jQuery.trim(dragOverClass) isnt ''
      dragOverSelector = ['.', dragOverClass].join('')
      jQuery(dragOverSelector).removeClass(dragOverSelector)

    @trigger 'didDragEnd', e

  ###
    Handle the end of a drag interaction. Override with custom handling.

    @event didDragStart
  ###
  didDragStart: Ember.K

  ###
    Handle the end of a drag interaction. Override with custom handling.

    @event didDragEnd
  ###
  didDragEnd: Ember.K
