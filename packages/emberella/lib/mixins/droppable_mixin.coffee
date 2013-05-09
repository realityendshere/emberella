###
@module emberella
@submodule emberella-mixins
###

Emberella = window.Emberella
jQuery = window.jQuery
get = Ember.get
set = Ember.set
VIEW_TYPE = 'view'

###
  `Emberella.DroppableMixin` adds drop event handling to a view class.

  The mixin will attempt to call a large variety of methods on the bound
  controller depending on the type(s) of item dropped on the view. For example,
  dropping a file on the view will send a `didDropFiles` message to the
  controller along with messages like `didDropRichText` and many others.

  Dropping another view onto a drop zone will cause the dropped view's content
  to be examined and transformed into a method call such as `didDropThumbnail`
  or `didDropPerson`.

  Similar method calls will be made for `dragEnter`, `dragOver`, and
  `dragLeave` events (e.g. `didDragEnterThumbnail`, `didDragOverThumbnail`,
  `didDragLeaveThumbnail`).

  In development, Ember will throw warnings if this mixin sends messages that
  are unhandeld.

  This mixin is rough around the edges and is not verified to work
  across browsers.

  TODO: Refactor.
  TODO: Improve examples and documentation.

  @class DroppableMixin
  @namespace Emberella
###

Emberella.DroppableMixin = Ember.Mixin.create
  ###
    @property isDroppable
    @type Boolean
    @default true
    @final
  ###
  isDroppable: true # quack like a duck

  ###
    The class name to apply to the element with an item dragged over it.

    @property dragOverClass
    @type String
    @default 'dragover'
  ###
  dragOverClass: 'dragover'

  ###
    Handle the DOM's `dragEnter` event. This event is triggered as a dragged
    item crosses into the host view's "airspace."

    @event dragEnter
  ###
  dragEnter: (e) ->
    e.stopPropagation()
    e.preventDefault()
    @_findScrollableParent()
    @_droppableCallMethodForEvent(e, 'didDragEnter') unless @didDragEnter(e) is false

  ###
    Handle the DOM's `dragOver` event. This event is triggered as a dragged
    item moves around over the host view.

    @event dragOver
  ###
  dragOver: (e) ->
    e.stopPropagation()
    e.preventDefault()
    $target = jQuery(e.currentTarget)

    #remove the dragOverClass from all elements
    @clearDragOverClass()

    #add dragOverClass to this element
    $target.addClass(get(@, 'dragOverClass'))

    #inject custom handling in the didDragOver hook
    #return false to interrupt event handling
    unless @didDragOver(e) is false
      @_scrollDropTarget(e)
      @_droppableCallMethodForEvent(e, 'didDragOver')

  ###
    Handle the DOM's `dragLeave` event. This event is triggered as a dragged
    item crosses out of the host view's "airspace."

    @event dragLeave
  ###
  dragLeave: (e) ->
    e.stopPropagation()
    e.preventDefault()
    $target = jQuery(e.currentTarget)
    $target.removeClass(get(@, 'dragOverClass'))
    @_droppableCallMethodForEvent(e, 'didDragLeave') unless @didDragLeave(e) is false

  ###
    Handle the DOM's `drop` event.

    @event drop
  ###
  drop: (e) ->
    e.stopPropagation()
    e.preventDefault()
    @clearDragOverClass()
    @_droppableCallMethodForEvent(e, 'didDrop') unless @didDrop(e) is false

  ###
    Remove the `dragOverClass` from all droppable elements.

    @method clearDragOverClass
    @chainable
  ###
  clearDragOverClass: ->
    selector = ['.', get(@, 'dragOverClass')].join('')
    jQuery(selector).removeClass(get(@, 'dragOverClass'))
    @

  ###
    @private

    Call methods to handle the type(s) of item(s) dropped on the host view.

    @method _droppableCallMethodForEvent
    @return null
  ###
  _droppableCallMethodForEvent: (e, prefix) ->
    return unless e

    files = e.dataTransfer.files
    types = e.dataTransfer.types

    if types
      for type in types
        methodKey = @_droppableMethodNameForType(type, prefix)
        if type.toUpperCase() is 'FILES' and files.length > 0
          data = files
        else if type is VIEW_TYPE
          viewId = e.dataTransfer.getData(VIEW_TYPE)
          data = if jQuery.trim(viewId) is '' then Emberella.get('_draggableView') else Ember.View.views[viewId]
          return false if this is data
        else
          data = e.dataTransfer.getData(type)
        Ember.tryInvoke(@, methodKey, [e, data, !!(files.length)])

    null

  ###
    @private

    Create a method name for the type of item using a specified prefix.

    @method _droppableMethodNameForType
    @return String
  ###
  _droppableMethodNameForType: (type, prefix) ->
    methodKey = prefix || ''
    stringParts = type.split(/[^a-z0-9]+/i)
    for part in stringParts
      methodKey = methodKey + part.charAt(0).toUpperCase() + part.slice(1)
    methodKey

  ###
    @private

    Send a message to the bound controller regarding the type of item being
    dragged/dropped and the event being performed to it.

    @method _sendDroppableMessage
    @return null
  ###
  _sendDroppableMessage: (e, view, prefix) ->
    return unless view
    e.droppableItem = view && view.get('content')
    e.droppableTarget = @get('content')
    e.droppableSelection = view && view.get('parentView.selection')
    e.droppableView = view
    message = [prefix, @_extractDroppableItemName(e.droppableItem)].join('')
    viewMethodResult = Ember.tryInvoke(@, message, [e]) # stop here with an instance message handler that returns false
    unless viewMethodResult is false
      @get('controller').send(message, e)
    null

  ###
    @private

    Find the name of the object being dropped.

    @method _extractDroppableItemName
    @return String
  ###
  _extractDroppableItemName: (item) ->
    if item and jQuery.isFunction(item.getTypeString) then item.getTypeString() else @_nameForType(item.constructor)

  ###
    @private

    Find the name of the object being dropped.

    @method _nameForType
    @return String
  ###
  _nameForType: (type) ->
    typeString = type.toString()
    parts = typeString.split('.')
    parts[parts.length - 1]

  ###
    @private

    Look for a parent view that may require scrolling.

    @method _findScrollableParent
    @return jQuery|Null
  ###
  _findScrollableParent: ->
    $scrollable = false
    $testEl = @$()

    while $scrollable is false
      $scrollable = $testEl if $testEl.prop('scrollHeight') > $testEl.prop('clientHeight') or $testEl.size() is 0
      $testEl = $testEl.parent()

    scrollable = if $scrollable.size() then $scrollable else null
    set(@, 'scrollableParent', scrollable)
    scrollable

  ###
    @private

    Scroll if the `dragOver` event position is within 20px of the viewable
    portion of the scrolling area.

    @method _scrollDropTarget
    @return null
  ###
  _scrollDropTarget: (e) ->
    clientY = e.originalEvent.clientY
    adjustment = 0
    $scrollable = get(@, 'scrollableParent')

    return unless $scrollable

    scrollableOffsetTop = $scrollable.offset().top
    scrollableHeight = $scrollable.height()

    if (clientY - scrollableOffsetTop) < 20
      adjustment = -1 * (Math.pow(Math.abs(clientY - scrollableOffsetTop - 20), 1.6))

    if (scrollableOffsetTop + scrollableHeight - clientY) < 20
      adjustment = Math.pow(Math.abs((scrollableOffsetTop + scrollableHeight - clientY) - 20), 1.6)

    $scrollable.prop('scrollTop', $scrollable.prop('scrollTop') + adjustment)
    null

  didDragEnterView: (e, view) -> @_sendDroppableMessage(e, view, 'didDragEnter')
  didDragOverView: (e, view) -> @_sendDroppableMessage(e, view, 'didDragOver')
  didDragLeaveView: (e, view) -> @_sendDroppableMessage(e, view, 'didDragLeave')
  didDropView: (e, view) -> @_sendDroppableMessage(e, view, 'didDrop')

  didDropFiles: (e, files, areFiles) ->
    get(@, 'controller')?.send('didDropFiles', get(@, 'content'), files) if areFiles

  didDragEnter: (e) ->@
  didDragOver: (e) ->@
  didDragLeave: (e) ->@
  didDrop: (e) ->@
