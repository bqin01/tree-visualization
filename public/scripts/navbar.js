function loadDropdown(element){
   const allButtons = document.querySelectorAll("#tree-settings button");
   allButtons.forEach(function(elem){
      unloadDropdown(elem);
   });
   const dropDown = document.getElementById(element.getAttribute('data-dropdown'));
   dropDown.style.visibility = 'visible';
}
function unloadDropdown(element){
  const dropDownID = element.getAttribute('data-dropdown');
  const dropDown = document.getElementById(dropDownID);
  dropDown.style.visibility = 'hidden';
}
