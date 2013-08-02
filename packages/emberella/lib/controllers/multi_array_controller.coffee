###
@module emberella
@submodule emberella-controllers
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set

###
  Assembles an array of array controllers.

  @example
    // Sets `arrangedContent` to an array containing the array controllers
    // App.PeopleController, App.PlacesController, and App.ThingsController
    App.SidebarController = Emberella.MultiArrayController.extend({
      subArrays: ['people', 'places', 'things']
    });

  @class MultiArrayController
  @namespace Emberella
  @extends Ember.ArrayController
###
Emberella.MultiArrayController = Ember.ArrayController.extend
  init: ->
    @_subArraysDidChange()
    @_super()

  ###
    An array of strings describing the names of array controllers to include
    as part of the `arrangedContent`. Sub-controllers will be arranged in the
    order listed.

    @property subArrays
    @type Array
    @default []
  ###
  subArrays: []

  arrangedContent: Ember.computed ->
    subArrays = Ember.A get(@, 'subArrays')
    subArrays = subArrays.uniq() unless get(@, 'allowDuplicates')

    [].concat(@_super(), subArrays.map((name) =>
      controller = get(@, 'controllers.' + name)
      heading = Ember.String.capitalize(name)

      Ember.Object.create({
        heading: heading
        children: controller
      })
    ))
  .property('content', 'sortProperties.@each', 'needs.@each', 'subArrays.@each')

  ###
    @private

    Ensure sub-arrays are also added to the `needs` array so they can be
    accessed by this controller.

    @method _subArraysDidChange
    @chainable
  ###
  _subArraysDidChange: Ember.observer ->
    Ember.A(get(@, 'needs')).addObjects(Ember.A(get(@, 'subArrays')))
    @
  , 'subArrays', 'subArrays.@each'
