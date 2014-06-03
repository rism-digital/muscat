(function($) {

	$.fn.dirtyFields = function(parameters) {
	
		var opts = $.extend({}, $.fn.dirtyFields.defaults, parameters);
		
		return this.each(function() {
			var $container= $(this);
			
			$container.data("dF",opts);
			$container.data("dF").dirtyFieldsDataProperty= new Array;
			
			$("input[type='text'],input[type='file'],input[type='password'],textarea",$container).not("." + $container.data("dF").exclusionClass).each(function(i) {
				$.fn.dirtyFields.configureField($(this),$container,"text");
			});
			
			$("select",$container).not("." + $container.data("dF").exclusionClass).each(function(j) {
				$.fn.dirtyFields.configureField($(this),$container,"select");
			});	
			
			$(":checkbox,:radio",$container).not("." + $container.data("dF").exclusionClass).each(function(k) {
				$.fn.dirtyFields.configureField($(this),$container,"checkRadio");	
			});
			
			$.fn.dirtyFields.setStartingValues($container);
		
		});
		
	};  
	
	
	$.fn.dirtyFields.defaults = {
		   checkboxRadioContext: "next-span",
		   denoteDirtyOptions: false,
		   denoteDirtyFields: true,
		   denoteDirtyForm: false,
		   dirtyFieldClass: "dirtyField",
		   dirtyFieldsDataProperty:"dirtyFields",
		   dirtyFormClass: "dirtyForm",
		   dirtyOptionClass: "dirtyOption",
		   exclusionClass: "dirtyExclude", 
		   fieldChangeCallback: "",
		   fieldOverrides: {none:"none"},
		   formChangeCallback: "",
		   ignoreCaseClass: "dirtyIgnoreCase",
		   preFieldChangeCallback: "",
		   selectContext: "id-for",
		   startingValueDataProperty:"startingValue",
		   textboxContext: "id-for",
		   trimText: false
		  };
	
	
	$.fn.dirtyFields.configureField= function($object,$container,context,target) {
		if(!$object.hasClass($container.data("dF").exclusionClass)) {
			
			if (typeof target != "undefined") {
				$container.data("dF").fieldOverrides[$object.attr("id")]= target;
			}
			
			switch(context) {
				case "text":
					$object.change(function() {
						if ($.isFunction($container.data("dF").preFieldChangeCallback)) {
							if($container.data("dF").preFieldChangeCallback.call($object,$object.data($container.data("dF").startingValueDataProperty))== false)
							{
								return false;
							};
						}	
						evaluateTextElement($object,$container);	
					});	
				break;
				
				case "select":
					$object.change(function(){
						if ($.isFunction($container.data("dF").preFieldChangeCallback)) {
							if ($container.data("dF").preFieldChangeCallback.call($object, $object.data($container.data("dF").startingValueDataProperty)) == false) {
								return false;
							};
													}
						
						evaluateSelectElement($object, $container);
					});
				break;
				
				case "checkRadio":
					$object.change(function() {
						if ($.isFunction($container.data("dF").preFieldChangeCallback)) {
							if($container.data("dF").preFieldChangeCallback.call($object,$object.data($container.data("dF").startingValueDataProperty))== false)
							{
								return false;
							};
						}	
						evaluateCheckboxRadioElement($object,$container);	
					});	
				break;
			}	
			
		}
	};
	
	
	$.fn.dirtyFields.formSaved= function($container) {
		$.fn.dirtyFields.setStartingValues($container);
		$.fn.dirtyFields.markContainerFieldsClean($container);	
	};
	
	$.fn.dirtyFields.markContainerFieldsClean = function($container){
		var fieldArray= new Array();
		$container.data("dF").dirtyFieldsDataProperty= fieldArray;
		
		$("." + $container.data("dF").dirtyFieldClass,$container).removeClass($container.data("dF").dirtyFieldClass);
		if($container.data("dF").denoteDirtyOptions)
			{
				$("." + $container.data("dF").dirtyOptionClass,$container).removeClass($container.data("dF").dirtyOptionClass);
			}
		if($container.data("dF").denoteDirtyForm)
			{
				$container.removeClass($container.data("dF").dirtyFormClass);
			}
	};
	
	$.fn.dirtyFields.setStartingValues= function($container,opts) {
		$("input[type='text'],input[type='file'],input[type='password'],:checkbox,:radio,textarea",$container).not("." + $container.data("dF").exclusionClass).each(function(i) {
				var $object= $(this);
				if($object.attr("type")== "radio" || $object.attr("type")== "checkbox")
					{
						$.fn.dirtyFields.setStartingCheckboxRadioValue($object,$container);
					}
				else
					{
						$.fn.dirtyFields.setStartingTextValue($object,$container);
					}
		});
		
		$("select",$container).not("." + $container.data("dF").exclusionClass).each(function (j) {
			$.fn.dirtyFields.setStartingSelectValue($(this),$container);
		});
	};  
	
	
	$.fn.dirtyFields.setStartingTextValue = function($objects,$container){
		return $objects.not("." + $container.data("dF").exclusionClass).each(function() {
			var $object= $(this);
			$object.data($container.data("dF").startingValueDataProperty,$object.val());
		});
	};
	
	$.fn.dirtyFields.setStartingCheckboxRadioValue = function($objects,$container){
		return $objects.not("." + $container.data("dF").exclusionClass).each(function() {
			var $object= $(this);
			var isChecked;
			if($object.is(":checked"))
				{
					$object.data($container.data("dF").startingValueDataProperty,true);
				}
			else
				{
					$object.data($container.data("dF").startingValueDataProperty,false);
				}
		});
	};
	
	$.fn.dirtyFields.setStartingSelectValue = function($objects,$container){
		return $objects.not("." + $container.data("dF").exclusionClass).each(function() {
			var $object= $(this);
			if($container.data("dF").denoteDirtyOptions== false && $object.attr("multiple") != true)
				{
					$object.data($container.data("dF").startingValueDataProperty,$object.val());
				}
			else
				{
					var valArray= new Array;
					$object.children("option").each(function(o) {
							var $option= $(this);
							if($option.is(":selected"))							
								{
									$option.data($container.data("dF").startingValueDataProperty,true);
									valArray.push($option.val());
								}
							else
								{
									$option.data($container.data("dF").startingValueDataProperty,false);
								}
							
						});
					$object.data($container.data("dF").startingValueDataProperty,valArray);
				}
		});
	};
	
	
	$.fn.dirtyFields.rollbackTextValue = function($objects,$container, processChange){
		if(typeof processChange== "undefined") {processChange= true}
		return $objects.not("." + $container.data("dF").exclusionClass).each(function() {
			var $object= $(this);
			$object.val($object.data($container.data("dF").startingValueDataProperty));
			if(processChange)
				{
					evaluateTextElement($object,$container)
				}
		});
	};
	
	$.fn.dirtyFields.updateTextState = function($objects,$container){
		return $objects.not("." + $container.data("dF").exclusionClass).each(function() {
			evaluateTextElement($(this),$container)
		});
	};
	
	
	$.fn.dirtyFields.rollbackCheckboxRadioState= function($objects,$container,processChange) {
		if(typeof processChange== "undefined") {processChange= true}
		return $objects.not("." + $container.data("dF").exclusionClass).each(function() {
			var $object= $(this);
			if($object.data($container.data("dF").startingValueDataProperty))
				{
					$object.attr("checked",true);
				}
			else
				{
					$object.attr("checked",false);
				}
			
			if(processChange)
				{
					evaluateCheckboxRadioElement($object,$container);
				}
		});
	};
	
	$.fn.dirtyFields.updateCheckboxRadioState= function($objects,$container) {
		return $objects.not("." + $container.data("dF").exclusionClass).each(function() {
			evaluateCheckboxRadioElement($(this),$container);
		});
	};
	
	$.fn.dirtyFields.rollbackSelectState= function($objects,$container,processChange) {
		if(typeof processChange== "undefined") {processChange= true}
		return $objects.not("." + $container.data("dF").exclusionClass).each(function() {
			var $object= $(this);
			if($container.data("dF").denoteDirtyOptions== false && $object.attr("multiple") != true)
				{
					$object.val($object.data($container.data("dF").startingValueDataProperty));
				}
			else
				{
					$object.children("option").each(function(o) {
						var $option= $(this);
						if($option.data($container.data("dF").startingValueDataProperty))
							{
								$option.attr("selected",true);
							}
						else
							{
								$option.attr("selected",false);
							}		
					});
				}
				
			if(processChange) 
				{
					evaluateSelectElement($object,$container);
				}
		});
	};
	
	$.fn.dirtyFields.updateSelectState= function($objects,$container) {
		return $objects.not("." + $container.data("dF").exclusionClass).each(function() {
			evaluateSelectElement($(this),$container);
		});
	};
	
	
	$.fn.dirtyFields.rollbackForm= function($container) {
		$("input[type='text'],input[type='file'],input[type='password'],:checkbox,:radio,textarea",$container).not("." + $container.data("dF").exclusionClass).each(function(i) {
					$object= $(this);
					if($object.attr("type")== "radio" || $object.attr("type")== "checkbox")
						{
							$.fn.dirtyFields.rollbackCheckboxRadioState($object,$container,false);
						}
					else
						{
							$.fn.dirtyFields.rollbackTextValue($object,$container,false);
						}
			});
			
			$("select",$container).not("." + $container.data("dF").exclusionClass).each(function (j) {
				$.fn.dirtyFields.rollbackSelectState($(this),$container,false);
			});
			
			$.fn.dirtyFields.markContainerFieldsClean($container);
	};  
	
	$.fn.dirtyFields.updateFormState = function($container) {		
		$("input[type='text'],input[type='file'],input[type='password'],:checkbox,:radio,textarea",$container).not("." + $container.data("dF").exclusionClass).each(function(i) {
			$object= $(this);
			if ($object.attr("type") == "radio" || $object.attr("type") == "checkbox") 
				{
					$.fn.dirtyFields.updateCheckboxRadioState($object,$container);
				}
			else 
				{
					$.fn.dirtyFields.updateTextState($object,$container);
				}
			
		});
		
		$("select",$container).not("." + $container.data("dF").exclusionClass).each(function (j) {
			$object= $(this);
			$.fn.dirtyFields.updateSelectState($object,$container);
		});
	};
	
	
	$.fn.dirtyFields.getDirtyFieldNames = function($container) {		
		return 	$container.data("dF").dirtyFieldsDataProperty;
	};
	
	function updateDirtyFieldsArray(objectName,$container,status) {
		var dirtyFieldsArray= $container.data("dF").dirtyFieldsDataProperty;
		var index= $.inArray(objectName,dirtyFieldsArray);
		if(status== "dirty" && index== -1)
			{
				dirtyFieldsArray.push(objectName);
				$container.data("dF").dirtyFieldsDataProperty= dirtyFieldsArray;
			}
		else if(status== "clean" && index > -1)
			{
				dirtyFieldsArray.splice(index,1);
				$container.data("dF").dirtyFieldsDataProperty= dirtyFieldsArray;
			}
	};
	
	function updateFormStatus($container) {
		if($container.data("dF").dirtyFieldsDataProperty.length > 0) 
			{
				$container.addClass($container.data("dF").dirtyFormClass);
				if($.isFunction($container.data("dF").formChangeCallback))
					{
						$container.data("dF").formChangeCallback.call($container,true,$container.data("dF").dirtyFieldsDataProperty);
					}
			}
		else
			{
				$container.removeClass($container.data("dF").dirtyFormClass);
				if($.isFunction($container.data("dF").formChangeCallback))
					{
						$container.data("dF").formChangeCallback.call($container,false,$container.data("dF").dirtyFieldsDataProperty);
					}
			}
	};  

	function updateContext(context,$object,status,$container) {
		if ($container.data("dF").denoteDirtyFields) {
			var overrides = $container.data("dF").fieldOverrides;
			var elemId = $object.attr("id");
			var overridden = false;
			for (var overrideId in overrides) {
				if (elemId == overrideId) {
					if (status == "changed") {
						$("#" + overrides[overrideId]).addClass($container.data("dF").dirtyFieldClass);
					}
					else {
						$("#" + overrides[overrideId]).removeClass($container.data("dF").dirtyFieldClass);
					}
					overridden = true;
				}
			}
			if (overridden == false) {
				var updateSettings = $container.data("dF")[context];
				var updateSettingsArray = updateSettings.split("-");
				
				switch (updateSettingsArray[0]) {
					case "next":
						if (status == "changed") {
							$object.next(updateSettingsArray[1]).addClass($container.data("dF").dirtyFieldClass);
						}
						else {
							$object.next(updateSettingsArray[1]).removeClass($container.data("dF").dirtyFieldClass);
						}
						break;
						
					case "previous":
						if (status == "changed") {
							$object.prev(updateSettingsArray[1]).addClass($container.data("dF").dirtyFieldClass);
						}
						else {
							$object.prev(updateSettingsArray[1]).removeClass($container.data("dF").dirtyFieldClass);
						}
						break;
						
					case "closest":
						if (status == "changed") {
							$object.closest(updateSettingsArray[1]).addClass($container.data("dF").dirtyFieldClass);
						}
						else {
							$object.closest(updateSettingsArray[1]).removeClass($container.data("dF").dirtyFieldClass);
						}
						break;
						
					case "self":
						if (status == "changed") {
							$object.addClass($container.data("dF").dirtyFieldClass);
						}
						else {
							$object.removeClass($container.data("dF").dirtyFieldClass);
						}
						break;
						
					default:
						if (updateSettingsArray[0] == "id" || updateSettingsArray[0] == "name") {
							switch (updateSettingsArray[1]) {
								case "class":
									if (status == "changed") {
										$("." + $object.attr(updateSettingsArray[0]), $container).addClass($container.data("dF").dirtyFieldClass);
									}
									else {
										$("." + $object.attr(updateSettingsArray[0]), $container).removeClass($container.data("dF").dirtyFieldClass);
									}
									break;
									
								case "title":
									if (status == "changed") {
										$("*[title='" + $object.attr(updateSettingsArray[0]) + "']", $container).addClass($container.data("dF").dirtyFieldClass);
									}
									else {
										$("*[title='" + $object.attr(updateSettingsArray[0]) + "']", $container).removeClass($container.data("dF").dirtyFieldClass);
									}
									break;
									
								case "for":
									if (status == "changed") {
										$("label[for='" + $object.attr(updateSettingsArray[0]) + "']", $container).addClass($container.data("dF").dirtyFieldClass);
									}
									else {
										$("label[for='" + $object.attr(updateSettingsArray[0]) + "']", $container).removeClass($container.data("dF").dirtyFieldClass);
									}
									break;
							}
						}
						break;
						
						
				}
			}
		}
	};

	function evaluateTextElement($object,$container) {
		var objectName= $object.attr("name");
		var elemDirty= false;
		
		if($container.data("dF").trimText)
			{
				var elemValue= jQuery.trim($object.val());
			}
		else
			{
				var elemValue= $object.val();
			}
			
		if($object.hasClass($container.data("dF").ignoreCaseClass)) {
			var elemValue= elemValue.toUpperCase();
			var startingValue= $object.data($container.data("dF").startingValueDataProperty).toUpperCase();
		} else {
			var startingValue= $object.data($container.data("dF").startingValueDataProperty);
		}
			
		if (elemValue != startingValue)
			{
				updateContext("textboxContext",$object,"changed",$container);
				updateDirtyFieldsArray(objectName,$container,"dirty");
				elemDirty= true;
			}
		else 
			{
				updateContext("textboxContext",$object,"unchanged",$container);
				updateDirtyFieldsArray(objectName,$container,"clean");
			}
		
		if($.isFunction($container.data("dF").fieldChangeCallback))
			{
				$container.data("dF").fieldChangeCallback.call($object,$object.data($container.data("dF").startingValueDataProperty),elemDirty);
			}
		
		
		if($container.data("dF").denoteDirtyForm)
			{
				updateFormStatus($container);
			}
		
	} ;

	function evaluateSelectElement($object,$container) {
		var objectName= $object.attr("name");
		var elemDirty= false;
		
		if($container.data("dF").denoteDirtyOptions== false && $object.attr("multiple") != true)
			{
				if($object.hasClass($container.data("dF").ignoreCaseClass)) {
					var elemValue= $object.val().toUpperCase();
					var startingValue=  $object.data($container.data("dF").startingValueDataProperty).toUpperCase();
				} else {
					var elemValue= $object.val();
					var startingValue= $object.data($container.data("dF").startingValueDataProperty);
				}
			
				if (elemValue != startingValue)
					{
						updateContext("selectContext",$object,"changed",$container);
						updateDirtyFieldsArray(objectName,$container,"dirty");
						elemDirty= true;
					}
				else
					{
						updateContext("selectContext",$object,"unchanged",$container);
						updateDirtyFieldsArray(objectName,$container,"clean");
					}
			}
		else
			{
				var optionsDirty= false;
				$object.children("option").each(function(o) {
					var $option= $(this);
					var isSelected= $option.is(":selected");
					if(isSelected != $option.data($container.data("dF").startingValueDataProperty))
						{
							if ($container.data("dF").denoteDirtyOptions) {
								$option.addClass($container.data("dF").dirtyOptionClass);
							}
							optionsDirty= true;
						}
					else
						{
							if ($container.data("dF").denoteDirtyOptions) {
								$option.removeClass($container.data("dF").dirtyOptionClass);
							}	
						}
				});
				
				if(optionsDirty)
					{
						updateContext("selectContext",$object,"changed",$container);
						updateDirtyFieldsArray(objectName,$container,"dirty");
						elemDirty= true;
					}
				else
					{
						updateContext("selectContext",$object,"unchanged",$container);
						updateDirtyFieldsArray(objectName,$container,"clean");
					}
			}
			
		if($.isFunction($container.data("dF").fieldChangeCallback))
			{
				$container.data("dF").fieldChangeCallback.call($object,$object.data($container.data("dF").startingValueDataProperty),elemDirty);
			}
			
		if($container.data("dF").denoteDirtyForm)
			{
				updateFormStatus($container);
			}
			
	};
	
	function evaluateCheckboxRadioElement($object,$container) {
		var objectName= $object.attr("name");
		var elemDirty= false;
		var objectType= $object.attr("type");
		
		$(":" + objectType + "[name='" + objectName + "']",$container).each(function(r) {
			var $thisControl= $(this);
			var thisIsChecked= $thisControl.is(":checked");
			if(thisIsChecked != $thisControl.data($container.data("dF").startingValueDataProperty))
				{
					updateContext("checkboxRadioContext",$thisControl,"changed",$container);
					elemDirty= true;
				}
			else
				{
					updateContext("checkboxRadioContext",$thisControl,"unchanged",$container);
				}
			
		});
		
		if(elemDirty) 
			{
				updateDirtyFieldsArray(objectName,$container,"dirty");
			}
		else 
			{
				updateDirtyFieldsArray(objectName,$container,"clean");
			}
		
		if($.isFunction($container.data("dF").fieldChangeCallback))
			{
				$container.data("dF").fieldChangeCallback.call($object,$object.data($container.data("dF").startingValueDataProperty),elemDirty);
			}
		
		if($container.data("dF").denoteDirtyForm)
			{
				updateFormStatus($container);
			}
	};



})(jQuery);
