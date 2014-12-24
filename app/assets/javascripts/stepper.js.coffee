((app) ->
  app.bstepper = (options = {}) ->

    defaults =
      el:   $('@stepper')
      step: 0.25
      min:  0
      max:  24

    settings = $.extend defaults, options

    bStepper  =  settings.el
    bsStep    =  settings.step
    bsMin     =  settings.min
    bsMax     =  settings.max
    bsPlus    =  bStepper.find '.plus'
    bsMinus   =  bStepper.find '.minus'
    bsInput   =  bStepper.find 'input'
    bsValue   =  null

    floatValue = parseFloat(bsInput.val())
    bsValue = floatValue unless isNaN(floatValue)

    controller =
      _currentvalue: bsValue

      makePlus: ->
        val = @getCurrentValue()
        unless (val + bsStep) > bsMax
          @setValue val + bsStep

      makeMinus: ->
        val = @getCurrentValue()
        unless (val - bsStep) < bsMin
          @setValue val - bsStep

      getCurrentValue: ->
        @_currentvalue

      updateCurrentValue: (e) ->
        val = parseFloat e.target.value
        unless val < bsMin
          @_currentvalue = val
          @setValue @_currentvalue
        else
          @setValue @_currentvalue

      setValue: (val) ->
        bsInput[0].value = val
        bsInput.attr 'value', val
        @_currentvalue = val

    bsPlus.on 'click', ->
      controller.makePlus()

    bsMinus.on 'click', ->
      controller.makeMinus()

    bsInput.on 'change', (e) ->
      controller.updateCurrentValue e

)(window.App ||= {})
