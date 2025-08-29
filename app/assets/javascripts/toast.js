const onReady = function() {
  console.log("onReady emited");
  var option = { delay: 3000 }
  var toastElList = [].slice.call(document.querySelectorAll('.toast'))
  var toastList = toastElList.map(function (toastEl) {
    var toast = new bootstrap.Toast(toastEl, option)
    toast.show()
  })

  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })
}

document.addEventListener("turbo:load", onReady);

// Чтобы флешки показывались на 422 после POST-запроса
document.addEventListener("turbo:render", onReady);
