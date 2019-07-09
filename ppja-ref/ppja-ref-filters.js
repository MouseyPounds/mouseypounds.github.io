/* ppja-ref-filters.js
 * https://mouseypounds.github.io/ppja-ref/
 */

/*jslint indent: 4, maxerr: 50, passfail: false, browser: true, regexp: true, plusplus: true */

window.onload = function () {
	"use strict";

	var e = document.getElementsByClassName("filter_check");
	for(var i = 0; i < e.length; i++){
		e[i].onclick = function() {
			var filterName = (this.id);
			var row = document.getElementsByClassName(filterName);
			for(var j = 0; j < row.length; j++){
				if (this.checked) {
					row[j].style.display = "table-row";
				} else {
					row[j].style.display = "none";
				}
			}
		};
	}

	if (document.getElementById("growth_speed_options") !== null) {
		document.getElementById("growth_speed_options").onclick = function() {
			// Find out which option is now selected
			var e = document.getElementsByName('speed');
			var speed_value;
			for(var i = 0; i < e.length; i++){
				if(e[i].checked){
					speed_value = e[i].value;
					break;
				}
			}
			
			// Hide whatever was previously shown
			var old = document.getElementById("last_speed").value;
			e = document.getElementsByClassName("col_" + old);
			for(var i = 0; i < e.length; i++){
				e[i].style.display = "none";
			}
			
			// Now show the new choice and save it
			document.getElementById("last_speed").value = speed_value;
			e = document.getElementsByClassName("col_" + speed_value);
			for(var i = 0; i < e.length; i++){
				e[i].style.display = "table-cell";
			}
		};
	}
};