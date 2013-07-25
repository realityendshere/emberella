#= require ./autocomplete
#= require ./tags_input

Emberella = window.Emberella
jQuery = window.jQuery
get = Ember.get
set = Ember.set

Emberella.AutocompleteTagsView = Emberella.AutocompleteView.extend
  displayValueBinding: 'inputView.inputView.value'

  # init: ->
  #   root.ACT = @
  #   @_super()

  value: ''

  content: null

  delimiter: null

  placeholder: ''

  deleteCharacter: 'x'

  deleteTitle: "Remove tag"

  autocompleteOnFocusOut: true

  inputViewClass: 'Emberella.AutocompleteTagsInputView'

  capture: ->
    return unless (inputView = get(@, 'inputView'))?
    hasFocus = get @, 'hasFocus'
    inputView.capture() if inputView.capture?

  selectMember: (view, confirm) ->
    @_super(view)
    @capture() if confirm

  focusIn: (e) ->
    @_super(e)
    return unless (inputView = get(@, 'inputView'))?
    inputView.focus(e)

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

  tagify: ->
    [get(@, 'selected')]
