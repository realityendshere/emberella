Emberella = window.Emberella

Emberella.throttle = (func, wait) ->
  context = null
  args = null
  timeout = null
  result = null
  previous = 0
  later = ->
    previous = new Date()
    timeout = null
    result = func.apply(context, args)

  return ->
    now = new Date()
    remaining = wait - (now - previous)
    context = this
    args = arguments
    if remaining <= 0
      clearTimeout(timeout)
      timeout = null
      previous = now
      result = func.apply(context, args)
    else
      timeout = setTimeout(later, remaining)
    result

Emberella.debounce = (func, wait, immediate) ->
  timeout = null
  result = null
  return ->
    context = this
    args = arguments
    later = ->
      timeout = null
      result = func.apply(context, args) unless immediate

    callNow = immediate && !timeout
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
    result = func.apply(context, args) if callNow
    result
