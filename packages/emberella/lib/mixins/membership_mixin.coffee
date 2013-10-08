###
@module emberella
@submodule emberella-mixins
###

Emberella = window.Emberella
jQuery = window.jQuery
get = Ember.get
typeOf = Ember.typeOf

###
  Some views (like `Emberella.TagsInput`) are container views that contain a
  variety of child views and must share properties and collaborate in response
  to events. The `Emberella.MembershipMixin` allows child views to easily
  establish a stronger bond with a specified ancestor view.

  For example, each tag listing in `Emberella.TagsInput` inherits its template
  from its parent container. This allows tag items to be customized directly
  through the handlebars template or without subclassing the item view class.
  Additionally, each tag listing must communicate with the parent container in
  response to certain events --- easily accomplished using the `dispatch()`
  method.

  @class MembershipMixin
  @namespace Emberella
###

Emberella.MembershipMixin = Ember.Mixin.create
  ###
    The path to the view this member view should collaborate with. Typically,
    the lead view will be an ancestor container view setup to manage multiple
    member views. (e.g. the tags input view or an autocomplete
    suggestions listing).

    @property leadViewBinding
    @type String
    @default 'parentView'
  ###
  leadViewBinding: 'parentView'

  init: ->
    @applyInheritedBindings()
    @_super()

  ###
    Bind the array of properties specified in the `inherit` attribute and
    setup computed aliases to relavant properties on the lead view.

    For example, if `this.inherit` is `['template', 'isVisible:isChildVisible']`
    then this view's `template` property would become an alias for
    `leadView.template` and the `isVisible` property would become an alias for
    `leadView.isChildVisible`.

    @method applyInheritedBindings
    @chainable
  ###
  applyInheritedBindings: ->
    inherit = @inherit
    return @ unless Ember.isArray(inherit)

    inherit.forEach (binding) =>
      [property, path] = binding.split(':')
      path = path || property
      propertyPath = 'leadView.' + path
      inheritComputed = Ember.computed.alias(propertyPath)
      Ember.defineProperty @, property, inheritComputed

    @

  ###
    Attempt to call a method on the lead view.

    @method dispatch
    @param String message The method to call on the lead view
    @param Mixed arg/args... Arguments to send to the method on the lead view
    @chainable
  ###
  dispatch: (message, arg = @, args...) ->
    return @ if !(leadView = get(@, 'leadView')) or Ember.isEmpty(message) or get(leadView, 'disabled')
    args = [arg].concat(args)
    leadView[message].apply(leadView, args) if typeOf(leadView[message]) is 'function'
    @
