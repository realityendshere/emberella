#= require ../helpers/function_helpers
#= require ../mixins/keyboard_control_mixin
#= require ../mixins/membership_mixin

###
@module emberella
@submodule emberella-views
###

Emberella = window.Emberella
jQuery = window.jQuery
get = Ember.get
set = Ember.set
typeOf = Ember.typeOf

ESCAPE_REG_EXP = /[\-\[\]{}()*+?.,\\\^$|#\s]/g
ESCAPE_REPLACEMENT = '\\$&'

SEARCH_SUBSTITUTION = /%s/
QUERY_SUBSTITUTION = /%q/

###
  The `Emberella.AutocompleteView` combines a text field and a collection view
  to offer a list of suggested completions based on user input.

  TODO: Allow more flexible positioning of the suggestions list when near the
        bottom edge of the window?
  TODO: Code cleanup and refactor to allow autocomplete to integrate with
        other views

  @class AutocompleteView
  @namespace Emberella
  @extends Ember.ContainerView
  @uses Ember.ViewTargetActionSupport
  @uses Emberella.KeyboardControlMixin
  @uses Emberella.FocusableMixin
###

Emberella.AutocompleteView = Ember.ContainerView.extend Ember.ViewTargetActionSupport, Emberella.KeyboardControlMixin, Emberella.FocusableMixin,
  # private bookkeeping properties
  _isListVisible: false

  init: ->
    set(@, 'search', '')
    @_super()

  ###
    Declares this view is an autocomplete view.

    @property isAutocomplete
    @type Boolean
    @default true
    @final
  ###
  isAutocomplete: true

  ###
    @property childViews
  ###
  childViews: ['inputView', 'listView']

  ###
    @property defaultTemplate
    @final
  ###
  defaultTemplate: Ember.Handlebars.compile [
    '<span class="emberella-autocomplete-item-content">{{{view.displayContent}}}</span>'
  ].join(' ')

  ###
    @property defaultHighlighter
    @final
  ###
  defaultHighlighter: (str, p1, offset, s) ->
    ['<strong>', p1, '</strong>'].join('')

  ###
    @property defaultUpdater
    @final
  ###
  defaultUpdater: (value = get(@, 'selected')) ->
    contentPath = get(@, 'contentPath')
    set(@, 'displayValue', get(value, contentPath))

  ###
    @property defaultMatcher
    @final
  ###
  defaultMatcher: (item) ->
    searchPaths = get(@, 'searchPaths')
    match = false

    for path in searchPaths
      if get(@, 'searchExpression').test(get(item, path))
        match = true
        break;

    match

  ###
    @property defaultSorter
    @final
  ###
  defaultSorter: (suggestions, search = get(@, 'search')) ->
    searchPaths = get(@, 'searchPaths')
    return Ember.A() unless search
    search = search.toLowerCase()
    words = search.split(/\s+/)
    searches = get @, 'searches'
    suggestions = suggestions.slice().reverse()
    results = []

    for s, si in searches
      s = @stringToSearchExpression(s, search)
      results[si] = results[si] || new Array(words.length)

      for term, ti in suggestions by -1

        for path in searchPaths
          s.lastIndex = 0 if s.global
          if m = s.exec(get(term, path))
            match = suggestions.splice(ti, 1)[0]
            if m.length > 1 and (pos = words.indexOf(m[1].toLowerCase())) >= 0
              results[si][pos] = results[si][pos] || []
              results[si][pos].push(match)
            else
              results[si].push(match)
            break

    Ember.A([].concat.apply([], [].concat.apply([], [].concat(results))).concat(suggestions)).compact()

  ###
    The current focus state of this view instance.

    @property hasFocus
  ###
  hasFocusBinding: 'inputView.hasFocus'

  ###
    Prevent focus with TAB key.

    @property tabindex
    @type Integer
    @default -1
  ###
  tabindex: -1

  ###
    Add the 'emberella-autocomplete' class to the container element. Use this
    class to style your autocomplete input.

    @property classNames
    @type Array
    @default ['emberella-autocomplete']
  ###
  classNames: ['emberella-autocomplete']

  ###
    If true, the first suggestion in the list will be automatically selected
    for the user.

    @property autoSelect
    @type Boolean
    @default true
  ###
  autoSelect: true

  ###
    The maximum number of suggestions to show.

    @property items
    @type Number
    @default 10
  ###
  items: 10

  ###
    The number of ms to wait after the user finishes typing before beginning
    the suggestions retrieval process. If your suggestions are fetched
    asynchronously from a server, a bigger number will help to reduce the
    frequency of remote queries.

    @property delay
    @type Number
    @default 10
  ###
  delay: 10

  ###
    The minimum length a search string must reach before suggestions should be
    retrieved, assembled, or displayed.

    @property minLength
    @type Number
    @default 1
  ###
  minLength: 1

  ###
    The selected/highlighted suggestion.

    @property selected
    @type Mixed
    @default null
  ###
  selected: null

  ###
    The current value of the input field.

    @property value
    @type String
    @default ''
  ###
  value: ''

  ###
    The dot-delimited "Ember.get" path for finding a string value to display
    and use as the input value.

    For example, a list of US States might appear as an array of objects like
    `{"name":"California", "alpha-2":"CA"}`. To adopt the full state name as
    the value for this input, set the `contentPath` to `"name"`.

    @property contentPath
    @type String
    @default ''
  ###
  contentPath: ''

  ###
    Either a space-delimited string or an array containing one or many
    dot-delimited "Ember.get" paths to examine for matches when searching.

    The `contentPath` will always be searched.

    For example, a list of US States might appear as an array of objects like
    `{"name":"California", "alpha-2":"CA", "nickname": "The Golden State"}`.
    To find suggestions by searching both the `name` and `alpha-2` attributes,
    set the `searchPath` property to `"alpha-2"`. To search across all three
    attributes, set the `searchPath` property to `"alpha-2 nickname"` or
    `["alpha-2", "nickname"]`.

    @property searchPath
    @type String
    @default ''
  ###
  searchPath: ''

  ###
    The sort order for search results.

    `Emberella.AutocompleteView` begins the search process by assembling an
    array of all possible matches. It then prioritizes suggestions in the
    following order:

    1) exact matches
    2) result starts with the search string
    3) result starts with any "word" in the search (`"CA"` is different than
       `"C A"`, the latter includes results that start with "A")
    4) other matches

    Lastly, it takes the first x number of array items (where x is
    `this.get('items')`) and displays them as suggestions.

    If you wish to override the default behavior, you may supply your own array
    of sort expression strings.

    `%s` will be substituted with the escaped search as is
    `%q` will be substituted with the "word" finding query

    @property searches
    @type Array
    @default [
      '^%s$' #exact match
      '^%s'  #starts with search
      '^%q'  #starts with word
      '%s'   #string found
    ]
  ###
  searches: [
    '^%s$' #exact match
    '^%s'  #starts with search
    '^%q'  #starts with word
    '%s'   #string found
  ]

  ###
    The current search string.

    As the input value changes, the `search` property will be updated the
    number of ms specified in the `delay` property after the last change to the
    input value.

    @property search
    @type String
    @default null
  ###
  search: null

  ###
    Either an Array of available values to search through or a string to help a
    controller determine how to fetch suggestions.

    @property source
    @type {Array|String}
    @default Ember.A()
  ###
  source: Ember.A()

  ###
    Binds the `displayValue` property to the input view's value. As
    `displayValue` changes, the `search` property may eventually be updated to
    initiate the gathering of suggested values.

    @property displayValueBinding
    @type String
    @default 'inputView.value'
  ###
  displayValueBinding: 'inputView.value'

  ###
    A listing with the current display value will appear as an option if this
    is `true`.

    If set to a value less than 0, the display value will be appended to the
    end of the suggestions listing. Otherwise, the display value will appear as
    the first suggestion in the list.

    TODO: adjust this behavior to do something more useful like display
    a message/error.

    @property suggestCurrentValue
    @type Boolean
    @default false
  ###
  suggestCurrentValue: false

  ###
    When `true`, the selected autocomplete suggestion is set as the value when
    the input loses focus.

    @property autocompleteOnFocusOut
    @type Boolean
    @default false
  ###
  autocompleteOnFocusOut: false

  ###
    The view class to use as the input field.

    @property inputViewClass
    @type Ember.View
    @default 'Emberella.AutocompleteInputView'
  ###
  inputViewClass: 'Emberella.AutocompleteInputView'

  ###
    The view class to use as the suggestion collection view.

    @property listViewClass
    @type Ember.View
    @default 'Emberella.AutocompleteListView'
  ###
  listViewClass: 'Emberella.AutocompleteListView'

  ###
    The view class to use for individual suggestion listing views.

    @property itemViewClass
    @type Ember.View
    @default 'Emberella.AutocompleteItemView'
  ###
  itemViewClass: 'Emberella.AutocompleteItemView'

  ###
    A custom string.replace function to highlight matching strings in
    a suggestion.

    See the "Specifying a function as a parameter" section at
    https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace
    for additional guidance.

    @property highlighter
    @type Function
    @default defaultHighlighter
  ###
  highlighter: Ember.computed.defaultTo 'defaultHighlighter'

  ###
    A custom function for injecting a selected value into the input value.

    @property updater
    @type Function
    @default defaultUpdater
  ###
  updater: Ember.computed.defaultTo 'defaultUpdater'

  ###
    A custom function for determining if a string or object should be included
    as a potential suggestion.

    The function is called in the context of this view instance and receives
    one argument: the item to test.

    @property matcher
    @type Function
    @default defaultMatcher
  ###
  matcher: Ember.computed.defaultTo 'defaultMatcher'

  ###
    A custom function for sorting potential suggestions into the order to
    display to the user.

    The function is called in the context of this view instance and receives
    one argument: the Array of potential suggestions.

    @property matcher
    @type Function
    @default defaultMatcher
  ###
  sorter: Ember.computed.defaultTo 'defaultSorter'

  ###
    An array of potential suggestions that match the current search criteria.

    This list is sorted and cut down to size in the `selection` property.

    @property allSuggestions
    @type Array
    @default []
  ###
  allSuggestions: Ember.A()

  ###
    The suggested values to display in a list to the user.

    @property suggestions
    @type Array
    @default []
    @readOnly
  ###
  suggestions: Ember.computed ->
    items = get @, 'items'
    displayValue = get(@, 'displayValue') || ''
    allSuggestions = get(@, 'allSuggestions').slice()
    _suggestions = allSuggestions.slice(0, items)

    return _suggestions unless (suggestCurrentValue = get(@,'suggestCurrentValue'))

    contentPath = get @, 'contentPath'
    inputObject = displayValue

    if contentPath isnt ''
      inputObject = {}
      parts = contentPath.split('.')
      while parts.length > 0
        part = parts.shift()
        inputObject[part] = if parts.length > 0 then {} else displayValue

    method = if +suggestCurrentValue < 0 then "pushObject" else "unshiftObject"

    _suggestions[method](inputObject)

    _suggestions
  .property('allSuggestions', 'items', 'sorter').readOnly()

  ###
    A regular expression to use for finding items to suggest.

    @property searchExpression
    @type RegExp
    @readOnly
  ###

  # Volatile to prevent global regex cursor madness
  # See: http://stackoverflow.com/questions/1520800/why-regexp-with-global-flag-in-javascript-give-wrong-results
  searchExpression: Ember.computed ->
    new RegExp(get(@, '_searchExpression'), 'gi')
  .volatile().readOnly()

  ###
    An array of paths to use with `Ember.get`. Always includes the
    `contentPath` property.

    @property searchPaths
    @type Array
    @default [this.get('contentPath')]
    @readOnly
  ###
  searchPaths: Ember.computed ->
    searchPath = get(@, 'searchPath')
    searchPath = searchPath.split(/\s+/) if searchPath.split?
    ret = Ember.A([get(@, 'contentPath')])
    ret.addObjects(searchPath) if Ember.isArray(searchPath)
    ret
  .property('contentPath', 'searchPath').readOnly()

  ###
    Specifies if the list of suggestions should be visible or not.

    @property isListVisible
    @type Boolean
    @default false
  ###
  isListVisible: Ember.computed (key, value) ->
    key = '_' + key
    len = get @, 'suggestions.length'

    #getter
    if arguments.length is 1
      return !!(get(@, 'hasFocus') and get(@, key) and len > 0)

    #setter
    else
      set(@, key, value)
      return @
  .property('hasFocus', '_isListVisible', 'suggestions.length', 'displayValue')

  ###
    The debounced method for responding to changes in the input value.

    @property debouncedValueDidChange
    @type Function
  ###
  debouncedValueDidChange: Ember.computed ->
    Emberella.debounce((=>
      @_displayValueChangeHandler()
    ), get(@, 'delay'))
  .property 'delay'

  ###
    The input view instance.

    @property inputView
    @type Ember.View
  ###
  inputView: Ember.computed ->
    @getInputViewClass()
  .property 'inputViewClass'

  ###
    The list view instance.

    @property inputView
    @type Ember.View
  ###
  listView: Ember.computed ->
    @getListViewClass()
  .property 'listViewClass'

  ###
    Escape a string for use as a regular expression.

    @method escapeSearch
    @param String str The string to excape
    @return String The escaped string
  ###
  escapeSearch: (str) ->
    jQuery.trim(str ? '').replace(ESCAPE_REG_EXP, ESCAPE_REPLACEMENT)

  ###
    Convert a plain string into a word search regular expression (for finding
    matches for any word in the given string).

    @method expressionFor
    @param String str The string to convert
    @return String The expression string
  ###
  expressionFor: (str) ->
    search = @escapeSearch(str)
    words = '(' + search.replace(/(\\\s)+/gi, '|').split('|').join(')|(') + ')'
    searchExpression = [search]
    searchExpression = [].concat(searchExpression, '|', words) if words.indexOf('|') >= 0
    searchExpression.unshift('(')
    searchExpression.push(')')
    searchExpression.join('')

  ###
    When called without arguments, the `complete()` method applies the
    `selected` property as the new value for the input and maintains the view's
    current focus state.

    You may also provide a specific item to insert as the input value or choose
    to alter the focus state.

    @method complete
    @param Mixed value The value to commit to
    @param Boolean retainFocus
    @chainable
  ###
  complete: (value = get(@, 'selected'), retainFocus = @isFocused()) ->
    return @ unless value
    get(@, 'updater').call @, value
    @focus() if retainFocus
    @hide()
    @

  ###
    Move focus into the input element of this view instance.

    @method focus
    @chainable
  ###
  focus: ->
    return @ unless (inputView = get(@, 'inputView'))? and get(inputView, 'state') is 'inDOM'

    if typeOf(inputView.focus) is 'function'
      inputView.focus()
    else
      element = get(inputView, 'element')
      element?.focus()
    @

  ###
    Convenience method for obtaining the view class for text input.

    @method getInputViewClass
    @return Ember.View
  ###
  getInputViewClass: ->
    @_getViewClass 'inputViewClass'

  ###
    Convenience method for obtaining the view class for suggestion listings.

    @method getItemViewClass
    @return Ember.View
  ###
  getItemViewClass: ->
    @_getViewClass 'itemViewClass'

  ###
    Convenience method for obtaining the view class for suggestion list.

    @method getListViewClass
    @return Ember.View
  ###
  getListViewClass: ->
    @_getViewClass 'listViewClass'

  ###
    The index of the currently selected suggestion in the array of suggestions.

    @method indexOfSelection
    @return Integer
  ###
  indexOfSelection: ->
    suggestions = get(@, 'suggestions')
    return -1 if !suggestions or suggestions.length is 0
    suggestions.indexOf get(@, 'selected')

  ###
    Determine if the autocomplete view or any of its child views have focus.

    @method isFocused
    @return Boolean
  ###
  isFocused: ->
    focused = @find((childView) ->
      get(childView, 'hasFocus')
    )
    return !!(focused)

  ###
    Checks to see if the selected item is currently listed as a suggestion.

    @method isSelectedInContent
    @return Boolean
  ###
  isSelectedInContent: ->
    @indexOfSelection() >= 0

  ###
    Select the next suggestion (e.g. current selection index + 1) in the list.
    If no next selection is available, select the first suggestion.

    @method next
    @chainable
  ###
  next: ->
    @move(1, get(@, 'suggestions.firstObject'))
    @

  ###
    Select the previous suggestion (e.g. current selection index - 1) in the
    list. If no previous selection is available, select the last suggestion.

    @method previous
    @chainable
  ###
  previous: ->
    @move(-1, get(@, 'suggestions.lastObject'))
    @

  ###
    Adjust the selection index by the provided `delta`. If no object exists at
    the adjusted index, select the provided alternative instead.

    @method move
    @param Integer delta The adjustment to the selection index
    @param Mixed defaultSelection
    @chainable
  ###
  move: (delta, defaultSelection) ->
    suggestions = get @, 'suggestions'
    idx = @indexOfSelection()
    newIdx = Math.min(Math.max(-1, (idx + delta)), suggestions.length)

    selected = (if newIdx < 0 then get(suggestions, 'lastObject') else suggestions.objectAt(newIdx)) ? defaultSelection

    set @, 'selected', selected
    @

  ###
    Set the `selected` property to the `content` of the provided view.

    Optionally, use the provided view content to complete the input value.

    @method selectMember
    @param Ember.View The view with content to mark `selected`
    @param Boolean complete If true, apply selected content to the input value
    @chainable
  ###
  selectMember: (view, complete) ->
    content = get(view, 'content')
    set(@, 'selected', content)
    @complete(content) if complete
    @

  ###
    Show the suggestion listing view.

    @method show
    @chainable
  ###
  show: ->
    set @, '_isListVisible', true
    @

  ###
    Hide the suggestion listing view.

    @method hide
    @chainable
  ###
  hide: ->
    set @, '_isListVisible', false
    @

  sort: (arr, search) ->
    sorter = get @, 'sorter'
    sorter.call(@, arr, search)

  ###
    Substitutes `%s` and `%q` with corresponding search strings and returns
    a regular expression.

    @method stringToSearchExpression
    @param String str An autocomplete expression string
    @param String search A regular expression safe search string
    @return RegExp
  ###
  stringToSearchExpression: (str, search) ->
    str = str.replace SEARCH_SUBSTITUTION, @escapeSearch(search)
    str = str.replace QUERY_SUBSTITUTION, @expressionFor(search)

    new RegExp(str, 'gi')

  ###
    Shows and hides the list of completion options as the `suggestions` array
    property changes.

    @method suggestionsDidChange
  ###
  suggestionsDidChange: Ember.observer ->
    set(@, 'selected', if get(@, 'autoSelect') then (get(@, 'suggestions.firstObject') ? null) else null)
  , 'suggestions', 'suggestions.length'

  # didRetrieveSuggestions: (search, results) ->

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
    len = get @, 'suggestions.length'
    return if len is 0 or alt or ctrl or meta or shift
    e.preventDefault()
    @show().previous()

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
    len = get @, 'suggestions.length'
    return if len is 0 or alt or ctrl or meta or shift
    e.preventDefault()
    @show().next()

  ###
    Respond to the return/enter key while focus is on the input view.

    @event enterPressed
    @param Event e The jQuery keyDown event
    @param Boolean alt Alt/option key is pressed
    @param Boolean ctrl Control key is pressed
    @param Boolean meta Meta/Command key is pressed
    @param Boolean shift Shift key is pressed
  ###
  enterPressed: (e, alt, ctrl, meta, shift) ->
    @complete() if get(@, 'isListVisible')

  ###
    @private

    A regular expression string to use for finding items to suggest.

    @property _searchExpression
    @type String
    @readOnly
  ###
  _searchExpression: Ember.computed ->
    @expressionFor get(@, 'search')
  .property('search').readOnly()

  ###
    @private

    Updates the `search` property appropriately as the input value changes.

    @method _displayValueDidChange
  ###
  _displayValueDidChange: Ember.observer ->
    set(@, 'allSuggestions', Ember.A())
    method = if get(@, 'displayValue.length') < get(@, 'minLength') then 'hide' else 'show'
    @[method]()
    get(@, 'debouncedValueDidChange')()
  , 'displayValue', 'minLength'

  ###
    @private

    Perform actions when focus entirely exits the tags input view.

    @method _hasFocusDidChange
  ###
  _hasFocusDidChange: Ember.observer ->
    if !get(@, 'hasFocus')
      displayValue = get(@, 'displayValue') ? ''
      selected = get(@, 'selected')
      # The field may appear to lose focus frequently as the focus shifts
      # between child views. The run later helps to verify the focus has, in
      # fact, completely left the field.
      Ember.run.later @, ->
        if !@isFocused() and                            # Verify focus was really lost
        displayValue.length >= get(@, 'minLength') and  # Don't autocomplete if display value is too short
        get(@, 'autocompleteOnFocusOut')                # Don't autocomplete if configured not to
          @complete()
          # TODO: Fix this code; it sometimes leads to extra tags in
          #       autocomplete with tags view.
          # @searchFor(displayValue).then((results) =>
          #   return unless get(@, 'state') is 'inDOM'    # Input must be in DOM to update it
          #   result = if selected in results then selected else results[0]
          #   @complete(result) if result
          # )
      , 100
  , 'hasFocus'

  searchFor: (str, disableRemote) ->
    promise = new Ember.RSVP.Promise((resolve, reject) =>
      processResults = (search, results) ->
        return unless str is search
        @off('didRetrieveSuggestions', @, processResults)
        Ember.run(null, resolve, @sort(results, str))

      @on('didRetrieveSuggestions', @, processResults)

      source = get(@, 'source') ? Ember.A()
      source = (get(source) if typeOf(source) is 'string' and source isnt '') || source

      set(@, 'search', str)

      @_triggerRemote(source) unless disableRemote
      @trigger('didRetrieveSuggestions', str, @_arraySearch(source)) if Ember.isArray(source)
    )
    promise

  ###
    @private

    Assemble or fetch search results. Will trigger the `searchForSuggestions`
    on the view's controller if the updated property is `'search'`.

    @method _searchDidChange
    @param Ember.View view Should typically be this view instance
    @param String property The property that changed
  ###
  _searchDidChange: Ember.observer (view, property) ->
    search = get(@, '_search') || ''
    len = search.length
    len = len ? 0

    if len < get(@, 'minLength')
      suggestions = Ember.A()
      set @, 'allSuggestions', suggestions
      return suggestions

    @searchFor(search, property isnt '_search').then((results) =>
      displayValue = get @, 'displayValue'
      set(@, 'allSuggestions', results) if search is displayValue
    )

    get @, 'allSuggestions'
  , '_search', 'matcher', 'minLength', 'source', 'source.length'

  ###
    @private

    Search the provided array of items for suggestions.

    @method _getViewClass
    @param Array source An array of items to search for suggestions
    @return Array
  ###
  _arraySearch: (source) ->
    matcher = get(@, 'matcher')
    suggestions = Ember.A()

    for term in source
      do (term) =>
        suggestions.push(term) if matcher.call(@, term)

    suggestions

  ###
    @private

    Trigger action on context.

    @method _triggerRemote
    @param Mixed source
    @chainable
  ###
  _triggerRemote: (source) ->
    context = get @, 'context'
    action = 'searchForSuggestions'

    # Trigger action only if the context will handle it
    # or the source is a string (async/remote search)
    if (typeOf(source) is 'string') or (context? and typeOf(context[action]) is 'function')
      @triggerAction(
        action: action
        actionContext: @
      )

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

    If valid, copy the input value to the `search` property.

    @method _displayValueChangeHandler
  ###
  _displayValueChangeHandler: ->
    set(@, '_search', if get(@, 'displayValue.length') < get(@, 'minLength') then '' else get(@, 'displayValue'))


###############################################################################
###############################################################################


###
  `Emberella.AutocompleteInputView` is designed to be a drop-in input view for
  `Emberella.AutocompleteView`. It sets up value bindings and disables the
  browser's built in autocomplete functionality.

  @class AutocompleteInputView
  @namespace Emberella
  @extends Ember.TextField
  @uses Emberella.FocusableMixin
  @uses Emberella.KeyboardControlMixin
  @uses Emberella.MembershipMixin
###
Emberella.AutocompleteInputView = Ember.TextField.extend Emberella.FocusableMixin, Emberella.KeyboardControlMixin, Emberella.MembershipMixin,
  inherit: ['value']
  attributeBindings: ['autocomplete']
  autocomplete: 'off' #disable browser autocomplete


###############################################################################
###############################################################################


###
  `Emberella.AutocompleteListView` is designed to be a drop-in collection view
  for `Emberella.AutocompleteView`. It sets up property bindings to allow
  properties to be inherited from the parent `Emberella.AutocompleteView`.

  @class AutocompleteListView
  @namespace Emberella
  @extends Ember.CollectionView
  @uses Emberella.MembershipMixin
###
Emberella.AutocompleteListView = Ember.CollectionView.extend Emberella.MembershipMixin,
  inherit: ['itemViewClass', 'content:suggestions', 'isVisible:isListVisible']
  classNames: ['emberella-autocomplete-list']


###############################################################################
###############################################################################


###
  `Emberella.AutocompleteItemView` is designed to be a drop-in suggestion
  listing view for `Emberella.AutocompleteView`. It sets up property bindings
  to allow certain properties, including `template`, to be inherited from its
  host `Emberella.AutocompleteView`.

  @class AutocompleteItemView
  @namespace Emberella
  @extends Ember.View
  @uses Emberella.MembershipMixin
###
Emberella.AutocompleteItemView = Ember.View.extend Emberella.MembershipMixin,
  inherit: ['template', 'highlighter', 'searchExpression', 'contentPath']

  classNames: ['emberella-autocomplete-item']

  classNameBindings: ['selected']

  leadViewBinding: 'parentView.parentView'

  ###
    The string to display as the suggestion.

    @property displayContent
    @type String
    @default ''
    @readOnly
  ###
  displayContent: Ember.computed ->
    content = get @, 'content'
    displayContent = get(content, get(@, 'contentPath')) ? ''
    searchExpression = get @, 'searchExpression'
    highlighter = get @, 'highlighter'
    displayContent.replace searchExpression, highlighter
  .property('content', 'contentPath').readOnly()

  selected: Ember.computed ->
    get(@, 'content') is get(@, 'leadView.selected')
  .property 'content', 'leadView.selected'

  mouseEnter: (e) ->
    @dispatch('selectMember')

  click: (e) ->
    @dispatch('selectMember', @, true)
