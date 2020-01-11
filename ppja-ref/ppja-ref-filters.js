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
			// Prepare some stuff for the cooking & crafting summary adjustments
			// This is understood to be food total, food count, drink total, drink count,
			//  object total, object count, craftable total, craftable count
			var adjustments = [0, 0, 0, 0, 0, 0, 0, 0];
			var row = document.getElementsByClassName(filterName);
			// And now we prepare for adjusting the actual ingredient table.
			var ingr_adjustments = {};
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
					var tables = ['food', 'drink', 'object', 'craftable'];
					for(var t = 0; t < tables.length; t++) {
						var c = row[j].getElementsByClassName("total_" + tables[t]);
						for(var k = 0; k < c.length; k++) {
							var temp = c[k].innerHTML;
							var change = (temp === "--" ? 0 : parseInt(temp));
							adjustments[2*t] += adjust*change;
							adjustments[2*t+1] += adjust;
						}
						// Stupid hack for adjusting count only on gift_tastes page
						c = document.getElementById("gift_footer");
						if (c !== null) {
							adjustments[2*t+1] += adjust;
						}
					}
					// There should only be 1 of these per row.
					var ingrs = row[j].getElementsByClassName("ingr");
					if (ingrs !== null && ingrs.length > 0) {
						var str = ingrs[0].getAttribute("data-ingr");
						var c = str.split("|");
						for(var k=0; k < c.length; k++) {
							var cc = c[k].split("/");
							if (!(cc[0] in ingr_adjustments)) {
								ingr_adjustments[cc[0]] = 0;
							}
							ingr_adjustments[cc[0]] += adjust*cc[1];
						}
					}
				}
			}
			var elements = ["foot_total_food", "foot_count_food", "foot_total_drink", "foot_count_drink",
							"foot_total_object", "foot_count_object", "foot_total_craftable", "foot_count_craftable"];
			for(var n = 0; n < elements.length; n++) {
				var ele = document.getElementById(elements[n]);
				if (ele !== null) {
					var old = removeCommas(ele.innerHTML);
					ele.innerHTML = addCommas(old + adjustments[n]);
				}
			}
			// Adjusting the ingredient list
			elements = document.getElementsByClassName("ingr_list");
			for(var n = 0; n < elements.length; n++) {
				var ingr_id = elements[n].getAttribute("data-ingr");
				if (ingr_id in ingr_adjustments) {
					var count = parseInt(elements[n].getElementsByClassName("value")[0].innerHTML);
					count += ingr_adjustments[ingr_id];
					elements[n].getElementsByClassName("value")[0].innerHTML = count;
					if (count === 0) {
						elements[n].style.display = "none";
					} else {
						elements[n].style.display = "table-row";
					}
				}
			}
		};
	}

	// Handling special buttons to bulk show/hide mod filters
	// baseGameCheckState will be used if it is supplied and the base_game filter is part of whichClass
	function checkAll(whichClass, checkState, baseGameCheckState) {
		var e = document.getElementsByClassName(whichClass);
		for(var j = 0; j < e.length; j++){
			if (e[j].type == 'checkbox') {
				if (e[j].id === 'filter_base_game' && (typeof baseGameCheckState !== 'undefined')) {
					e[j].checked = baseGameCheckState;
				} else {
					e[j].checked = checkState;
				}
				e[j].onclick();
			}
		}
	}		
	if (document.getElementById("filter_check_all_on") !== null) {
		document.getElementById("filter_check_all_on").onclick = function() {checkAll("filter_check", true);};
	}
	if (document.getElementById("filter_check_all_off") !== null) {
		document.getElementById("filter_check_all_off").onclick = function() {checkAll("filter_check", false);};
	}
	if (document.getElementById("filter_check_ppja") !== null) {
		document.getElementById("filter_check_ppja").onclick = function() {
			checkAll("filter_check", false); checkAll("filter_ppja", true); };
	}
	if (document.getElementById("filter_check_nonppja") !== null) {
		document.getElementById("filter_check_nonppja").onclick = function() {
			checkAll("filter_check", true, false); checkAll("filter_ppja", false);};
	}

	// The speed filters for crop summary
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