# Copied from https://github.com/Addepar/ember-table/blob/master/dependencies/ember-addepar-mixins/style_bindings.js

Ember.StyleBindingsMixin = Ember.Mixin.create
  isStyleBindings: true

  init: ->
    @applyStyleBindings()
    @_super()

  concatenatedProperties: ['styleBindings']

  attributeBindings: ['style']

  unitType: 'px'

  createStyleString: (styleName, property) ->
    value = @get property
    return unless value?
    @makeStyleProperty styleName, value

  makeStyleProperty: (styleName, value) ->
    if Ember.typeOf(value) is 'number'
      value = value + @get('unitType')
    "#{styleName}:#{value};"

  applyStyleBindings: ->
    styleBindings = @styleBindings
    return unless styleBindings

    # get properties from bindings e.g. ['width', 'top']
    lookup = {}
    styleBindings.forEach (binding) ->
      [property, style] = binding.split(':')
      lookup[(style or property)] = property
    styles     = Ember.keys(lookup)
    properties = styles.map (style) -> lookup[style]

    # create computed property
    styleComputed = Ember.computed =>
      styleTokens = styles.map (style) =>
        @createStyleString style, lookup[style]
      styleString = styleTokens.join('')
      return styleString unless styleString.length is 0

    # add dependents to computed property
    styleComputed.property.apply(styleComputed, properties)

    # define style computed properties
    Ember.defineProperty @, 'style', styleComputed
