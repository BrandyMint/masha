$ ->
  bStepper = $('@stepper')
  bsStep = bStepper.data('step') || 0.25
  bsMin = bStepper.data('minimum') || 0
  bsMax = bStepper.data('maximum') || 24
  bsPlus = bStepper.find('.plus')
  bsMinus = bStepper.find('.minus')
  bsInput = bStepper.find('input')
  bsPlus.click ->
    val = parseFloat(bsInput.attr('value')) || 0
    unless (val + bsStep) > bsMax
      bsInput.attr('value', val + bsStep)
  bsMinus.click ->
    val = parseFloat(bsInput.attr('value')) || 0
    unless (val - bsStep) < bsMin
      bsInput.attr('value', val - bsStep)
