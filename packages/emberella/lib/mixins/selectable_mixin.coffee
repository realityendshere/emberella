###
@module emberella
@submodule emberella-mixins
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set
guidFor = Ember.guidFor
typeOf = Ember.typeOf

###
  `Emberella.SelectableMixin` adds selection support to array controllers.

  This mixin is rough around the edges and is not verified to work
  across browsers.

  @class SelectableMixin
  @namespace Emberella
###

Emberella.SelectableMixin = Ember.Mixin.create
  ###
    @property isSelectable
    @type Boolean
    @default true
    @final
  ###
  isSelectable: true #quack like a duck

  init: ->
    set @, '_selection', new Emberella.SelectionSet()
    get @, 'selection'
    @_super()

  actions: {
    select: -> @select.apply @, arguments
    next: -> @next.apply @, arguments
    previous: -> @previous.apply @, arguments
  }

  # allowsSelection: true #TODO: Enable this setting

  # allowsMultipleSelection: true #TODO: Enable this setting

  # allowsEmptySelection: true #TODO: Enable this setting

  ###
    A member of the content array. When expanding the selection, the selection
    will typically expand using the index of this object.

    @property cursor
    @type Object
    @default null
  ###
  cursor: null

  ###
    @private

    The complete set of all currently selected items.

    @property _selection
    @type Set
    @default null
  ###
  _selection: null

  ###
    The "active" selection: an array of items selected by the user that are
    also present in the content array. This allows the selection to be retained
    even if, for example, a filter removes a selected object from the `content`
    property. When the filter is removed, the previously selected object will,
    once again, appear to be selected.

    @property selection
    @type Array
    @default []
  ###
  # TODO: Fix excessive array creation
  selection: Ember.computed ->
    content = @getActiveContent()
    selection = get(@, '_selection')
    selection.filter((item) -> content.contains(item))
  .property('_selection.[]', 'content', 'arrangedContent.[]')

  ###
    The first member of the content array that would be a valid selection. The
    default behavior is to simply use the first item in the content array.
    Override this property with validation checks as needed.

    @property firstSelectableObject
    @type Object
  ###
  firstSelectableObject: Ember.computed ->
    get(@, 'firstObject')
  .property 'firstObject'

  ###
    The last member of the content array that would be a valid selection. The
    default behavior is to simply use the last item in the content array.
    Override this property with validation checks as needed.

    @property firstSelectableObject
    @type Object
  ###
  lastSelectableObject: Ember.computed ->
    get(@, 'lastObject')
  .property 'lastObject'

  ###
    Retrieve an array of items that could appear in the active selection.

    The default behavior is simply to return the `content` array. Override this
    method to introduce custom retrieval or assembly of the array of
    potentially selectable items.

    @method getActiveContent
    @return Array
  ###
  getActiveContent: ->
    get(@, 'content')

  ###
    Manipulate the selection set.

    Typically, this method will empty the selection set and add the specified
    item to the selection.

    Optionally, the selection status of a given item can be toggled or all
    items between the cursor and the specified item can be selected.

    @method select
    @param {Object|Integer} item The object or index to select
    @param {Object} [options] Expand or toggle the selection
      @param {Boolean} [options.toggle]
        If true, the item's selection state will be toggled.
      @param {Boolean} [options.range]
        If true, all items between the item and the cursor (inclusive) will be
        added to the selection.
    @chainable
  ###
  select: (item, options) ->
    options = options ? {}

    item = @objectAt(parseInt(item, 10)) if typeOf(item) is 'number'
    toggle = get(options, 'toggle')
    range = get(options, 'range')
    retainSelection = get(options, 'retainSelection')

    if toggle or range
      if toggle
        if @inSelection(item) then @deselectObject(item) else @selectObject(item)
      else if range
        targetIdx = +@indexOf(item)
        indexOfCursor = @indexOfCursor()
        start = Math.min(targetIdx, indexOfCursor)
        end = Math.max(targetIdx, indexOfCursor)
        selectionRange = [start..end]
        @selectObjects(selectionRange)
    else
      Ember.beginPropertyChanges(@)
      @deselectAll() unless retainSelection
      @selectObject(item)
      Ember.endPropertyChanges(@)

    @

  ###
    Check an item to see if it can be selected.

    @method isSelectableObject
    @param {Mixed} obj The item to check
    @return {Boolean}
  ###
  isSelectableObject: (obj) ->
    type = typeOf obj
    !!(obj and (type is 'instance' or type is 'object'))

  ###
    Add an item to the selection.

    @method selectObject
    @param {Object|Integer} item The object or index to select
    @chainable
  ###
  selectObject: (item) ->
    item = @objectAt(parseInt(item, 10)) if typeOf(item) is 'number'
    if @isSelectableObject(item)
      get(@, '_selection').addObject(item)
      set(@, 'cursor', item)
    @

  ###
    Add multiple items to the selection.

    @method selectObjects
    @param {Array} items Items or indexes to select
    @chainable
  ###
  selectObjects: (items...) ->
    items = [].concat.apply([], items)
    Ember.beginPropertyChanges(@)
    @selectObject(item) for item in items
    Ember.endPropertyChanges(@)
    @

  ###
    Add all items to the selection.

    @method selectAll
    @chainable
  ###
  #TODO: Boost performance. Select All can feel quite slow.
  selectAll: ->
    @selectObjects([0...get(@, 'length')])
    @

  ###
    Swap a selected item with another item. Useful if the content contains
    proxies or placeholders that must eventually be swapped.

    @method selectInstead
    @param {Object} current The item to replace
    @param {Object} replacement The new item
    @chainable
  ###
  selectInstead: (current, replacement) ->
    @deselectObjects(current).selectObjects(replacement) if @inSelection(current)
    @

  ###
    Alias to `deselectObject`.

    @method deselect
    @param {Object|Integer} item The item or indexes to remove from the selection
    @chainable
  ###
  deselect: Ember.aliasMethod('deselectObjects')

  ###
    Remove the specified item from the selection set.

    @method deselectObject
    @param {Object|Integer} item The item or indexes to remove from the selection
    @chainable
  ###
  deselectObject: (item) ->
    item = @objectAt(parseInt(item, 10), true) if typeOf(item) is 'number'
    get(@, '_selection').removeObject(item)
    set(@, 'cursor', item) if @isSelectableObject item
    @

  ###
    Remove multiple items from the selection.

    @method deselectObjects
    @param {Array} items Items or indexes to deselect
    @chainable
  ###
  deselectObjects: (items...) ->
    items = [].concat.apply([], items)
    Ember.beginPropertyChanges(@)
    @deselectObject(item) for item in items
    Ember.endPropertyChanges(@)
    @

  ###
    Clear the selection set.

    @method deselectAll
    @chainable
  ###
  deselectAll: ->
    get(@, '_selection').clear()
    @

  ###
    Determine if a given object is present in the selection set.

    @method inSelection
    @param {Mixed} obj Object to search for
    @return {Boolean}
  ###
  inSelection: (obj) ->
    get(@, '_selection').contains(obj)

  ###
    Remove all actively selected objects from the content array.

    @method removeSelection
    @chainable
  ###
  removeSelection: ->
    selection = get(@, 'selection')
    @removeObjects selection
    @deselectObjects selection
    @

  ###
    Based on the arrangement of items in the content array, `indexOfSelection`
    creates an object with `first`, `last`, and `indexes` attributes.

    `first`:   The index of the selected item closest to the beginning of the
               content array.

    `last`:    The index of the selected item closest to the end of the
               content array.

    `indexes`: An array of integers representing each selected item's position
               in the content array.

    @example
      //Returned object
      {
        first: 3,
        last: 12,
        indexes: [5, 9, 12, 3, 10]
      }

    @method indexOfSelection
    @param content Array to search for current selection
    @return {Object|Boolean} `false` if nothing selected
  ###
  indexOfSelection: (content = get(@, 'arrangedContent').toArray()) ->
    result = indexes: Ember.A(), first: null, last: null
    selection = get(@, 'selection')

    return false if selection.length is 0 or !Ember.isArray(content)

    for selected in selection
      idx = content.indexOf selected
      result.first = idx if !result.first? or idx < result.first
      result.last = idx if !result.last? or idx > result.last
      result.indexes.push idx

    result

  ###
    Move the selection forward from the last selected index.

    @method next
    @param {Boolean} expandSelection
    @param {Integer} count How far forward to move the selection
    @chainable
  ###
  next: (expandSelection = false, count = 1) ->
    len = get(@, 'length')
    indices = @indexOfSelection()
    firstIdx = +@indexOf(get(@, 'firstSelectableObject'))

    if indices
      targetIdx = indices.last + count
      itemsMod = (len % count) || count # how many items on the last "row"

      # if last selected item is in last "row", don't move
      targetIdx = if indices.last >= (len - itemsMod) then indices.last else targetIdx

      # if target is out of bounds, select last item
      targetIdx = if targetIdx >= len and targetIdx < (len + count) then len - 1 else targetIdx
    else
      targetIdx = firstIdx

    @select(@objectAt(targetIdx), {range: expandSelection})

  ###
    Move the selection back from the first selected index.

    @method previous
    @param {Boolean} expandSelection
    @param {Integer} count How far back to move the selection
    @chainable
  ###
  previous: (expandSelection = false, count = 1) ->
    len = get(@, 'length')
    indices = @indexOfSelection()
    lastIdx = +@indexOf(get(@, 'lastSelectableObject'))

    if indices
      targetIdx = indices.first - count
      targetIdx = if indices.first < count then indices.first else targetIdx
    else
      targetIdx = lastIdx

    @select(@objectAt(targetIdx), {range: expandSelection})

  ###
    Find the position of the cursor object.

    @method indexOfCursor
    @return {Integer}
  ###
  indexOfCursor: ->
    +@indexOf(@get('cursor'))

  # SELECTION ARRAY SETUP/EVENTS

  ###
    Hook for responding to impending updates to the selection set. Override to
    add custom handling for selection set updates.

    @method selectionSetWillChange
  ###
  selectionSetWillChange: Ember.K

  ###
    Hook for responding to updates to the selection set. Override to
    add custom handling for selection set updates.

    @method selectionSetDidChange
  ###
  selectionSetDidChange: Ember.K

  ###
    Hook for responding to the selection set being replaced with a different
    selection set instance. Override to add custom handling.

    @method selectionWillChange
    @param {Object} self
  ###
  selectionWillChange: Ember.K

  ###
    Hook for responding to the selection set being replaced with a different
    selection set instance. Override to add custom handling.

    @method selectionDidChange
    @param {Object} self
  ###
  selectionDidChange: Ember.K

  ###
    @private

    Handle a complete swap of the selection set.

    @method _selectionWillChange
  ###
  _selectionWillChange: Ember.beforeObserver ->
    selection = get(@, '_selection')
    len = if selection then get(selection, 'length') else 0

    @selectionSetWillChange @, 0, len, undefined
    @selectionWillChange @
    @_teardownSelection selection
  , '_selection'

  ###
    @private

    Handle a complete swap of the selection set.

    @method _selectionDidChange
  ###
  _selectionDidChange: Ember.observer ->
    selection = get(@, '_selection')
    len = if selection then get(selection, 'length') else 0

    @_setupSelection selection
    @selectionDidChange @
    @selectionSetDidChange @, 0, undefined, len
  , '_selection'

  ###
    @private

    Begin observing for updates to the selection set.

    @method _setupSelection
  ###
  _setupSelection: ->
    selection = get(@, '_selection')
    if selection
      selection.addEnumerableObserver @,
        willChange: 'selectionSetWillChange',
        didChange: 'selectionSetDidChange'

  ###
    @private

    Discontinue observing of updates to the selection set.

    @method _setupSelection
  ###
  _teardownSelection: ->
    selection = get(@, '_selection')
    if selection
      selection.removeEnumerableObserver @,
        willChange: 'selectionSetWillChange',
        didChange: 'selectionSetDidChange'

  ###
    Called before destruction of the host object.

    @method willDestroy
  ###
  willDestroy: ->
    @_super()
    @_teardownSelection()

###
  `Emberella.SelectionSet` an `Ember.Set` that maps the `nextObject` method
  to `objectAt`.

  @class SelectionSet
  @namespace Emberella
  @extends Ember.Set
###
Emberella.SelectionSet = Ember.Set.extend
  ###
    Alias for `nextObject`.

    @method objectAt
  ###
  objectAt: Ember.aliasMethod('nextObject')
