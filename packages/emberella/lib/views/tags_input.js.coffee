#= require ../mixins/style_bindings
#= require ../mixins/focusable_mixin
#= require ../mixins/keyboard_control_mixin
#= require ../mixins/membership_mixin
#= require ./flexible_text_field

Emberella = window.Emberella
jQuery = window.jQuery
get = Ember.get
set = Ember.set
setProperties = Ember.setProperties
typeOf = Ember.typeOf

DEFAULT_DELIMITER = ','
ESCAPE_REG_EXP = /[\-\[\]{}()*+?.,\\\^$|#\s]/g
ESCAPE_REPLACEMENT = '\\$&'

###
  The aim of `Emberella.TagsInput` is to present users with an easy to use tag
  input and creation experience that approaches the quality of a desktop
  interaction pattern. Rather than simply instructing users to "split tags
  with a comma" in a plain text input, the `Emberella.TagsInput` creates
  distinctive listing views for each tag. Tags can also be used to represent
  complex objects. Thus this tags input view may be used to display an array of
  words or establish complex relationships between objects through text entry.

  To work with this input control, bind the `content` property to data
  represented as an array of strings or objects.

  With styling, the `Emberella.TagsInput` can nearly mimic the experience of
  entering email addresses in the "To:" field of Mac OS X Mail.

  TODO: Multi-select
  TODO: drag and drop rearrangement
  TODO: Improved handling for duplicate tags
  TODO: Code cleanup and refactor to allow tag UI to integrate into other
        views, perhaps as a mixin
  TODO: Multiple cursors to allow invalid tags to remain editable in place

  @class TagsInput
  @namespace Emberella
  @extends Ember.ContainerView
  @uses Ember.StyleBindingsMixin
  @uses Emberella.FocusableMixin
  @uses Emberella.KeyboardControlMixin
###
Emberella.TagsInput = Ember.ContainerView.extend Ember.StyleBindingsMixin, Emberella.FocusableMixin, Emberella.KeyboardControlMixin,
  # private bookkeeping properties
  _value: ''
  _cursor: 0

  init: ->
    ret = @_super()
    value = get(@, 'value')
    content = get(@, 'content')
    set(@, 'content', Ember.A()) unless Ember.isArray content
    set(@, '_value', value)
    @capture(value) if value?
    @_setupContent()
    @_renderList()
    ret

  ###
    Declares this view is a tags input view.

    @property isTagsInput
    @type Boolean
    @default true
    @final
  ###
  isTagsInput: true #quack like a duck

  ###
    Add the 'emberella-tags-input' class to the tag input element. Use this
    class to style your tag input.

    @property classNames
    @type Array
    @default ['emberella-tags-input']
  ###
  classNames: ['emberella-tags-input']
  classNameBindings: ['disabled']

  ###
    Binds the width and height styles to the properties of the same name.

    @property styleBindings
    @type Array
    @default ['width', 'height']
  ###
  styleBindings: ['width', 'height']

  ###
    Disables tag input when true.

    @property disabled
    @type Boolean
    @default false
  ###
  disabled: false

  ###
    The view class to use for each item listing. The default
    `Emberella.TagItemView` is already designed to provide a familiar
    interaction pattern to users. But, of course, you are welcome to
    override this property and provide your own custom tag listing class with
    adapted or entirely custom behavior.

    @property itemViewClass
    @type Ember.View
    @default Emberella.TagItemView
  ###
  itemViewClass: 'Emberella.TagItemView'

  ###
    The view class that allows users to enter new tags. The default
    `Emberella.TagItemInput` is a flexible text field designed to allow input
    directly at the beginning, middle, or end of a list of tags. You can
    override this property to install new or custom behavior to the
    input field.

    @property inputViewClass
    @type Ember.View
    @default Emberella.TagItemInput
  ###
  inputViewClass: 'Emberella.TagItemInput'

  ###
    The content of this tags input. The content may be an array of strings
    or objects.

    @property content
    @type Array
    @default null
  ###
  content: null

  ###
    A string representation of the input's `content`. If this view manages an
    array of strings (e.g. `['Ember', 'Javascript', 'Frontend', 'Code']`), then
    the value property can be seeded with a string value and will be updated
    as strings are added to and removed from the `content` array.

    If a tag instance expects to manage objects, the value will not be
    automatically updated as the content changes.

    In any case, updating the `value` will not cause any automatic updates to
    the `content` array.

    @property value
    @type String
    @default ''
  ###
  value: ''

  ###
    A delimiter to use when splitting or assembling tag values. This property
    can be set to a string or an array of strings and regular expressions.

    If the delimiter property is a string, it will be split into individual
    characters and each character will be used as a delimiter.

    @example
      // semi-colons (';'), colons (':'), and spaces (' ') will break string
      // values into tags.
      //
      // 'one; two: three four' -> ['one', 'two', 'three', 'four']
      this.set('delimiter', ';: ');

    If the delimiter property is an array of strings and regular expressions,
    then each member of the array will be used to split strings into tags.

    @example
      // commas(','), semi-colons (';'), and numbers (0-9) will break string
      // values into tags.
      //
      // 'one1 two;three,four' -> ['one', 'two', 'three', 'four']
      this.set('delimiter', [',', ';', /\d/]);

    If no delimiter is specified, the tags input will fallback to a comma (,)
    as the default delimiter.

    @property delimiter
    @type {String|Array}
    @default ','
  ###
  delimiter: DEFAULT_DELIMITER

  ###
    Prevent focus with TAB key.

    @property tabindex
    @type Integer
    @default -1
  ###
  tabindex: -1

  ###
    A width style for the tag input view.

    @property width
    @type {Integer|String}
    @default 'auto'
  ###
  width: 'auto'

  ###
    A height style for the tag input view.

    @property height
    @type {Integer|String}
    @default 'auto'
  ###
  height: 'auto'

  ###
    A placeholder to display when the input has no content.

    @property placeholder
    @type String
    @default ''
  ###
  placeholder: ''

  ###
    A string to display as the 'delete' button in the default tag listing
    template.

    @property deleteCharacter
    @type String
    @default 'x'
  ###
  deleteCharacter: 'x'

  ###
    A string to display as the "title" attribute of the "delete" button in the
    default tag listing template.

    @property deleteTitle
    @type String
    @default 'Remove tag'
  ###
  deleteTitle: 'Remove tag'

  ###
    Specifies if a tag should be created automatically when the tag input view
    instance loses focus.

    @property tagOnFocusOut
    @type Boolean
    @default true
  ###
  tagOnFocusOut: true

  ###
    The "get path" to follow to find a string to display in each tag listing.

    For example, if each item in this view's content array is an object
    structured like `{id: 1, label: 'Ember'}` and the `contentPath` is "label",
    then the tag listing for the sample item would appear with the word 'Ember'
    in the browser (i.e. the value of Ember.get(content, 'label')).

    If the `contentPath` is an empty string, the `content` property is expected
    to contain an array of strings.

    @property contentPath
    @type String
    @default ''
  ###
  contentPath: ''

  ###
    A collection of fuctions to use for applying special classes to each tag
    listing.

    Set the `stylist` property to an object where each key represents a
    class name to add to a tag listing view and each value is a function that
    returns a truthy value when key should be added as a class name. This
    allows tags with special meaning to be styled differently as needed.

    @example
      // Adds the class 'is-ember' to any tag listing view with a label
      // of 'ember'.
      this.set('stylist', {
        'is-ember': function (content) {
          return (Ember.get(content, 'label').toLowerCase() === 'ember');
        }
      });

    Each stylist function is called in the context of its tag listing
    view instance.

    @property stylist
    @type Object
    @default null
  ###
  stylist: null

  ###
    The default template for each tag item listing. Set the `template` property
    to inject a custom template for tag listing views.

    @property defaultTemplate
    @type Ember.Handlebars
    @final
  ###
  defaultTemplate: Ember.Handlebars.compile [
    '<span class="emberella-tag-item-content">{{view.displayContent}}</span>'
    '{{#unless view.disabled}}'
      '{{#if view.deleteCharacter}}'
        '<a href="#" {{bind-attr title="view.deleteTitle"}} {{action "removeSelf" target=view bubbles=false}}>{{view.deleteCharacter}}</a>'
      '{{/if}}'
    '{{/unless}}'
  ].join(' ')

  ###
    The primary delimiter is the first string or number in the `delimiter`
    property. If none of the delimiters is a string or number, a plain comma
    (',') will be used instead.

    The `_primary_delimiter` is used when converting an array of strings to a
    string value.

    @private
    @property _primary_delimiter
    @type String
    @readOnly
  ###
  _primary_delimiter: Ember.computed ->
    delimiter = get(@, 'delimiter')
    if typeOf(delimiter) is 'string' or typeOf(delimiter) is 'number'
      delimiter = delimiter + ''
      ret = get(delimiter, '0')
    else if Ember.isArray(delimiter)
      ret = delimiter.find((d) ->
        typeOf(d) is 'string' or typeOf(d) is 'number'
      )

    (ret || DEFAULT_DELIMITER) + ''
  .property('delimiter', 'delimiter.length').volatile().readOnly()

  ###
    This computed property converts the public `delimiter` setting into a
    string that can be transformed into a regular expression object.

    @private
    @property _delimiter
    @type String
    @readOnly
  ###
  _delimiter: Ember.computed ->
    delimiter = get(@, 'delimiter') || DEFAULT_DELIMITER

    if typeOf(delimiter) is 'string' or typeOf(delimiter) is 'number'
      delimiter = (delimiter + '').split('')

    if Ember.isArray(delimiter)
      delimiter = Ember.A(delimiter.slice()).map((item) =>
        if typeOf(item) is 'string' or typeOf(item) is 'number'
          return @_escapeRegExpString(item.toString())
        else if typeOf(item) is 'regexp'
          return item.toString().split('/').slice(1, -1).join('/')
        null
      ).compact()

    delimiter = Ember.A(@_escapeRegExpString(DEFAULT_DELIMITER)) unless Ember.isArray(delimiter)
    delimiter.join('|')
  .property('delimiter', 'delimiter.length').readOnly()

  ###
    Returns a regular expression object that can be used to split and
    manipulate strings and input values based on the specified `delimiter`
    property.

    @private
    @property _delimiter_pattern
    @type RegExp
    @readOnly
  ###
  _delimiter_pattern: Ember.computed ->
    new RegExp(get(@, '_delimiter'), 'g')
  .volatile().readOnly()

  ###
    The current cursor position (i.e. index of the input view among this tag
    input's child views).

    The computed property ensures the cursor position does not exceed the
    length of the tag input's content.

    @property cursor
    @type Integer
  ###
  cursor: Ember.computed (key, value) ->
    #getter
    if arguments.length is 1
      result = get(@, '_cursor')
      contentLength = get(@, 'content.length')
      return contentLength unless result?
      result = Math.max(0, Math.min(parseInt(result, 10), contentLength))
      return result

    #setter
    else
      set(@, '_cursor', value)
  .volatile()

  ###
    Insert a single new tag value into the `content` array at a given index.
    If no index is specified, the `cursor` position will be used instead.

    Before a tag is allowed into the `content` array, the `willAddValue()`
    method will be called. Tag addition will be aborted if `willAddValue()`
    returns `false`.

    After a tag is inserted into the `content`, the `didAddValue` event
    will be triggered. Override `didAddValue()` or add an event handler to
    inject custom logic for handling newly created tags.

    @method addTag
    @param {String|Object} value A value to insert into the content array
    @param Integer idx The position/index at which to insert the new value
    @chainable
  ###
  addTag: (value = '', idx = get(@, 'cursor')) ->
    type = typeOf(value)
    method = '_' + ['prepare', type, 'tag'].join('-').camelize()

    unless typeOf(@[method]) is 'function'
      throw new TypeError("Attempting to add tag of an unsupported type " + type)

    unless (value = @[method](value)) is false or @_willAddValue(value, idx) is false
      @insertContent(value, idx)
      @_didAddValue(value, idx)

    @

  ###
    Add an array of tags.

    @method addTags
    @param Array values Array of tags to add
    @chainable
  ###
  addTags: (values = Ember.A()) ->
    @beginPropertyChanges()

    cursor = get(@, 'cursor')

    for value, i in values
      @addTag(value, cursor + i)

    @endPropertyChanges()
    @

  ###
    Convert the provided string (or current input value) into an array of new
    tags and add them to the `content`.

    @method capture
    @param String value A value to capture (default: `inputView.value`)
    @param Boolean retainFocus The input should regain focus after render
    @chainable
  ###
  capture: (value, retainFocus = @isFocused()) ->
    inputValue = get(@, 'inputView.value')
    value = inputValue unless typeOf(value) is 'string'

    values = @tagify(value)
    len = get(@, 'content.length')

    @addTags(values)

    if len isnt get(@, 'content.length')
      Ember.run.schedule('afterRender', @, ->
        @reset() if value is inputValue
        @refocus(retainFocus)
      )

    @

  ###
    Determine if the provided string value is already represented as a tag in
    this input view.

    Exact matches will always return true. If no exact match is found, this
    method will use the `isEqual()` method to search for tag content that is
    equivalent to the provided value.

    @method contains
    @param String value A string to search for
    @return Boolean
  ###
  contains: (value) ->
    content = get(@, 'content')
    return false unless content?
    return true if content.contains value

    match = content.find((obj) =>
      # use overridable isEqual() method
      @isEqual value, obj
    )

    !!(match)

  ###
    Compare two tag values (typically a string and an object) to
    determine equivalency.

    For example, the string `"foo"` may be equivalent to the object
    `{"label": "foo"}` when managing a list of tags.

    Override with your own method to inject a custom comparison for strings
    and tag objects.

    @method isEqual
    @param {String|Object} value The needle
    @param Object tag An object from the content array
    @return Boolean
  ###
  isEqual: (value, tag) ->
    contentPath = get @, 'contentPath'
    value = get(value, contentPath) || value
    contentValue = get(tag, contentPath) || ''
    (value.toLowerCase? and contentValue.toLowerCase? and value.toLowerCase() is contentValue.toLowerCase())

  ###
    Place the input view before the specified view instance.

    @method cursorBefore
    @param Ember.View view The child view to place the cursor before
    @chainable
  ###
  cursorBefore: (view) ->
    @moveCursor view, -1

  ###
    Place the input view after the specified view instance.

    @method cursorAfter
    @param Ember.View view The child view to place the cursor after
    @chainable
  ###
  cursorAfter: (view) ->
    @moveCursor view

  ###
    Place the input view some distance after the specified view instance.

    Use a negative number to move the input to a lower index.

    @method moveCursor
    @param Ember.View view The child view to move the cursor from
    @param Integer shift How far to move focus
    @chainable
  ###
  moveCursor: (view, shift = 1) ->
    return @ unless view?
    cursor = get(@, 'cursor')
    childViews = get(@, 'childViews')
    idx = childViews.indexOf view
    shift = shift - 1 if idx > cursor
    set(@, 'cursor', idx + shift)
    @refocus(true, (shift < 0))
    @

  ###
    Move document focus to the child view at the provided index.

    @method focusOn
    @param Integer idx The index of the child to gain focus
    @chainable
  ###
  focusOn: (idx) ->
    childViews = get(@, 'childViews')
    viewToFocus = childViews.objectAt idx
    viewToFocus = get(childViews, 'lastObject') unless viewToFocus?
    @moveFocus viewToFocus, 0

  ###
    Move focus to the view before the provided child view.

    @method focusBefore
    @param Ember.View view The child view to focus before
    @chainable
  ###
  focusBefore: (view) ->
    @moveFocus view, -1

  ###
    Move focus to the view after the provided child view.

    @method focusAfter
    @param Ember.View view The child view to focus after
    @chainable
  ###
  focusAfter: (view) ->
    @moveFocus view

  ###
    Place focus a number of sibling views after the provided view.

    Use a negative number to move the focus to a sibling with a lower index.

    @method moveFocus
    @param Ember.View view The child view to move focus from
    @param Integer shift How far to move focus
    @chainable
  ###
  moveFocus: (view, shift = 1) ->
    return @ unless view?
    childViews = get(@, 'childViews')
    idx = childViews.indexOf view

    firstView = get(childViews, 'firstObject')
    lastView = get(childViews, 'lastObject')

    viewToFocus = childViews.objectAt(Math.max(0, Math.min(childViews.length - 1, idx + shift)))
    viewToFocus = lastView unless viewToFocus?

    if @isInputView viewToFocus
      if viewToFocus is firstView
        viewToFocus = viewToFocus
      else if viewToFocus is lastView
        viewToFocus = childViews.objectAt(childViews.length - 1) ? viewToFocus
      else
        idx = childViews.indexOf viewToFocus
        viewToFocus = childViews.objectAt(idx + (shift/Math.abs(shift)))

    get(viewToFocus, 'element').focus()
    @

  ###
    Focus on input view and place selection in the expected position.

    @method focus
    @param {Object|Event} e A focus event
    @param Boolean beginning Move selection to the start of the input value
    @chainable
  ###
  focus: (e, beginning = false) ->
    return @ unless (inputView = get(@, 'inputView'))? and get(inputView, 'state') is 'inDOM'
    element = get(inputView, 'element')
    element?.focus()
    selection = if beginning then 0 else get(inputView, 'value.length')
    element.selectionStart = selection
    element.selectionEnd = selection
    @

  ###
    Convenience method for obtaining the view class for text input.

    @method getInputViewClass
    @return Ember.View
  ###
  getInputViewClass: ->
    @_getViewClass 'inputViewClass'

  ###
    Convenience method for obtaining the view class for tag listings.

    @method getItemViewClass
    @return Ember.View
  ###
  getItemViewClass: ->
    @_getViewClass 'itemViewClass'

  ###
    Determine if the tags input view or any of its child views have focus.

    @method isFocused
    @return Boolean
  ###
  isFocused: ->
    focused = @find((childView) ->
      get(childView, 'hasFocus')
    )
    return !!(focused)

  ###
    Inject a new tag into the content array.

    @method insertContent
    @param {String|Object} value A tag to insert
    @param Integer idx The index at which to insert the new tag
    @chainable
  ###
  insertContent: (value, idx) ->
    get(@, 'content').insertAt idx, value
    @

  ###
    Check if the provided view is an instance of the input view class.

    @method isInputView
    @param Mixed view A value to check
    @return Boolean
  ###
  isInputView: (view) ->
    !!(view instanceof @getInputViewClass())

  ###
    Check if the provided view is an instance of the item view class.

    @method isItemView
    @param Mixed view A value to check
    @return Boolean
  ###
  isItemView: (view) ->
    !!(view instanceof @getItemViewClass())

  ###
    Determine if the text field's selection cursor is positioned entirely
    before the input's value.

    @method isSelectionAtStart
    @return Boolean
  ###
  isSelectionAtStart: ->
    return @ unless (inputView = get(@, 'inputView'))? and get(inputView, 'state') is 'inDOM'
    element = get(inputView, 'element')
    !!(element.selectionStart is 0 and element.selectionEnd is 0)

  ###
    Determine if the text field's selection cursor is positioned entirely
    after the input's value.

    @method isSelectionAtEnd
    @return Boolean
  ###
  isSelectionAtEnd: ->
    return @ unless (inputView = get(@, 'inputView'))? and get(inputView, 'state') is 'inDOM'
    element = get(inputView, 'element')
    len = get(inputView, 'value.length')
    !!(element.selectionStart is len and element.selectionEnd is len)

  ###
    Determine if the `content` for this input instance is expected to contain
    an array of strings (not objects).

    @method isStringContent
    @return Boolean
  ###
  isStringContent: ->
    get(@, 'contentPath') is ''

  ###
    Place focus on the input view when it's ready.

    @method refocus
    @param Boolean force Send `true` to ensure focus moves to the input view
    @param Boolean beginning Move selection to the start of the input value
  ###
  refocus: (force, beginning) ->
    inputView = get(@, 'inputView')

    return unless force or @isFocused()

    if get(inputView, 'state') is 'inDOM'
      @focus({}, beginning)
    else
      Ember.run.schedule 'afterRender', @, ->
        @focus({}, beginning) if force or @isFocused()

    return

  ###
    Remove the provided value from the tag input's `content`.

    @method removeTag
    @param {String|Object} value The value to remove
    @chainable
  ###
  removeTag: (value) ->
    return @ unless value?

    content = get(@, 'content')
    idx = content.indexOf value

    return @ if idx < 0 or @willRemoveValue(value) is false

    content.removeObject value
    set(@, 'cursor', idx)
    @_didRemoveValue value
    @

  ###
    Empty the value of the input view.

    @method reset
    @chainable
  ###
  reset: ->
    return @ unless (inputView = get(@, 'inputView'))?
    set inputView, 'value', ''
    @

  ###
    Convert an array into a string joined by the primary delimiter.

    @method stringify
    @param Array arr An array to join into a string
    @return String
  ###
  stringify: (arr = get(@, 'content')) ->
    @_arrayToString arr

  ###
    Swap the provided string with the provided object in the `content` array.

    User entry can only be captured as a string. Therefore, you may need to
    use a given string to lookup or retrive an object. Once the desired object
    is prepared or retrieved, then it can be transplanted into the `content`
    array with `swap()`.

    @method swap
    @param String str A string to swap out
    @param Object obj An object to put in its place
    @chainable
  ###
  swap: (str, obj) ->
    @_swap(str, obj, @isFocused())

  ###
    Called during the input capture process to convert a user-provided string
    value into an array of strings.

    @method tagify
    @param String value A string to process into tags
    @return Array
  ###
  tagify: (value) ->
    @_splitStringByDelimiter(value)

  ###
    Update the `value` property with the stringified `content` array.

    @method updateValue
    @chainable
  ###
  updateValue: ->
    set(@, 'value', @stringify())
    @

  ###
    A pre-insertion check for a newly added string.

    Override this method to add custom tag validation. If a string should not
    be added, return `false`.

    @method willAddValue
    @param {String|Object} value A processed (delimiter split) value to add
    @param Integer idx The index at which to insert the new value
  ###
  willAddValue: Ember.K

  ###
    Override this method to inject custom behavior prior to a tag's removal.

    Return `false` to prevent the tag's removal.

    @method willRemoveValue
    @param {String|Object} value A tag being removed
  ###
  willRemoveValue: Ember.K

  ###
    Override this method to inject custom tag creation/retrieval logic into
    your tag input view. Once the tag is ready, add it to the listing by
    calling `swap(value, tag)` (where `tag` is the created/retrieved value).

    @event didAddValue
    @param {String|Object} value A processed (delimiter split) value to add
    @param Integer idx The index at which to insert the new value
  ###
  didAddValue: Ember.K

  ###
    Override this method to inject custom delete logic for tags that were just
    successfully removed from the content array.

    @event didRemoveValue
    @param {String|Object} value A tag being removed
  ###
  didRemoveValue: Ember.K

  ###
    Adjust cursor value after entry into the DOM.

    @event didInsertElement
  ###
  didInsertElement: ->
    @_super()
    set(@, 'cursor', get(@, 'content.length'))

  ###
    Respond to a click event on the view element. The tags input will try to
    position the input view near the position where the click occurred.

    @event click
    @param Event e The jQuery click event
  ###
  click: (e) ->
    return if get(@, 'disabled') or e.target isnt get(@, 'element')
    posX = e.pageX
    posY = e.pageY
    nearest = @.find((childView) ->
      jQ = childView.$()
      position = jQ.offset()
      height = jQ.outerHeight(true)
      space = jQ.outerWidth(true) - jQ.width()
      !!((position.left > (posX - space) and (position.top + height) > posY) or position.top > posY)
    )
    idx = @indexOf(nearest)
    idx = idx - 1 if idx > get(@, 'cursor')
    set(@, 'cursor', if nearest then idx else get(@, 'content.length'))
    @refocus(true)

  ###
    Respond to the enter/return key while focus is on the input view.

    @event enterPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
  ###
  enterPressed: (e, alt, ctrl, meta, shift) ->
    return if alt or ctrl or meta or shift
    e.preventDefault()
    e.stopPropagation()
    @capture()

  ###
    Respond to the backspace key while focus is on the input view.

    @event backspacePressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
  ###
  backspacePressed: (e, alt, ctrl, meta, shift) ->
    return if alt or ctrl or meta or shift or !@isSelectionAtStart() or !(inputView = get(@, 'inputView'))
    e.preventDefault()
    e.stopPropagation()
    @focusBefore(inputView)

  ###
    Respond to the "forward" delete key while focus is on the input view.

    @event deletePressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
  ###
  deletePressed: (e, alt, ctrl, meta, shift) ->
    return if alt or ctrl or meta or shift or !@isSelectionAtEnd() or !(inputView = get(@, 'inputView'))
    e.preventDefault()
    e.stopPropagation()
    @focusAfter(inputView)

  ###
    Respond to the right arrow key while focus is on the input view.

    @event rightArrowPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
  ###
  rightArrowPressed: (e, alt, ctrl, meta, shift) ->
    return if alt or ctrl or meta or !@isSelectionAtEnd() or !(inputView = get(@, 'inputView'))
    e.preventDefault()
    e.stopPropagation()
    if shift
      @focusAfter(inputView)
    else
      len = get(@, 'content.length')
      @capture()
      @cursorAfter(inputView) if len is get(@, 'content.length')

  ###
    Respond to the left arrow key while focus is on the input view.

    @event leftArrowPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
  ###
  leftArrowPressed: (e, alt, ctrl, meta, shift) ->
    return if alt or ctrl or meta or !@isSelectionAtStart() or !(inputView = get(@, 'inputView'))
    e.preventDefault()
    e.stopPropagation()
    if shift then @focusBefore(inputView) else @cursorBefore(inputView)

  ###
    Respond to the up arrow key while focus is on the input view.

    @event upArrowPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
  ###
  upArrowPressed: (e, alt, ctrl, meta, shift) ->
    return if alt or ctrl or meta or !(inputView = get(@, 'inputView')) or (get(inputView, 'value') isnt '')
    e.preventDefault()
    e.stopPropagation()
    @cursorBefore(get(@, 'childViews.firstObject'))

  ###
    Respond to the down arrow key while focus is on the input view.

    @event downArrowPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
  ###
  downArrowPressed: (e, alt, ctrl, meta, shift) ->
    return if alt or ctrl or meta or !(inputView = get(@, 'inputView')) or (get(inputView, 'value') isnt '')
    e.preventDefault()
    e.stopPropagation()
    @cursorAfter(get(@, 'childViews.lastObject'))

  ###
    Watches for changes in the input's value and automatically captures tags
    if a delimiter match is found within the value.

    @method didInputValueChange
    @chainable
  ###
  didInputValueChange: Ember.observer ->
    inputView = get(@, 'inputView')
    value = get(inputView, 'value')

    delimiter = get @, '_delimiter_pattern'
    regexString = delimiter.toString().split('/').slice(1, -1).join('/')
    regexString = ['.+(', regexString, ')$'].join('')
    pattern = new RegExp(regexString, 'g')

    @capture() if delimiter.test(value) and (pattern.test(value) or inputView._didPaste)
    inputView._didPaste = false
    @
  , 'inputView.value'

  ###
    @private

    Updates child view rendering when the cursor position changes.

    @method _cursorDidChange
  ###
  _cursorDidChange: Ember.observer ->
    if get(@, 'childViews.length') then @_updateCursorLocation() else @_updateChildViews()
  , 'cursor'

  ###
    @private

    Update `content` and `value` to account for a change to the `delimiter`.

    @method _delimiterDidChange
  ###
  _delimiterDidChange: Ember.observer ->
    # Update the content and value when the delimiter changes
    # only if using strings as tags
    return unless @isStringContent()
    content = @_arrayToString(get(@, 'content'))
    @_clearContent()
    @capture content
    @updateValue()
  , 'delimiter'

  _willAddValue: (value, idx) ->
    @willAddValue(value, idx)

  _didAddValue: (value, idx) ->
    @trigger 'didAddValue', value, idx
    @

  _didRemoveValue: (value) ->
    @trigger 'didRemoveValue', value
    @

  ###
    @private

    Swaps the provided string with the provided object. If silent, then
    `content` is quietly swapped using `splice()` to update the array without
    causing the child views to be re-rendered (potentially causing focus to
    change), and the content of just a single tag listing is updated.

    If the tag is no longer in the `content` array, then nothing will happen.

    @method _swap
    @chainable
  ###
  _swap: (str, obj, silent) ->
    content = get(@, 'content')
    idx = content.indexOf str
    cursor = get @, 'cursor'
    if idx >= 0
      if silent
        content.splice(idx, 1, obj)
        itemView = get(@, 'childViews').objectAt(if cursor <= idx then idx + 1 else idx)
        set(itemView, 'content', obj) if itemView? and get(itemView, 'content') is str
      else
        content.replace(idx, 1, [obj])
    @

  ###
    @private

    Attempts to retrieve a view class from a given property name.

    @method _getViewClass
    @return Ember.View
  ###
  _getViewClass: (property) ->
    viewClass = get(@, property)
    viewClass = get(viewClass) if typeOf(viewClass) is 'string'
    viewClass

  ###
    @private

    Combines items in the `content` array to form a string value.

    @method _arrayToString
    @return String
  ###
  _arrayToString: (arr = Ember.A()) ->
    unless (Ember.Enumerable.detect(arr) || Ember.isArray(arr))
      throw new TypeError("Must pass Ember.Enumerable to Emberella.TagsInput#_arrayToString")

    delimiter = get @, '_primary_delimiter'
    contentPath = get @, 'contentPath'

    if Ember.isArray arr
      result = arr.map((item) ->
        if item? and (ret = get(item, contentPath)) then ret else item
      ).compact().join(delimiter)

  ###
    @private

    Updates focus state as focus moves within the tags input view.

    @method _focusDidChange
  ###
  _focusDidChange: Ember.observer ->
    set @, 'hasFocus', @isFocused()
  , '@each.hasFocus'

  ###
    @private

    Perform actions when focus entirely exits the tags input view.

    @method _hasFocusDidChange
  ###
  _hasFocusDidChange: Ember.observer ->
    if !get(@, 'hasFocus')
      # The field may appear to lose focus frequently as the focus shifts
      # between child views. The run later helps to verify the focus has, in
      # fact, completely left the field.
      Ember.run.later @, ->
        return unless get(@, 'state') is 'inDOM' and !@isFocused()
        @capture() if get(@, 'tagOnFocusOut')
        set(@, 'cursor', get(@, 'childViews.length')) if get(@, 'inputView.value') is ''
      , 100
  , 'hasFocus'

  ###
    @private

    Render/update the tags listing and input views.

    @method _renderList
  ###
  _renderList: ->
    @_updateChildViews()

  ###
    @private

    Redraw all of the child views.

    @method _rerenderList
  ###
  _rerenderList: ->
    @destroyAllChildren()
    @_renderList()

  ###
    @private

    Places an input view at the current `cursor` position.

    @method _insertInputView
  ###
  _insertInputView: ->
    inputView = get(@, 'inputView')
    inputView = if inputView and !get(inputView, 'isDestroyed') and !get(inputView, 'isDestroying') then inputView else @_createInputView()
    cursor = get @, 'cursor'
    @insertAt(cursor, inputView)
    return

  ###
    @private

    Removes the input view from the DOM.

    @method _removeInputView
  ###
  _removeInputView: ->
    inputView = get(@, 'inputView')
    inputView = if inputView and !get(inputView, 'isDestroyed') and !get(inputView, 'isDestroying') then inputView else @_createInputView()

    # Weird jQuery DOM manipulation error in Webkit.
    try
      inputView.removeFromParent()
    catch e

    # inputView.removeFromParent()

    return

  ###
    @private

    Creates a new input view instance.

    @method _createInputView
  ###
  _createInputView: ->
    inputView = @createChildView(@getInputViewClass())
    set @, 'inputView', inputView
    inputView

  ###
    @private

    Creates and updates tag listing views with the current `content` array.

    @method _updateChildViews
  ###
  _updateChildViews: ->
    return if (get(@, 'state') isnt 'inDOM') or get(@, 'isDestroyed') or get(@, 'isDestroying')
    @_removeInputView()

    childViews = @
    childViewsLength = Math.max(0, get(@, 'length'))

    itemViewClass = @getItemViewClass()

    content = get(@, 'content')
    contentLength = get(@, 'content.length')

    for i in [0...Math.max(childViewsLength, contentLength)]
      childView = @objectAt(i)

      if i < contentLength
        unless childView instanceof itemViewClass
          childView = @createChildView(itemViewClass)
          @insertAt(i, childView)

        setProperties childView, {'content': content[i], 'index': i}
      else
        childView?.removeFromParent() if @isItemView childView

    @_insertInputView()
    return

  ###
    @private

    Moves the input view without redrawing all childViews.

    @method _updateCursorLocation
  ###
  _updateCursorLocation: ->
    @_removeInputView()
    @_insertInputView()

  ###
    @private

    Escape special regular expression characters in a given string.

    @method _escapeRegExpString
    @return String
  ###
  _escapeRegExpString: (str) ->
    str.replace(ESCAPE_REG_EXP, ESCAPE_REPLACEMENT)

  ###
    @private

    Split a string using the regular expression in the `_delimiter_pattern`
    property. Add the results to a provided result array.

    @method _splitStringByDelimiter
    @param String str A string to process
    @param Array result An array to add the results to
    @return Array The provided result array
  ###
  _splitStringByDelimiter: (str = '', result = Ember.A()) ->
    pattern = get(@, '_delimiter_pattern')
    values = str.split(pattern)
    result.clear()

    for v in values
      v = jQuery.trim v
      continue if !v? or v is ''
      result.addObject v

    result

  ###
    @private

    Prepares (trims) a string to be a tag.

    @method _prepareStringTag
    @param String value The string to capture
    @return {String|Boolean} Processed value or false
  ###
  _prepareStringTag: (value = '') ->
    value = jQuery.trim(value)
    return false if value is '' or @contains(value)

    # If the value can be split further, do so and early return
    if get(@, '_delimiter_pattern').test(value)
      @capture(value)
      return false

    value

  ###
    @private

    Validates an object for tag-worthiness.

    @method _prepareObjectTag
    @param Object value The object to capture
    @return {Object|Boolean} Validated object or false
  ###
  _prepareObjectTag: (value) ->
    unless value and @_isValidTagValue(value)
      Ember.warn "Attempted to add an object without a value at " + get(@, 'contentPath')
      return false

    if @contains(value) then false else value

  ###
    @private

    Routes an array of tags back to addTags for proper processing.

    @method _prepareArrayTag
    @param Array value The array to capture
    @return Boolean
  ###
  _prepareArrayTag: (value) ->
    @addTags value
    false

  ###
    @private

    Checks a tag to see if it contains a defined value at the `contentPath`.

    @method _isValidTagValue
    @param Mixed value The value to check
    @return Boolean
  ###
  _isValidTagValue: (value) ->
    return false unless value
    contentPath = get @, 'contentPath'

    !!(get(value, contentPath))


  ################################
  ### CONTENT ARRAY MANAGEMENT ###
  ################################


  ###
    Hook for responding to the content array being replaced with a new
    array instance. Override to add custom handling.

    @method contentWillChange
    @param {Object} self
  ###
  contentWillChange: Ember.K

  ###
    Hook for responding to the content array being replaced with a new
    array instance. Override to add custom handling.

    @method contentDidChange
    @param {Object} self
  ###
  contentDidChange: ->
    @_rerenderList() if get(@, 'state') is 'inDOM'

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

    @method contentArrayDidChange
    @param {Array} array The array instance being updated
    @param {Integer} idx The index where changes applied
    @param {Integer} removedCount
    @param {Integer} addedCount
  ###
  contentArrayDidChange: (array, idx, removedCount, addedCount) ->
    @_updateChildViews()
    @incrementProperty('cursor', ((addedCount || 0) - (removedCount || 0)))
    @updateValue() if @isStringContent()
    @

  ###
    @private

    Content array change handler.

    @method _contentWillChange
  ###
  _contentWillChange: Ember.beforeObserver ->
    content = get(@, 'content')
    len = if content then get(content, 'length') else 0

    @contentArrayWillChange @, 0, len, undefined
    @contentWillChange @
    @_teardownContent content
  , 'content'

  ###
    @private

    Content array change handler.

    @method _contentDidChange
  ###
  _contentDidChange: Ember.observer ->
    content = get(@, 'content')
    len = if content then get(content, 'length') else 0

    @_setupContent content
    @contentDidChange @
    @contentArrayDidChange @, 0, undefined, len
  , 'content'

  ###
    @private

    Remove change observing on content array.

    @method _teardownContent
  ###
  _teardownContent: ->
    @_clearContent()
    content = get(@, 'content')
    if content
      content.removeArrayObserver @,
        willChange: 'contentArrayWillChange',
        didChange: 'contentArrayDidChange'

  ###
    @private

    Begin change observing on content array.

    @method _setupContent
  ###
  _setupContent: ->
    content = get(@, 'content')
    if content
      content.addArrayObserver @,
        willChange: 'contentArrayWillChange',
        didChange: 'contentArrayDidChange'

  ###
    @private

    Empty the content array.

    @method _clearContent
  ###
  _clearContent: ->
    content = get(@, 'content')
    content.clear() if content


###############################################################################
###############################################################################


###
  `Emberella.TagItemView` is designed to be a drop-in tag item listing view for
  an `Emberella.TagsInput` container view. Each instance of
  `Emberella.TagItemView` inherits its template and the majority of its
  properties from its parent view. Each tag item also responds to a variety of
  keyboard events to provide familiar interactions to users.

  @class TagItemView
  @namespace Emberella
  @extends Ember.View
  @uses Ember.StyleBindingsMixin
  @uses Emberella.FocusableMixin
  @uses Emberella.KeyboardControlMixin
###

Emberella.TagItemView = Ember.View.extend Ember.StyleBindingsMixin, Emberella.FocusableMixin, Emberella.KeyboardControlMixin, Emberella.MembershipMixin,
  inherit: ['template', 'contentPath', 'deleteCharacter', 'deleteTitle', 'stylist', 'disabled']

  actions: {
    removeSelf: -> @removeSelf.apply @, arguments
  }

  ###
    The type of element to render this view into. By default, tag items will
    appear in `<span/>` elements.

    @property tagName
    @type String
    @default 'span'
  ###
  tagName: 'span'

  ###
    Add the 'emberella-tag-item' class to each tag item. Use this class to
    style your tags.

    @property classNames
    @type Array
    @default ['emberella-tag-item']
  ###
  classNames: ['emberella-tag-item']

  ###
    Add the computed `stylistClasses` property as additional classes for
    this tag listing.

    @property classNameBindings
    @type Array
    @default ['stylistClasses']
  ###
  classNameBindings: ['stylistClasses']

  ###
    Toggle the `display` style based on the property of the same name.

    @property styleBindings
    @type Array
    @default ['display']
  ###
  styleBindings: ['display']

  ###
    Prevent focus with TAB key.

    @property tabindex
    @type Integer
    @default -1
  ###
  tabindex: -1

  ###
    The content to display in the listing.

    @property content
    @type Mixed
    @default null
  ###
  content: null

  ###
    The position of this listing in the parent view's content.

    @property index
    @type Integer
    @default null
  ###
  index: null

  ###
    Computes the string to display in the DOM based on the listing's content
    and contentPath.

    @property displayContent
    @type String
    @readOnly
  ###
  displayContent: Ember.computed ->
    return '' unless (content = get @, 'content')?
    contentPath = get @, 'contentPath'
    get(content, contentPath) ? content
  .property('content', 'contentPath').readOnly()

  ###
    Iterates over the stylist object (if one is set) and assembles a
    space-delimited string of classes to add to this listing view.

    @property stylistClasses
    @type String
  ###
  stylistClasses: Ember.computed ->
    return '' unless (content = get(@, 'content')) and (stylist = get(@, 'stylist')) and typeOf(stylist) is 'object'
    ret = Ember.A()
    for own key, fn of stylist
      continue unless typeOf(fn) is 'function'
      ret.pushObject(key) if fn.call(@, content)

    ret.join(' ')
  .property 'stylist', 'content'

  ###
    Set display style to 'none' when content is empty.

    @property display
    @type String
  ###
  display: Ember.computed ->
    if Ember.isEmpty(get(@, 'content')) then 'none' else undefined
  .property 'content'

  ###
    Remove this listing's content from the parent view's content array.

    Subsequently, this listing will be removed from the DOM or recycled with
    new content.

    @method removeSelf
    @chainable
  ###
  removeSelf: ->
    @dispatch('removeTag', get(@, 'content'))

  ###
    Respond to the backspace key.

    @event backspacePressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
    @chainable
  ###
  backspacePressed: (e, alt, ctrl, meta, shift) ->
    return if alt or ctrl or meta or shift
    @dispatch 'cursorAfter'
    @removeSelf()

  ###
    Respond to the ("forward") delete key.

    @event deletePressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
    @chainable
  ###
  deletePressed: Ember.aliasMethod 'backspacePressed'

  ###
    Respond to the right arrow key.

    @event rightArrowPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
    @chainable
  ###
  rightArrowPressed: (e, alt, ctrl, meta, shift) ->
    return if alt or ctrl or meta
    @dispatch(if shift then 'focusAfter' else 'cursorAfter')

  ###
    Respond to the left arrow key.

    @event leftArrowPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
    @chainable
  ###
  leftArrowPressed: (e, alt, ctrl, meta, shift) ->
    return if alt or ctrl or meta
    if shift then @dispatch('focusBefore') else @dispatch('moveCursor', @, 0)

  ###
    Respond to the up arrow key.

    @event upArrowPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
    @chainable
  ###
  upArrowPressed: (e, alt, ctrl, meta, shift) ->
    @dispatch('upArrowPressed', e, alt, ctrl, meta, shift)

  ###
    Respond to the down arrow key.

    @event downArrowPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
    @chainable
  ###
  downArrowPressed: (e, alt, ctrl, meta, shift) ->
    @dispatch('downArrowPressed', e, alt, ctrl, meta, shift)

  ###
    Respond to the enter/return key.

    @event enterPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
    @chainable
  ###
  enterPressed: Ember.aliasMethod 'rightArrowPressed'

  ###
    Respond to the TAB key.

    @event tabPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
    @chainable
  ###
  tabPressed: Ember.aliasMethod 'rightArrowPressed'

  ###
    Stop propagation of key down events.

    @event keyDown
  ###
  keyDown: (e) ->
    e.stopPropagation()
    @_super.apply @, arguments

  ###
    Handle key press events.

    @event keyPress
  ###
  keyPress: (e) ->
    @_super(e)
    return if e.isDefaultPrevented()
    @backspacePressed(e, false, e.ctrlKey, e.metaKey, false)


###############################################################################
###############################################################################


###
  `Emberella.TagItemInput` is a flexible text field that moves to the cursor
  position of its parent view. An extension of `Emberella.FlexibleTextField`,
  this input is designed to squeeze between tag listings and allow the user to
  enter text (and create tags) at any position in the tag array.

  @class TagItemInput
  @namespace Emberella
  @extends Emberella.FlexibleTextField
  @uses Emberella.FocusableMixin
  @uses Emberella.KeyboardControlMixin
###
Emberella.TagItemInput = Emberella.FlexibleTextField.extend Emberella.FocusableMixin, Emberella.KeyboardControlMixin, Emberella.MembershipMixin,
  inherit: ['disabled']

  isTagItemInput: true

  ###
    Displays placeholder text until this input or the parent view have a value
    to display.

    @property placeholder
    @type String
  ###
  placeholder: Ember.computed ->
    if get(@, 'disabled') or get(@, 'parentView.content.length') then '' else get(@, 'parentView.placeholder')
  .property 'parentView.placeholder', 'parentView.content.length'

  ###
    Handle paste events.

    @method paste
  ###
  paste: (e) -> @_didPaste = true
