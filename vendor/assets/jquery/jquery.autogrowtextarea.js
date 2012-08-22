/*!
 * Autogrow Textarea Plugin Version v2.0
 * http://www.technoreply.com/autogrow-textarea-plugin-version-2-0
 *
 * Copyright 2011, Jevin O. Sewaruth
 *
 * Date: March 13, 2011
 */
jQuery.fn.autoGrow = function(){
	return this.each(function(){
		// Variables
		var colsDefault = this.cols;
		var rowsDefault = this.rows;
		
		//Functions
		var grow = function() {
			growByRef(this);
		}
		
		var growByRef = function(obj) {
			var linesCount = 0;
			var lines = obj.value.split('\n');
			
			for (var i=lines.length-1; i>=0; --i)
			{
				linesCount += Math.floor((lines[i].length / colsDefault) + 1);
			}

			if (linesCount >= rowsDefault)
				obj.rows = linesCount + 1;
			else
				obj.rows = rowsDefault;
		}
		
		var characterWidth = function (obj){
			var characterWidth = 0;
			var temp1 = 0;
			var temp2 = 0;
			var tempCols = obj.cols;
			
			obj.cols = 1;
			temp1 = obj.offsetWidth;
			obj.cols = 2;
			temp2 = obj.offsetWidth;
			characterWidth = temp2 - temp1;
			obj.cols = tempCols;
			
			return characterWidth;
		}
		
		// Manipulations
		this.style.width = "auto";
		this.style.height = "auto";
		this.style.overflow = "hidden";
		this.style.width = ((characterWidth(this) * this.cols) + 6) + "px";
		this.onkeyup = grow;
		this.onfocus = grow;
		this.onblur = grow;
		growByRef(this);
	});
};
