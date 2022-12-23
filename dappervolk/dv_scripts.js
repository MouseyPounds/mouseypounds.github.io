/* dv-scripts.js
 * https://mouseypounds.github.io/dappervolk/
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

	// If 2 args, interpreted as (min, max) with range [min, max)
	// If 1 arg, interpreted as (max) with range [0, max)
	function randInt(a, b) {
		var min, max;
		if (b === undefined) {
			min = 0;
			max = a;
		} else {
			min = a;
			max = b;
		}
		return Math.floor(min + Math.random()*(max - min));
	}

	function generateListFromWardrobe() {
		var howMany = document.getElementById("item_count").value;
		// So here's our scuffed way to pull the item information from wardrobe source into something we can use.
		// First we regexp match all the var = X assignments on the page and then we feed the ones we need into
		// an anonymous function that basically just parses that whole line and returns a copy of the var.
		var source = $('#wardrobe_source').val();
		const re_vars = /\svar [^\r\n]*;/g;
		const re_whichvar = /^.var (\w+)\s?=/;
		var vmatch = source.match(re_vars);
		var wvar = {};
		for (var m of vmatch) {
			var mm = m.match(re_whichvar);
			if (mm) {
				var v = `${mm[1]}`;
				if (v === "categories" || v === "flattenItems" || v === "avatar") {
					wvar[v] = Function(m + "return " + v)();
				}
			}
		}
		// Grabbing userid strictly for personalized text
		var wh = wvar["avatar"]["user"]["select_name"];
		if (typeof(wh) === 'undefined') {
			wh = "your Worldhopper";
		}
		var pickFrom = Object.keys(wvar["flattenItems"]);
		var output = "<p>Picking " + howMany + " random items out of a pool of " + pickFrom.length +
			" from the wardrobe contents of " + wh + ":</p>";
		// For this method, we already have all the item info in wvar["flattenItems"] so pickFrom simply stores
		// a list of possible item IDs. Variable theItems is again used to avoid duplicates but we are also trying to
		// honour DV wardrobe slot limits by keeping track of things in usedSlots.
		var theItems = [];
		var usedSlots = {};
		var thumbnails = [];
		if (howMany <= pickFrom.length) {
			output += "<ol>";
			for (var i = 0; i < howMany; i++) {
				var index = -1;
				while (index === -1 || theItems.includes(index)) {
					index = randInt(pickFrom.length);
					var slot = wvar["flattenItems"][pickFrom[index]]["clothing_settings"]["slot_id"];
					if (!(slot in usedSlots)) {
						usedSlots[slot] = 0;
					}
					if (usedSlots[slot] < wvar["categories"][slot-1]["max_slots"]) {
						usedSlots[slot]++;
					} else {
						// Slot too full, pick again
						index = -1;
					}
				}
				theItems.push(index);
				//output += "<li>" + wvar["flattenItems"][pickFrom[index]]["name"] + "</li>";
				output += '<li><img class="thumb" src="' + wvar["flattenItems"][pickFrom[index]]["thumbnail_url"] + '"> '+ wvar["flattenItems"][pickFrom[index]]["name"] + " (" + wvar["categories"][slot-1]["name"] + ")</li>";
			}
			output += "</ol>";
		} else {
			output += '<p class="note">Cannot generate item list because pool is too small</p>';
		}
		setCookies();
		document.getElementById("output-container").innerHTML = output;
	}
	
	function setCookies() {
		$('input:checkbox').each(function() {
			var n = $(this).attr("name");
			Cookies.set(n, $(this).prop('checked'), { expires: 365, path: '' });
		});
		$('select').each(function() {
			var n = $(this).attr("name");
			Cookies.set(n, $(this).val(), { expires: 365, path: '' });
		});

	}

	function setCheckboxes(on) {
		$('input:checkbox').each(function() {
			$(this).prop('checked', on);
		});
	}

	$( document ).ready(function() {
		// Restore prefs from cookies
		$('input:checkbox').each(function() {
			var n = $(this).attr("name");
			var c = Cookies.get(n);
			if (typeof(c) !== 'undefined') {
				$(this).prop('checked', (c === "true"));
			}
		});
		$('select').each(function() {
			var n = $(this).attr("name");
			var c = Cookies.get(n);
			if (typeof(c) !== 'undefined') {
				$(this).val(c);
			}
		});

		document.getElementById("theWardrobeButton").addEventListener("click", function() { generateListFromWardrobe(); } );
	});

};