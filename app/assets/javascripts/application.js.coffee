#= require jquery
#= require jquery.role
#= require jquery_ujs
#= require bootstrap
#= require jquery.autosize-min.js
#= require_tree .

# require jquery.freetile
# require jquery_ujs
# require jquery-ui
# require jquery.ui.datepicker-ru
# require select2
# require jquery_nested_form
#
# sass-ный jquery
# require jquery.ui.all

$ ->
  $('@tooltip').tooltip()
  # $('@freetile').freetile()
  # $('@ui-date-picker').datepicker()
  # $('@ui-datetime-picker').datetimepicker()
  # $('@select2').select2()
  # $('@select2').select2
  #  width: 'element'

  $('@j-autosize').autosize()

  $('@date-shortcut').click (e) ->
    $('#time_shift_date').val $(@).data('value')
    e.preventDefault()

  $('@period-shortcut').click (e) ->
    $('#time_sheet_form_date_from').val $(@).data('date-from')
    $('#time_sheet_form_date_to').val $(@).data('date-to')
    e.preventDefault()

  $("@j-password-toggle").on "click", ->
    icon = $(this).find("[class*='icon']")
    icon.toggleClass('icon-eye-open')
    icon.toggleClass('icon-eye-close')
    input = $(this).closest('form').find('.j-password-input')
    type = input.attr("type")
    if type is "text"
      input.attr "type", "password"
    else
      input.attr "type", "text"

  return

$ ->
  $("#session_form_email").data "holder", $("#session_form_email").attr("placeholder")
  $("#session_form_email").focusin ->
    $(this).attr "placeholder", ""

  $("#session_form_email").focusout ->
    $(this).attr "placeholder", $(this).data("holder")

  $("@submit_on_change").on 'change', ->
    $(this).parents('form').submit()
