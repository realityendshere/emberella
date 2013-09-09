###
@module emberella
@submodule emberella-mixins
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set
typeOf = Ember.typeOf
guidFor = Ember.guidFor

SEARCH_SUBSTITUTION = /%s/g

###
  `Emberella.AutocompleteSupport` provides a basic structure for fetching and
  caching remote autocomplete suggestions for a given search string.

  This mixin is intended to extend a controller.

  If you'll be using `Emberella.AutocompleteView` with a remote source, extend
  its controller with this mixin to get started quickly. This mixin uses the
  autocomplete view instance's `source` property to lookup an associated URL
  string. The `search` and `url` are then sent to your controller's
  `didRequestSuggestions()` method to perform the necessary asynchronous
  queries. If successful, the results of the query can be supplied back to the
  autocomplete view using this mixin's `provideSearchResults()` method.

  @example
    AutocompleteController = Ember.ArrayController.extend(Emberella.AutocompleteSupport, {

      // The autocomplete view instance's `source` property should be set to
      // `'cities'` to allow the AutocompleteSupport mixin to find the URL-like
      // string and replace the %s with the current search string.

      cities: '/api/search?q=%s',


      // Overriding `didRequestSuggestions()` to inject custom suggestion
      // fetching behavior.

      didRequestSuggestions: function(actionContext, search, url) {
        var jqxhr;

        jqxhr = jQuery.ajax({
          context: this,
          url: url,
          dataType: 'json'
        }).done(function(result, status, xhr) {

          // Inject results fetched from AJAX response into the view with the
          // `provideSearchResults()` method.

          this.provideSearchResults(actionContext, search, url, result.search || Ember.A());
        });
      }
    });

  @class AutocompleteSupport
  @namespace Emberella
###

Emberella.AutocompleteSupport = Ember.Mixin.create
  init: ->
    @__cached_results = {}
    @_super()

  actions: {
    searchForSuggestions: -> @searchForSuggestions.apply @, arguments
  }

  ###
    Get cached results for a given view/key.

    @method getCacheResults
    @param Ember.View actionContext The view making the search request
    @param String url A key to retrieve results from
  ###
  getCacheResults: (actionContext, url) ->
    path = [guidFor(actionContext), url].join('.')
    get(@__cached_results, path)

  ###
    Set cached results for a given view/key.

    @method setCacheResults
    @param Ember.View actionContext The view making the search request
    @param String url A key to cache results with
    @param Array value The value to cache
  ###
  setCacheResults: (actionContext, url, value) ->
    uniq = guidFor(actionContext)
    set(@__cached_results, uniq, (get(@__cached_results, uniq) ? {}))
    path = [uniq, url].join('.')
    set(@__cached_results, path, value)

  ###
    Supply suggestions to the view.

    Note: results from the server are directly injected into the view
    instance's `allSuggestions` property to allow multiple autocomplete
    views to coexist without impacting each other's visibility state,
    suggestions, etc.

    @method provideSearchResults
    @param Ember.View actionContext The view making the search request
    @param String search The original search string
    @param String url The "URL" string
    @param Array results The list of available suggestions
  ###
  provideSearchResults: (actionContext, search, url, results) ->
    results = if Ember.isArray(results) then results else [results]
    @setCacheResults(actionContext, url, results)
    actionContext.trigger('didRetrieveSuggestions', search, results)
    @

  ###
    The handler for the `searchForSuggestions` action.

    @event searchForSuggestions
    @param Ember.View actionContext The view making the search request
  ###
  searchForSuggestions: (actionContext) ->
    actionSource = actionContext.get('source')
    search = actionContext.get('search')

    # Store the URL pattern in the property specified by the target view's
    # `source` property.
    source = get(@, actionSource)
    return if typeOf(source) isnt 'string'

    url = @_buildSuggestionURL(source, search)
    suggestions = @getCacheResults(actionContext, url)

    if Ember.isArray(suggestions)
      @provideSearchResults(actionContext, search, url, suggestions)
    else if !suggestions?
      @setCacheResults(actionContext, url, {'isLoading': true})
      @didRequestSuggestions(actionContext, search, url) unless (search is '' or url is '')
    null

  ###
    Override this method in your controller to perform a query for
    autocomplete suggestions.

    @method didRequestSuggestions
    @param Ember.View actionContext The view making the search request
    @param String search The original search string
    @param String url The "URL" string
  ###
  didRequestSuggestions: Ember.K

  ###
    @private

    Replace "%s" in a given string with the current search parameter.

    @method _buildSuggestionURL
    @param String source String to sub the search string into
    @param String search The original search string
  ###
  _buildSuggestionURL: (source, search) ->
    url = source.replace SEARCH_SUBSTITUTION, search
    url = search if url is ''
    url
