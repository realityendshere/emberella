#= require ./autocomplete
#= require ./tags_input

###
@module emberella
@submodule emberella-views
###

Emberella = window.Emberella
jQuery = window.jQuery
get = Ember.get
set = Ember.set
typeOf = Ember.typeOf

###
  `Emberella.AutocompleteTagsView` combines the abilities of
  `Emberella.AutocompleteView` and `Emberella.TagsInput`.

  TODO: The basics work, but there is much todo here.
  TODO: Refactor to better integrate tags/autocomplete functionality.

  @class AutocompleteTagsView
  @namespace Emberella
  @extends Emberella.AutocompleteView
###

Emberella.AutocompleteTagsView = Emberella.AutocompleteView.extend
  ###
    The level of effort this view should make to swap user input with the most
    likely autocomplete suggestion.

    This setting comes into play primarily when a user pastes text that
    contains delimiter strings into the autocomplete tags field. The pasted
    text may then be optionally replaced or rejected automatically depending
    on the `autocompleteThreshold`. You may also add custom handling to the
    `didAddValue` event to inject entirely custom logic.

    0: Leave newly added strings as they are. No autocomplete to be attempted.

    1: Attempt to replace each newly added string with the top-ranked
       suggestion. If no suggestions can be found, leave the original string
       as is.

    2: Attempt to replace each newly added string with the top-ranked
       suggestion. Reject/remove any string without suggestions.

    @property autocompleteThreshold
    @type Integer
    @default 1
  ###
  autocompleteThreshold: 1

  ###
    Binds the `displayValue` property to the tag input view's value. As
    `displayValue` changes, the `search` property may eventually be updated to
    initiate the gathering of suggested values.

    @property displayValueBinding
    @type String
    @default 'inputView.inputView.value'
  ###
  displayValueBinding: 'inputView.inputView.value'

  ###
    The content of this tags input. The content may be an array of strings
    or objects.

    @property content
    @type Array
    @default null
  ###
  content: null

  ###
    See `Emberella.TagsInput`.

    @property delimiter
    @type {String|Array}
    @default ','
  ###
  delimiter: null

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
  deleteTitle: "Remove tag"

  ###
    When `true`, the selected autocomplete suggestion is captured as a tag when
    the input loses focus.

    @property autocompleteOnFocusOut
    @type Boolean
    @default false
  ###
  autocompleteOnFocusOut: true

  ###
    The view class to use as the input field.

    @property inputViewClass
    @type Ember.View
    @default 'Emberella.AutocompleteTagsInputView'
  ###
  inputViewClass: 'Emberella.AutocompleteTagsInputView'

  updater: Ember.aliasMethod('capture')

  ###
    Create a new tag using the currently selected suggestion.

    @method capture
    @chainable
  ###
  capture: ->
    return unless (inputView = get(@, 'inputView'))?
    inputView.capture() if inputView.capture?
    set(@, 'selected', null)
    @

  ###
    Set the `selected` property to the `content` of the provided view.

    Optionally, capture the view's content as a new tag.

    @method selectMember
    @param Ember.View The view with content to mark `selected`
    @param Boolean capture If true, capture selected content as tag
    @chainable
  ###
  selectMember: (view, capture) ->
    @_super(view)
    @capture() if capture
    @

  ###
    Shift focus to the tags input element.

    @event focusIn
    @param Event e
  ###
  focusIn: (e) ->
    @_super(e)
    return unless (inputView = get(@, 'inputView'))?
    inputView.focus(e)

  ###
    Override this method to inject custom tag creation/retrieval logic into
    your tag input view.

    @event didAddValue
    @param {String|Object} value A processed (delimiter split) value to add
    @param Integer idx The index at which to insert the new value
    @param Array results The autocomplete suggestions, if any
    @param String searchValue String used to search for autocomplete suggestions
  ###
  didAddValue: Ember.K

  ###
    Override this method to inject custom rejection logic into your view.

    @event didRejectValue
    @param String value The string that got rejected
    @param Integer idx The index at which the value was rejected
  ###
  didRejectValue: Ember.K

  ###
    @protected

    If a user pastes a string into the autocomplete field, tags may be created
    outside of the autocomplete interface. This method attempts to address this
    scenario by assembling suggestions for any newly added strings.

    @method _didAddValue
    @param {String|Object} value The newly added tag value
    @param Integer idx The index at which to insert the new value
  ###

  # TODO: Improve handling of duplicate tags
  _didAddValue: (value, idx) ->
    content = get(@, 'content')
    autocompleteThreshold = get(@, 'autocompleteThreshold')

    if autocompleteThreshold and typeOf(value) is 'string'
      @searchFor(value).then((results) =>
        return unless (inputView = get(@, 'inputView'))?
        idx = get(@, 'content').indexOf value
        if results? and results.length and (result = results[0]) isnt value and !(isContained = inputView.contains(result))
          inputView.swap(value, result)
          @trigger 'didAddValue', result, idx, results
        else
          if autocompleteThreshold is 2 or isContained
            isEnd = get(inputView, 'cursor') is content.length
            content.removeAt idx
            set(inputView, 'cursor', content.length) if isEnd
            @trigger('didRejectValue', value, idx, results) if autocompleteThreshold is 2
          else
            @trigger 'didAddValue', value, idx, results
      )
    else
      @trigger 'didAddValue', value, idx

    null

  _didRemoveValue: (value) ->
    @trigger 'didRemoveValue', value

###############################################################################
###############################################################################


###
  The `Emberella.AutocompleteTagsInputView` is a specially modified
  `Emberella.TagsInput` designed to integrate with an
  `Emberella.AutocompleteView`. This input binds to a variety of properties on
  the host view to make them easier to access and modify.

  @class AutocompleteTagsInputView
  @namespace Emberella
  @extends Emberella.TagsInput
  @uses Emberella.MembershipMixin
###

Emberella.AutocompleteTagsInputView = Emberella.TagsInput.extend Emberella.MembershipMixin,
  inherit: [
    'content'
    'contentPath'
    'delimiter'
    'placeholder'
    'deleteCharacter'
    'deleteTitle'
    'tagOnFocusOut:autocompleteOnFocusOut'
    'selected'
    'stylist'
  ]

  ###
    Simply returns an array with the currently selected suggestion as the
    only member.

    @method tagify
    @return Array
  ###
  tagify: (value) ->
    selected = get(@, 'selected')
    if selected? then [selected] else @_super(value)

  _didAddValue: (value, idx) ->
    @dispatch('_didAddValue', value, idx)

  _didRemoveValue: (value) ->
    @dispatch('_didRemoveValue', value)
