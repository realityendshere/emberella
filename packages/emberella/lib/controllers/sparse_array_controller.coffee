###
@module emberella
@submodule emberella-controllers
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set

###
  `Emberella.SparseArrayController` is a variation on an
  `Ember.ArrayController` that allows content to be lazily loaded from the
  persistence layer.

  @class SparseArrayController
  @namespace Emberella
  @extends Ember.ArrayProxy
###

Emberella.SparseArrayController = Ember.ArrayProxy.extend Ember.ControllerMixin,

  ###
    @private

    Stash a reference to the original content object.

    @property _content
    @type {Mixed}
    @default null
  ###
  _content: null

  ###
    @private

    Stash the potential total number of items as reported by the
    persistence layer.

    @property _length
    @type {Integer}
    @default null
  ###
  _length: null

  ###
    @property isSelectable
    @type Boolean
    @default true
    @final
  ###
  isSparseArrayController: true #quack like a duck

  ###
    The number of items to fetch together in a single request. Essentially,
    the "page size" of each query.

    @property rangeSize
    @type {Integer}
    @default 1
  ###
  rangeSize: 1

  ###
    Flag to indicate if this controller should attempt to fetch data.

    @property shouldRequestObjects
    @type {Boolean}
    @default true
  ###
  shouldRequestObjects: true

  ###
    Alias to `content` property. Override to customize the behavior of
    content referencing.

    @property sparseContent
  ###
  sparseContent: Ember.computed.alias('content')

  ###
    The total number of potential items in the sparse array. If the length is
    unknown, requesting this property will cause the controller to try to fetch
    the total length from the persistence layer.

    @property length
    @type {Integer}
    @default 0
    @readOnly
  ###
  length: Ember.computed ->
    ret = get(@, '_length')
    @requestLength() if Ember.isEmpty(ret)
    get(@, '_length') || 0
  .property('_length').readOnly()

  ###
    True if this controller instance is attempting to fetch its length.

    @property isRequestingLength
    @type {Boolean}
    @default false
  ###
  isRequestingLength: null

  ###
    True if this controller instance is attempting to fetch its length.

    @property isUpdating
    @type {Boolean}
    @default false
  ###
  # TODO: expand to become true when any data being fetched.
  isUpdating: Ember.computed ->
    !!(get(@, 'isRequestingLength'))
  .property('isRequestingLength')

  init: ->
    @_TMP_OBJECT = isSparseArrayItem: true, isStale: true
    @_TMP_PROVIDE_ARRAY = []
    @_TMP_PROVIDE_RANGE = length: 1
    @_TMP_RANGE = {}
    @_super()

  ###
    Return the content in array format.

    @method toArray
    @return {Array}
  ###
  toArray: ->
    sparseContent = get(@, 'sparseContent')
    return Ember.A() unless sparseContent
    sparseContent.toArray()

  ###
    Check the content to see if a valid, non-stale object is available at the
    provided index.

    @method isObjectAt
    @param {Integer} idx The index to check for object existence
    @return {Boolean}
  ###
  isObjectAt: (idx) ->
    result = @objectAt(idx, true)
    !!(result and result.isStale isnt true)

  ###
    Get the data from the specified index.

    If an object is found at a given index, it will be returned immediately.

    Otherwise, a "stale" placeholder object will be returned and a new remote
    query to fetch the data for the given index will be created.

    @method objectAt
    @param {Integer} idx The index to obtain content for
    @param {Boolean} dontFetch Won't obtain remote data if `true`
    @return {Object}
  ###
  objectAt: (idx, dontFetch = !get(@, 'shouldRequestObjects')) ->
    idx = parseInt idx, 10
    return undefined if (isNaN(idx) or (idx < 0) or (idx >= get(@, 'length')))
    result = @_super(idx) ? @insertSparseArrayItem(idx)
    return result if (result and result.isStale isnt true) or dontFetch
    @requestObjectAt(idx)

  ###
    Fetches data at the specified index. If `rangeSize` is greater than 1, this
    method will also retrieve adjacent items to form a "page" of results.

    @method requestObjectAt
    @param {Integer} idx The index to fetch content for
    @return {Object|Null} A placeholder object or null if content is empty
  ###
  requestObjectAt: (idx) ->
    content = get(@, 'content')
    rangeSize = parseInt(get(@, 'rangeSize'), 10) || 1

    return null unless content?

    start = Math.floor(idx / rangeSize) * rangeSize
    start = Math.max start, 0
    placeholders = Math.min((start + rangeSize), get(@, 'length'))
    @insertSparseArrayItems([start...placeholders])

    if @didRequestRange isnt Ember.K
      range = @_TMP_RANGE
      range.start = start
      range.length = rangeSize
      @_didRequestRange(range)
    else
      @_didRequestIndex(i) for i in [start...rangeSize]

    get(@, 'sparseContent')[idx]

  ###
    Fetches data regarding the total number of objects in the
    persistence layer.

    @method requestLength
    @return {Integer} The current known length
  ###
  requestLength: ->
    len = get(@, '_length')

    unless (@didRequestLength is Ember.K) or get(@, 'isRequestingLength')
      set @, 'isRequestingLength', true
      @_didRequestLength()
      return len

    get(@, '_content.length')

  ###
    Empty the sparse array.

    @method reset
    @chainable
  ###
  reset: ->
    @beginPropertyChanges()
    len = get(@, '_length')
    @_clearSparseContent()
    set(@, '_length', len)
    @endPropertyChanges()
    @

  ###
    Uncache the item at the specified index.

    @method unset
    @param {Integer} idx The index to unset
    @chainable
  ###
  unset: (idx) ->
    return @ unless idx?
    sparseContent = get(@, 'sparseContent')
    sparseContent[idx] = undefined
    @

  ###
    Remove the item at the specified index.

    @method removeObject
    @param {Mixed} obj The object to remove from the content
    @chainable
  ###
  removeObject: (obj) ->
    # Ember's standard `removeObject` method will try to fetch all available
    # data when attempting to remove an object. Disable data fetching to
    # prevent excessive (and slow) remote queries
    shouldRequestObjects = get @, 'shouldRequestObjects'
    @disableRequests()
    @_super obj
    @enableRequests() if shouldRequestObjects
    @

  ###
    Enable data fetching.

    @method enableRequests
    @chainable
  ###
  enableRequests: ->
    set(@, 'shouldRequestObjects', true)
    @

  ###
    Disable data fetching.

    @method disableRequests
    @chainable
  ###
  disableRequests: ->
    set(@, 'shouldRequestObjects', false)
    @

  #INJECT PLACEHOLDER OBJECTS

  ###
    Insert a placeholder object at the specified index.

    @method insertSparseArrayItem
    @param {Integer} idx Where to inject a placeholder
    @param {Boolean} force If true, placeholder replaces existing content
    @return {Object}
  ###
  insertSparseArrayItem: (idx, force = false) ->
    sparseContent = get(@, 'sparseContent')
    proxy = Ember.copy(@_TMP_OBJECT)
    proxy.contentIndex = idx
    sparseContent[idx] = proxy if force or !sparseContent[idx]?
    sparseContent[idx]

  ###
    Insert placeholder objects at the specified indexes.

    @method insertSparseArrayItems
    @param {Integer|Array} idx Multiple indexes
    @chainable
  ###
  insertSparseArrayItems: (idx...) ->
    @insertSparseArrayItem(i) for i in [].concat.apply([], idx)
    @

  # CALLBACK METHODS FOR LOADING FETCHED DATA

  ###
    Async callback to provide total number of objects available to this
    controller stored in the persistence layer.

    @method provideLength
    @param {Integer} length The total number of available objects
    @chainable
  ###
  provideLength: (length) ->
    set @, '_length', length
    set @, 'isRequestingLength', false
    @

  ###
    Async callback to provide objects in a specific range.

    @method provideObjectsInRange
    @param {Object} [range] A range object
      @param {Integer} [range.start]
        The index at which objects should be inserted into the content array
      @param {Integer} [range.length]
        The number of items to replace with the updated data
    @param {Array} array The data to inject into the sparse array
    @chainable
  ###
  provideObjectsInRange: (range, array) ->
    sparseContent = get(@, 'sparseContent')
    sparseContent.replace(range.start, range.length, array)
    @

  ###
    Async callback to provide an object at a specific index.

    Ultimately, this method calls `provideObjectsInRange`. Override
    `provideObjectsInRange` to inject custom behavior.

    @method provideObjectAtIndex
    @param {Integer} idx The index to insert data at
    @param {Object} obj The object to insert
    @chainable
  ###
  provideObjectAtIndex: (idx, obj) ->
    array = @_TMP_PROVIDE_ARRAY
    range = @_TMP_PROVIDE_RANGE
    array[0] = obj
    range.start = idx
    @provideObjectsInRange(range, array)

  # OVERRIDE ARRAY PROXY METHODS FOR CONTENT

  ###
    Hook for responding to impending updates to the content array. Override to
    add custom handling for array updates.

    @method contentArrayWillChange
    @param {Array} array The array instance being updated
    @param {Integer} idx The index where changes applied
    @param {Integer} removedCount
    @param {Integer} addedCount
  ###
  contentArrayWillChange: (array, idx, removedCount, addedCount) ->
    @

  ###
    Hook for responding to updates to the content array. Override to
    add custom handling for array updates.

    @method contentArrayWillChange
    @param {Array} array The array instance being updated
    @param {Integer} idx The index where changes applied
    @param {Integer} removedCount
    @param {Integer} addedCount
  ###
  contentArrayDidChange: (array, idx, removedCount, addedCount) ->
    @

  ###
    @private

    Override Ember's `_contentWillChange` to observe `_content`.

    @method _contentWillChange
  ###
  _contentWillChange: Ember.beforeObserver ->
    @_super()
  , '_content'

  ###
    @private

    Override Ember's `_contentDidChange` to observe `_content` and `content`.

    @method _contentDidChange
  ###
  _contentDidChange: Ember.observer ->
    @_super()
  , 'content', '_content'

  ###
    @private

    Move any array set to the `content` property to the `_content` property.

    This allows `content` to be used for referencing the sparse array while
    retaining a reference to the originally provided content object.

    @method _setupContent
    @return {Array} The sparse array
  ###
  _setupContent: ->
    controller = @
    _content = get(controller, 'content')

    return if _content and _content.isSparseArray

    if _content
      _content.addArrayObserver(controller,
        willChange: "contentArrayWillChange"
        didChange: "contentArrayDidChange"
      )

    sparseContent = Ember.A((_content and _content.slice()) ? [])
    sparseContent.isSparseArray = true
    set controller, '_content', _content
    set controller, 'sparseContent', sparseContent
    sparseContent

  ###
    @private

    Remove observers from `_content`.

    @method _teardownContent
    @return null
  ###
  _teardownContent: ->
    controller = @
    _content = get(controller, '_content')

    if _content
      _content.removeArrayObserver(controller,
        willChange: "contentArrayWillChange"
        didChange: "contentArrayDidChange"
      )

    null

  ###
    @private

    Set reported length to `content.total` if it changes.

    @method _contentTotalChanged
    @chainable
  ###
  _contentTotalChanged: Ember.observer ->
    set @, '_length', get(@, 'content.total')
    @
  , 'content.total'

  # SPARSE CONTENT SETUP/EVENTS

  ###
    Hook for responding to the sparse array being replaced with a new
    array instance. Override to add custom handling.

    @method sparseContentWillChange
    @param {Object} self
  ###
  sparseContentWillChange: Ember.K

  ###
    Hook for responding to the sparse array being replaced with a new
    array instance. Override to add custom handling.

    @method sparseContentDidChange
    @param {Object} self
  ###
  sparseContentDidChange: Ember.K

  ###
    Hook for injecting custom behavior when an item in the sparse array gets
    replaced with new data.

    @method sparseContentDidChange
    @param {Object} item The previous value
    @param {Object} addedObject The new value
  ###
  didReplaceSparseArrayItem: Ember.K

  ###
    Hook for responding to impending updates to the sparse array. Extend to
    add custom handling for array updates.

    @method sparseContentArrayWillChange
    @param {Array} array The array instance being updated
    @param {Integer} idx The index where changes applied
    @param {Integer} removedCount
    @param {Integer} addedCount
  ###
  sparseContentArrayWillChange: (array, idx, removedCount, addedCount) ->
    @_PREVIOUS_SPARSE_CONTENT = array.slice(idx, idx + removedCount)
    @

  ###
    Hook for responding to updates to the sparse array. Extend to
    add custom handling for array updates.

    @method sparseContentArrayDidChange
    @param {Array} array The array instance being updated
    @param {Integer} idx The index where changes applied
    @param {Integer} removedCount
    @param {Integer} addedCount
  ###
  sparseContentArrayDidChange: (array, idx, removedCount, addedCount) ->
    removedObjects = @_PREVIOUS_SPARSE_CONTENT ? Ember.A()
    addedObjects = array.slice(idx, idx + addedCount)

    # Calculate delta with length properties of actual arrays
    # More accurate than using addedCount and removedCount
    delta = (addedObjects?.length || 0) - (removedObjects?.length || 0)
    set(@, '_length', get(@, '_length') + delta)
    for item, i in removedObjects
      @didReplaceSparseArrayItem(item, addedObjects[i]) if item and item.isSparseArrayItem
    @_PREVIOUS_SPARSE_CONTENT = null
    @

  ###
    @private

    Sparse array change handler.

    @method _sparseContentWillChange
  ###
  _sparseContentWillChange: Ember.beforeObserver ->
    sparseContent = get(@, 'sparseContent')
    len = if sparseContent then get(sparseContent, 'length') else 0

    @sparseContentArrayWillChange @, 0, len, undefined
    @sparseContentWillChange @
    @_teardownSparseContent sparseContent
  , 'sparseContent'

  ###
    @private

    Sparse array change handler.

    @method _sparseContentDidChange
  ###
  _sparseContentDidChange: Ember.observer ->
    sparseContent = get(@, 'sparseContent')
    len = if sparseContent then get(sparseContent, 'length') else 0

    @_setupSparseContent sparseContent
    @sparseContentDidChange @
    @sparseContentArrayDidChange @, 0, undefined, len
  , 'sparseContent'

  ###
    @private

    Remove change observing on sparse array.

    @method _teardownSparseContent
  ###
  _teardownSparseContent: ->
    @_clearSparseContent()
    sparseContent = get(@, 'sparseContent')
    if sparseContent
      sparseContent.removeArrayObserver @,
        willChange: 'sparseContentArrayWillChange',
        didChange: 'sparseContentArrayDidChange'

  ###
    @private

    Add change observing on sparse array.

    @method _setupSparseContent
  ###
  _setupSparseContent: ->
    sparseContent = get(@, 'sparseContent')
    if sparseContent
      sparseContent.addArrayObserver @,
        willChange: 'sparseContentArrayWillChange',
        didChange: 'sparseContentArrayDidChange'
    @_lengthDidChange()

  ###
    @private

    Set the sparse array's length to the controller's length.

    @method _lengthDidChange
  ###
  _lengthDidChange: Ember.observer ->
    length = get(@, 'length') ? 0
    sparseContent = get(@, 'sparseContent')
    sparseContent.length = length if Ember.isArray(sparseContent) and sparseContent.isSparseArray and sparseContent.length isnt length
  , 'length'

  ###
    @private

    Empty the sparse array.

    @method _clearSparseContent
  ###
  _clearSparseContent: ->
    sparseContent = get(@, 'sparseContent')
    sparseContent.clear() if sparseContent and sparseContent.isSparseArray
    @

  ###
    Called before controller destruction.

    @method willDestroy
  ###
  willDestroy: ->
    @_super()
    @_teardownSparseContent()

  # DATA FETCHING

  ###
    Hook for single object requests. Override this method to enable this
    controller to obtain a single persisted object.

    If the request is successful, insert the fetched object into the sparse
    array using the `provideObjectAtIndex` method.

    @method didRequestIndex
    @param {Integer} idx
  ###
  didRequestIndex: Ember.K

  ###
    Hook for range requests. Override this method to enable this controller
    to obtain a page of persisted data.

    If the request is successful, insert the fetched objects into the sparse
    array using the `provideObjectsInRange` method.

    @method didRequestRange
    @param {Object} [range] A range object
      @param {Integer} [range.start]
        The index to fetch
      @param {Integer} [range.length]
        The number of items to fetch
  ###
  didRequestRange: Ember.K

  ###
    Hook for initiating requests for the total number of objects available to
    this controller in the persistence layer. Override this method to enable
    this controller to obtain its length.

    If the request is successful, set the length of this sparse array
    controller using the `provideLength` method.

    @method didRequestLength
  ###
  didRequestLength: Ember.K

  ###
    @private

    Prevents the controller from continuously attempting to fetch data for
    objects that are already in the process of being fetched.

    @method _markSparseArrayItemInProgress
    @param {Integer} idx The index of the object to place into a loading state
  ###
  _markSparseArrayItemInProgress: (idx) ->
    sparseContent = get(@, 'sparseContent')
    return unless sparseContent and Ember.typeOf sparseContent is 'array'
    item = sparseContent[idx]
    item.isStale = false if item and item.isStale
    item

  ###
    @private

    Prepare to fetch a page of data from the persistence layer.

    @method _didRequestRange
    @param {Object} [range] A range object
      @param {Integer} [range.start]
        The index to fetch
      @param {Integer} [range.length]
        The number of items to fetch
  ###
  _didRequestRange: (range) ->
    @_markSparseArrayItemInProgress(idx) for idx in [range.start...(range.start + range.length)]
    @didRequestRange(range)

  ###
    @private

    Prepare to fetch a single object from the persistence layer.

    @method _didRequestIndex
    @param {Integer} idx
  ###
  _didRequestIndex: (idx) ->
    @_markSparseArrayItemInProgress(idx)
    @didRequestIndex(idx)

  ###
    @private

    Prepare to fetch the total number of available objects from the
    persistence layer.

    @method _didRequestLength
  ###
  _didRequestLength: ->
    @didRequestLength()
