#= require jquery
#= require jquery_ujs
#= require jquery.turbolinks
#= require turbolinks
#= require bootstrap
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
  $('[rel*="tooltip"]').tooltip()
  # $('#freetile').freetile()
  # $('input.ui-date-picker').datepicker()
  # $('input.ui-datetime-picker').datetimepicker()
  # $('input.select2').select2()
  # $('select.select2').select2
  #  width: 'element'

  $('.date-shortcut').click (e) ->
    $('#time_shift_date').val $(@).data('value')
    e.preventDefault()

  $('.period-shortcut').click (e) ->
    $('#time_sheet_form_date_from').val $(@).data('date-from')
    $('#time_sheet_form_date_to').val $(@).data('date-to')
    e.preventDefault()

  return
