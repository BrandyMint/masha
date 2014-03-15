# require jquery.freetile
# require jquery_ujs
# require jquery-ui
# require jquery.ui.datepicker-ru
# require select2
# require jquery_nested_form
#
# sass-ный jquery
# require jquery.ui.all

#= require jquery
#= require jquery_ujs
#= require jquery.role
#= require bootstrap
#= require jquery-autosize/jquery.autosize
#= require stepper
#= require purl/purl
#= require wiselinks

$ ->
  window.wiselinks = new Wiselinks()
  $(document).on 'click', 'a:not([role]):not([data-target])', (e) ->
    anchor = e.currentTarget
    if document.location.host == anchor.host
      e.preventDefault()
      wiselinks.load(anchor.href)
      false

  (jsHandlers = ->
    window.App.bstepper()
    $('@tooltip').tooltip()
    $('@autosize').autosize()

    $("#session_form_email").data "holder", $("#session_form_email").attr("placeholder")
    $("#session_form_email").focusin -> $(@).attr "placeholder", ""
    $("#session_form_email").focusout -> $(@).attr "placeholder", $(@).data("holder")

    window.App.mobileBehaviour()
  )()

  $(document).off('page:done').on 'page:done', jsHandlers

  # $('@freetile').freetile()
  # $('@ui-date-picker').datepicker()
  # $('@ui-datetime-picker').datetimepicker()
  # $('@select2').select2()
  # $('@select2').select2
  #  width: 'element'

  $("#sticky-table-header").affix offset:
    top: 288

  $(document).on 'click', '@date-shortcut', (e) ->
    $('#time_shift_date').val $(@).data('value')
    $(@).trigger 'change'
    e.preventDefault()

  $(document).on 'click', '@period-shortcut', (e) ->
    $('#time_sheet_form_date_from').val $(@).data('date-from')
    $('#time_sheet_form_date_to').val $(@).data('date-to')
    $(@).trigger 'change'
    e.preventDefault()

  $(document).on 'click', "@j-password-toggle", ->
    icon = $(@).find("[class*='icon']")
    icon.toggleClass('icon-eye-open')
    icon.toggleClass('icon-eye-close')
    input = $(@).closest('form').find('.j-password-input')
    type = input.attr("type")
    if type is "text"
      input.attr "type", "password"
    else
      input.attr "type", "text"

  $(document).on 'change', "@submit_on_change", ->
    $(@).parents('form').submit()

  $(document).on 'change', "@membership_role_selector", (e)->
    membership_role = $(e.target).val()
    link = $ $(e.target).data('target-id')

    url = link.url()

    param = url.param()
    param.invite.role = membership_role

    link.attr 'href', url.attr('path')+'?'+$.param(param)

  return

((app) ->
  app.reset_btn_hide = ($form, $btn) ->
    $btn.hide()
    $form.data 'serialize', $form.serialize()
    $form.on 'reset', -> $btn.hide()
    $form.on 'change input changeDate', ->
      if $form.data('serialize') != $form.serialize()
        $btn.show()
      else
        $btn.hide()
)(window.App ||= {})


((app) ->
  isMobile = ->
    return (document.width < 640)

  focusInput = $('input[autofocus]')

  app.mobileBehaviour = ->
    if isMobile()
      focusInput.blur()
      window.scrollTo(0)

)(window.App ||= {})
