/* sr-scripts.js
 * https://mouseypounds.github.io/streamraiders/
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
	
	// We need to do two different kinds of filtering. First, the "filter_acct" and "filter_rare"
	//  radio button groups will be used to show/hide different table columns.
	function updateColumns(e) {
		var offset =  parseInt(document.querySelector('input[name="filter_acct"]:checked').value) + 
			parseInt(document.querySelector('input[name="filter_rare"]:checked').value);
		
		for (var i = 0; i < 8; i++) {
			var c = document.getElementsByClassName("cost_" + i);
			for(var j = 0; j < c.length; j++){
				if (i === offset || i === offset + 1) {
					c[j].style.display = "table-cell";
				} else {
					c[j].style.display = "none";
				}
			}
		}
		updateDescription();
	}
	
	// Additionally, the "level_start" and "level_end" select menus will be used to control which
	//  table rows are highlighted, and only the highlighted rows will be included when
	//  calculating the totals. We are using a more brute-force approach in this app than we did
	//  for the Stardew PPJA reference because we know this table is only going to have ~30 rows.
	function updateRows(e) {
		// Prepare some varables (total gold and total scrolls for each situation)
		var totals = [0, 0, 0, 0, 0, 0, 0, 0];
		var e_start = document.getElementById("level_start");
		var val_start = e_start.options[e_start.selectedIndex].value;
		var e_end = document.getElementById("level_end");
		var val_end = e_end.options[e_end.selectedIndex].value;
		// Special handling if the starting level is an "unlock" type
		document.getElementById("unlock_initial").className = "";
		document.getElementById("unlock_dupe").className = "";
		if (val_start === "unlock_initial" || val_start === "unlock_dupe") {
			var unlock_row = document.getElementById(val_start);
			unlock_row.className = "highlight";
			for (var n = 0; n < totals.length; n++) {
				var c = unlock_row.getElementsByClassName("cost_" + n);
				totals[n] += parseInt(c[0].innerHTML);
			}
			val_start = 1;
		}
		val_start = parseInt(val_start);
		if (val_end === "unlock_initial" || val_end === "unlock_dupe") {
			val_end = 0;
		} else {
			val_end = parseInt(val_end);
		}
		// Iterate over the entire table 
		for (var j = 1; j <= 29; j++) {
			var row = document.getElementById("level_" + j);
			if (j >= val_start && j < val_end) {
				row.className = "highlight";
				for (var n = 0; n < totals.length; n++) {
					var c = row.getElementsByClassName("cost_" + n);
					totals[n] += parseInt(c[0].innerHTML);
				}
			} else {
				row.className = "";
			}
		}
		
		for (var n = 0; n < totals.length; n++) {
			var ele = document.getElementById("total_" + n);
			ele.innerHTML = addCommas(totals[n]);
		}
		updateDescription();
	}
	
	// Update the summary statement for the total with a nice description. This is probably more
	//  trouble than it is worth.
	function updateDescription() {
		var msg_acct = parseInt(document.querySelector('input[name="filter_acct"]:checked').value) ? "Captain " : "Viewer ";
		var msg_rare = parseInt(document.querySelector('input[name="filter_rare"]:checked').value) ? "Legendary" : "Non-Legendary";
		var e_start = document.getElementById("level_start");
		var val_start = e_start.options[e_start.selectedIndex].value;
		var e_end = document.getElementById("level_end");
		var val_end = e_end.options[e_end.selectedIndex].value;
		
		console.log("Updating desc for {" + val_start + "} to {" + val_end + "}");
		
		var msg = "Selected level range does not make sense";
		if (val_start === "unlock_initial" || val_start === "unlock_dupe") {
			if (val_end !== "unlock_initial" && val_end !== "unlock_dupe") {
				var type = val_start === "unlock_initial" ? "initial" : "duplicate";
				msg = "Cost to unlock " + type + "<br />" + msg_acct + msg_rare + " unit<br />and upgrade it to level " + val_end;
			}
		} else if (val_end !== "unlock_initial" && val_end !== "unlock_dupe") {
			if (parseInt(val_end) > parseInt(val_start)) {
				msg = "Cost to upgrade<br />a " + msg_acct + msg_rare + " unit<br />from level " + val_start + " to level " + val_end;
			}
		}
		
		document.getElementById("result_desc").innerHTML = msg;
	}

	// Attach the change functions and trigger them both once to make sure everything is ready.
	var e = document.getElementsByClassName("filter");
	for(var i = 0; i < e.length; i++){
		e[i].onchange = function() { updateColumns(this) };
	}
	e = document.getElementsByClassName("level_select");
	for(var i = 0; i < e.length; i++){
		e[i].onchange = function() { updateRows(this) };
	}
	updateColumns();
	updateRows();
};