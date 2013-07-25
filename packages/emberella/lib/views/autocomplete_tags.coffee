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

###
  `Emberella.AutocompleteTagsView` combines the abilities of
  `Emberella.AutocompleteView` and `Emberella.TagsInput`.

  TODO: The basics work, but there is much todo here.

  @class AutocompleteTagsView
  @namespace Emberella
  @extends Emberella.AutocompleteView
###

Emberella.AutocompleteTagsView = Emberella.AutocompleteView.extend
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

  ###
    Create a new tag using the currently selected suggestion.

    @method capture
    @chainable
  ###
  capture: ->
    return unless (inputView = get(@, 'inputView'))?
    inputView.capture() if inputView.capture?
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
  ]

  ###
    Simply returns an array with the currently selected suggestion as the
    only member.

    @method tagify
    @return Array
  ###
  tagify: ->
    [get(@, 'selected')]
