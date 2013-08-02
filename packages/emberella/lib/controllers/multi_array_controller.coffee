Emberella = window.Emberella
get = Ember.get
set = Ember.set

Emberella.MultiArrayController = Ember.ArrayController.extend Emberella.SelectableMixin,
  _needs: []

  groupNameProperty: 'groupName'

  subArrays: []

  needs: Ember.computed (key, value) ->
    privateKey = '_' + key

    if arguments.length is 1
      return get(@, privateKey).concat(get(@, 'subArrays'))

    else
      return set(@, privateKey, value)

  .property('subArrays.@each')

  arrangedContent: Ember.computed ->

    subArrays = Ember.A get(@, 'subArrays')

    [].concat(@_super(), subArrays.map((name) =>
      controller = get(@, 'controllers.' + name)
      groupName = Ember.String.capitalize(name)

      Ember.Object.create({
        groupName: groupName
        groupNameProperty: get(@, 'groupNameProperty')
        children: controller
      })
    ))
  .property('content', 'sortProperties.@each', 'subArrays.@each')
