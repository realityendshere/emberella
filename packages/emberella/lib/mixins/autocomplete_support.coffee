###
@module emberella
@submodule emberella-mixins
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set
typeOf = Ember.typeOf
guidFor = Ember.guidFor

SEARCH_SUBSTITUTION = /%s/

###
  `Emberella.AutocompleteSupport`

  @class AutocompleteSupport
  @namespace Emberella
###

Emberella.AutocompleteSupport = Ember.Mixin.create
  init: ->
    @__cached_results = {}
    @_super()

  getCacheResults: (actionContext, url) ->
    path = [guidFor(actionContext), url].join('.')
    get(@__cached_results, path)

  setCacheResults: (actionContext, url, value) ->
    uniq = guidFor(actionContext)
    set(@__cached_results, uniq, (get(@__cached_results, uniq) ? {}))
    path = [uniq, url].join('.')
    set(@__cached_results, path, value)

  provideSearchResults: (actionContext, search, url, results) ->
    currentSearch = get(actionContext, 'search')
    results = if Ember.isArray(results) then results else [results]
    @setCacheResults(actionContext, url, results)
    set(actionContext, 'allSuggestions', results) if search is currentSearch
    @

  searchForSuggestions: (actionContext) ->
    actionSource = actionContext.get('source')
    search = actionContext.get('search')
    source = get(@, actionSource)
    return if typeOf(source) isnt 'string'

    url = @_buildURL(source, search)
    suggestions = @getCacheResults(actionContext, url)

    if Ember.isArray(suggestions)
      @provideSearchResults(actionContext, search, url, suggestions)
    else
      @setCacheResults(actionContext, url, Ember.A())
      @didRequestSuggestions(actionContext, search, url) unless (search is '' or url is '')

  didRequestSuggestions: Ember.K

  _buildURL: (source, search) ->
    url = source.replace SEARCH_SUBSTITUTION, search
    url = search if url is ''
    url
