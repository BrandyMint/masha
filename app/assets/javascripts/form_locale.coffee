$ ->
  localeField = document.getElementById 'time_sheet_form_locale'
  if localeField?
    localeField.value = navigator.userLanguage || navigator.language

