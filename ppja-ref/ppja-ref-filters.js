/* ppja-ref-filters.js
 * https://mouseypounds.github.io/ppja-ref/
 */

/*jslint indent: 4, maxerr: 50, passfail: false, browser: true, regexp: true, plusplus: true */

window.onload = function () {
	"use strict";

	// Utility functions
	function addCommas(x) {
		// Jamie Taylor @ https://stackoverflow.com/questions/3883342/add-commas-to-a-number-in-jquery
		return x.toString().replace(/\B(?=(?:\d{3})+(?!\d))/g, ",");
	}

	// Because we added commas to make the numbers look pretty, we want an easy way to strip them too
	// We will also convert this back to an integer since that is what we want when doing this.
	function removeCommas(x) {
		x = x.replace(/\,/g, '');
		return parseInt(x, 10);
	}
	
	var e = document.getElementsByClassName("filter_check");
	for(var i = 0; i < e.length; i++){
		e[i].onclick = function() {
			var filterName = (this.id);
			var row = document.getElementsByClassName(filterName);
			for(var j = 0; j < row.length; j++){
				var old_style = row[j].style.display;
				// We are filtering multiple types now, so we need to handle that properly
				var visible_style = "block";
				if (row[j].nodeName.toLowerCase() === "tr") {
					visible_style = "table-row";
				}
				row[j].style.display = (this.checked ? visible_style : "none");
				// All of the rest of this is to deal with auto-changing the count & total
				//  costs for the cooking page.
				var adjust = 0;
				if ((old_style == visible_style || old_style === "") && !this.checked) {
					// this row was just hidden so counts are going down
					adjust = -1;
				} else if (old_style === "none" && this.checked) {
					// this row was just unhidden so counts are going up
					adjust = 1;
				}
				if (adjust != 0) {
					// These are hardcoded right now because I am not sure how to use patterns
					var tables = ['food','drink']
					for(var t = 0; t < tables.length; t++) {
						var c = row[j].getElementsByClassName("total_" + tables[t]);
						for(var k = 0; k < c.length; k++) {
							
							var the_total = removeCommas(document.getElementById("foot_total_" + tables[t]).innerHTML);
							var temp = c[k].innerHTML;
							var change = (temp === "--" ? 0 : parseInt(temp));
							the_total += adjust*change;
							document.getElementById("foot_total_" + tables[t]).innerHTML = addCommas(the_total);
							var the_count = removeCommas(document.getElementById("foot_count_" + tables[t]).innerHTML);
							the_count += adjust;
							document.getElementById("foot_count_" + tables[t]).innerHTML = addCommas(the_count);
						}
					}
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