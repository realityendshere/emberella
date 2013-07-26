###
@module emberella
###

###
  `Emberella.forEachAsync` iterates over a large array gradually. The function
  will process items in the array for a given number of ms, stop iterating for
  a given wait time, then proceed and wait until the iteration is complete.

  * iterate for `runTime` milliseconds
  * if complete, call `completeFn`
  * otherwise, standby for `wait` milliseconds (releases Javascript thread)
  * iterate for `runTime` milliseconds
  * if complete, call `completeFn`
  * wash, rinse, repeat until array is fully processed...

  This can be useful for iterating over a large array without locking the UX
  in the browser.

  TODO: Promises?

  @method forEachAsync
  @param Mixed context The context (what `this` will be)
  @param Array objects The array to iterate over
  @param Function eachFn The function to call during each iteration
  @param Function completeFn A callback function
  @param Integer runTime The number of ms to process array items
  @param Integer wait The number of ms to wait between iteration sets
  @namespace Emberella
###

Emberella.forEachAsync = (context, objects, eachFn, completeFn, runTime = 200, wait = 200) ->
  if (!(Ember.Enumerable.detect(objects) || Ember.isArray(objects)))
    throw new TypeError("Must pass Ember.Enumerable to Emberella.forEachAsync");

  getTime = ->
    if Date.now then +Date.now() else +new Date()

  processItems = (items, process, callback) ->
    itemsToProcess = Array.prototype.slice.call(items)
    i = null

    loopFn = ->
      start = getTime()
      process.call(context, itemsToProcess.shift(), (if i? then ++i else 0))
      while itemsToProcess.length > 0 and getTime() - start < runTime
        process.call(context, itemsToProcess.shift(), ++i)

      if itemsToProcess.length > 0
        Ember.run.later(context, loopFn, wait)

      else
        callback.call(context) if callback? and callback.call?

    Ember.run(context, loopFn)

  processItems objects, eachFn, completeFn
