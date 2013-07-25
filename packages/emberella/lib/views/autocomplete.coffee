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

Emberella.AutocompleteView = Ember.ContainerView.extend Ember.ViewTargetActionSupport, Emberella.KeyboardControlMixin, Emberella.FocusableMixin,
  init: ->
    set(@, 'search', '')
    @_super()

  _isListVisible: false

  isAutocomplete: true

  classNames: ['emberella-autocomplete']

  tabindex: -1

  autoFocus: true

  items: 10

  delay: 10

  minLength: 1

  selected: null

  value: Ember.computed.alias('displayValue')

  contentPath: ''

  searchPath: ''

  searches: [
    '^%s$' #exact match
    '^%s'  #starts with search
    '^%q'  #starts with word
    '%s'   #string found
  ]

  search: null

  source: Ember.A()

  displayValueBinding: 'inputView.value'

  showEmptyListing: true

  autocompleteOnFocusOut: false

  childViews: ['inputView', 'listView']

  inputViewClass: 'Emberella.AutocompleteInputView'

  listViewClass: 'Emberella.AutocompleteListView'

  itemViewClass: 'Emberella.AutocompleteItemView'

  defaultTemplate: Ember.Handlebars.compile [
    '<span class="emberella-autocomplete-item-content">{{{view.displayContent}}}</span>'
  ].join(' ')

  defaultHighlighter: (str, p1, offset, s) ->
    ['<strong>', p1, '</strong>'].join('')

  defaultUpdater: (value = get(@, 'selected')) ->
    contentPath = get(@, 'contentPath')
    set(@, 'displayValue', get(value, contentPath))

  hasFocusBinding: 'inputView.hasFocus'

  highlighter: Ember.computed.defaultTo 'defaultHighlighter'

  updater: Ember.computed.defaultTo 'defaultUpdater'

  suggestions: Ember.computed ->
    items = get @, 'items'
    displayValue = get(@, 'displayValue') || ''
    allSuggestions = get(@, 'allSuggestions').slice()
    sorter = get @, 'sorter'
    suggestions = sorter.call @, allSuggestions
    _suggestions = suggestions.slice(0, items)

    return _suggestions if _suggestions.length > 0 or !get(@,'showEmptyListing') or displayValue is ''

    contentPath = get @, 'contentPath'
    inputObject = displayValue

    if contentPath isnt ''
      inputObject = {}
      parts = contentPath.split('.')
      while parts.length > 0
        part = parts.shift()
        inputObject[part] = if parts.length > 0 then {} else displayValue

    _suggestions.pushObject(inputObject)

    _suggestions
  .property 'allSuggestions', 'items', 'sorter'

  # Volatile to prevent global regex cursor madness
  # See: http://stackoverflow.com/questions/1520800/why-regexp-with-global-flag-in-javascript-give-wrong-results
  searchExpression: Ember.computed ->
    new RegExp(get(@, '_searchExpression'), 'gi')
  .property('_searchExpression').volatile().readOnly()

  _searchExpression: Ember.computed ->
    search = get(@, '_escaped_search')
    words = '(' + search.replace(/(\\\s)+/gi, '|').split('|').join(')|(') + ')'
    searchExpression = [search]
    searchExpression = [].concat(searchExpression, '|', words) if words.indexOf('|') >= 0
    searchExpression.unshift('(')
    searchExpression.push(')')
    searchExpression.join('')
  .property '_escaped_search'

  _escaped_search: Ember.computed ->
    search = get(@, 'search')
    search = jQuery.trim(search ? '')
    search.replace(ESCAPE_REG_EXP, ESCAPE_REPLACEMENT)
  .property 'search'

  allSuggestions: Ember.A()

  searchPaths: Ember.computed ->
    searchPath = get(@, 'searchPath')
    searchPath = searchPath.split(/\s+/) if searchPath.split?
    ret = Ember.A([get(@, 'contentPath')])
    ret.addObjects(searchPath) is Ember.isArray(searchPath)
    ret
  .property('contentPath', 'searchPath')

  stringToSearchExpression: (str, search = get(@, '_escaped_search')) ->
    searchExpression = get @, 'searchExpression'
    searchExpression = searchExpression.toString().split('/').slice(1, -1).join('/')

    str = str.replace SEARCH_SUBSTITUTION, search
    str = str.replace QUERY_SUBSTITUTION, searchExpression

    new RegExp(str, 'gi')

  matcher: Ember.computed.defaultTo 'defaultMatcher'
  sorter: Ember.computed.defaultTo 'defaultSorter'

  defaultMatcher: (item) ->
    searchPaths = get(@, 'searchPaths')
    match = false

    for path in searchPaths
      if get(@, 'searchExpression').test(get(item, path))
        match = true
        break;

    match

  defaultSorter: (suggestions) ->
    search = get(@, 'search')
    searchPaths = get(@, 'searchPaths')
    return Ember.A() unless search
    search = search.toLowerCase()
    words = search.split(/\s+/)
    searches = get @, 'searches'
    suggestions = suggestions.slice().reverse()
    results = []

    for s, si in searches
      s = @stringToSearchExpression(s)
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


  isListVisible: Ember.computed (key, value) ->
    key = '_' + key
    len = get @, 'suggestions.length'

    #getter
    if arguments.length is 1
      return (get(@, 'hasFocus') and get(@, key) and len > 0)

    #setter
    else
      set(@, key, value)
      return @
  .property('hasFocus', '_isListVisible', 'suggestions.length', 'displayValue').volatile()

  debouncedValueDidChange: Ember.computed ->
    Emberella.debounce((=>
      @_displayValueChangeHandler()
    ), get(@, 'delay'))
  .property 'delay'

  inputView: Ember.computed ->
    @getInputViewClass()
  .property 'inputViewClass'

  listView: Ember.computed ->
    @getListViewClass()
  .property 'listViewClass'

  select: (value = get(@, 'selected'), retainFocus = true) ->
    return unless value

    hideList = ->
      @hide()
      @removeObserver('_suggestions', @, hideList)

    @addObserver('_suggestions', @, hideList)
    get(@hide(), 'updater').call @, value
    @focus() if retainFocus

  focus: ->
    return @ unless (inputView = get(@, 'inputView'))? and get(inputView, 'state') is 'inDOM'

    if typeOf(inputView.focus) is 'function'
      inputView.focus()
    else
      element = get(inputView, 'element')
      element?.focus()
    @

  show: ->
    set @, 'isListVisible', true
    @

  hide: ->
    set @, 'isListVisible', false
    @

  next: ->
    @move(1, get(@, 'suggestions.firstObject'))
    @

  previous: ->
    @move(-1, get(@, 'suggestions.lastObject'))
    @

  move: (delta, defaultSelection) ->
    suggestions = get @, 'suggestions'
    idx = @indexOfSelection()
    newIdx = Math.min(Math.max(-1, (idx + delta)), suggestions.length)

    selected = (if newIdx < 0 then get(suggestions, 'lastObject') else suggestions.objectAt(newIdx)) ? defaultSelection

    set @, 'selected', selected
    @

  selectMember: (view, confirm) ->
    content = get(view, 'content')
    set(@, 'selected', content)
    @select(content) if confirm

  indexOfSelection: ->
    suggestions = get(@, 'suggestions')
    return -1 if !suggestions or suggestions.length is 0
    suggestions.indexOf get(@, 'selected')

  isSelectedInContent: ->
    @indexOfSelection() >= 0

  ###
    Convenience method for obtaining the view class for suggestion listings.

    @method getItemViewClass
    @return Ember.View
  ###
  getItemViewClass: ->
    @_getViewClass 'itemViewClass'

  ###
    Convenience method for obtaining the view class for text input.

    @method getInputViewClass
    @return Ember.View
  ###
  getInputViewClass: ->
    @_getViewClass 'inputViewClass'
  ###
    Convenience method for obtaining the view class for suggestion list.

    @method getListViewClass
    @return Ember.View
  ###
  getListViewClass: ->
    @_getViewClass 'listViewClass'

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

  contentDidChange: Ember.observer ->
    if get('suggestions.length') is 0 then @hide() else @show()
    set(@, 'selected', if get(@, 'autoFocus') then (get(@, 'suggestions.firstObject') ? null) else null)
  , 'suggestions', 'suggestions.length'

  upArrowPressed: (e, alt, ctrl, meta, shift) ->
    len = get @, 'suggestions.length'
    return if len is 0 or alt or ctrl or meta or shift
    e.preventDefault()
    @show().previous()

  downArrowPressed: (e, alt, ctrl, meta, shift) ->
    len = get @, 'suggestions.length'
    return if len is 0 or alt or ctrl or meta or shift
    e.preventDefault()
    @show().next()

  enterPressed: (e, alt, ctrl, meta, shift) ->
    @select()

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

  _displayValueDidChange: Ember.observer ->
    if get(@, 'displayValue.length') < get(@, 'minLength') then set(@, 'search', '') else get(@, 'debouncedValueDidChange')()
  , 'displayValue', 'minLength'

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
        @select(null, false) if !get(@, 'hasFocus') and get(@, 'autocompleteOnFocusOut')
      , 100
  , 'hasFocus'

  _displayValueChangeHandler: ->
    set(@, 'search', if get(@, 'displayValue.length') < get(@, 'minLength') then '' else get(@, 'displayValue'))

  provideSearchResults: (search, results) ->
    currentSearch = get(@, 'search')
    results = if Ember.isArray(results) then results else [results]
    @_remoteResults[search] = results
    set(@, 'allSuggestions', results) if search is currentSearch
    @

  _searchDidChange: Ember.observer (view, property) ->
    len = get(@, 'search.length')
    len = len ? 0

    if len < get(@, 'minLength')
      suggestions = Ember.A()
      set @, 'allSuggestions', suggestions
      return suggestions

    if property is 'search'
      @triggerAction(
        action: 'searchForSuggestions'
        target: get @, 'controller'
        actionContext: @
      )

    source = get(@, 'source') ? Ember.A()
    source = get(source) if typeOf(source) is 'string' and source isnt ''

    @_arraySearch(source) if Ember.isArray(source)
  , 'search', 'matcher', 'minLength', 'source', 'source.length'

  _arraySearch: (source) ->
    matcher = get(@, 'matcher')
    suggestions = Ember.A()

    for term in source
      do (term) =>
        suggestions.push(term) if matcher.call(@, term)

    set @, 'allSuggestions', suggestions

    suggestions


Emberella.AutocompleteInputView = Ember.TextField.extend Emberella.FocusableMixin, Emberella.KeyboardControlMixin,
  attributeBindings: ['autocomplete']
  autocomplete: 'off' #disable browser autocomplete

Emberella.AutocompleteListView = Ember.CollectionView.extend Emberella.MembershipMixin,
  inherit: ['itemViewClass', 'content:suggestions', 'isVisible:isListVisible']
  classNames: ['emberella-autocomplete-list']

Emberella.AutocompleteItemView = Ember.View.extend Emberella.MembershipMixin,
  inherit: ['template', 'highlighter', 'searchExpression', 'contentPath']

  classNames: ['emberella-autocomplete-item']

  classNameBindings: ['selected']

  leadViewBinding: 'parentView.parentView'

  displayContent: Ember.computed ->
    return '' if get(@, 'divider')
    content = get @, 'content'
    displayContent = get(content, get(@, 'contentPath')) ? ''
    searchExpression = get @, 'searchExpression'
    highlighter = get @, 'highlighter'
    displayContent.replace searchExpression, highlighter
  .property 'content'

  selected: Ember.computed ->
    get(@, 'content') is get(@, 'leadView.selected')
  .property 'content', 'leadView.selected'

  mouseEnter: (e) ->
    @dispatch('selectMember')

  click: (e) ->
    @dispatch('selectMember', @, true)
