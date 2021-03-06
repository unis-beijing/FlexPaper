/* 
Copyright 2009 Erik Engström

This file is part of FlexPaper.

FlexPaper is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

FlexPaper is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with FlexPaper.  If not, see <http://www.gnu.org/licenses/>.	
*/

package com.devaldi.controls.flexpaper.utils
{
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.display.InteractiveObject;
	import flash.external.ExternalInterface;
	
	public class MacMouseWheelHandler
	{	
		static private var 	_init			: Boolean				= false;
		static private var 	_currItem		: InteractiveObject;
		static private var 	_clonedEvent	: MouseEvent;
		
		static public function 	init(stage:Stage):void
		{
			if(!_init)
			{
				_init = true;
				stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void
				{
					_currItem = InteractiveObject(e.target);
					_clonedEvent = MouseEvent(e);
				});
				
				// send in the callbacks
				if(ExternalInterface.available)
				{
					var id:String = 'eb_' + Math.floor(Math.random()*1000000);
					ExternalInterface.addCallback(id, function(){});
					ExternalInterface.call(c_jscode);
					ExternalInterface.call("eb.focusSwf", id);
					ExternalInterface.call("eb.InitMacMouseWheel", id);
					ExternalInterface.addCallback('externalMouseEvent', _externalMouseEvent);	
				}
			}
		}
		
		static private function _externalMouseEvent(delta:Number):void
		{
			if(_currItem && _clonedEvent)
				_currItem.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL, true, false, 
					_clonedEvent.localX, _clonedEvent.localY, _clonedEvent.relatedObject,
					_clonedEvent.ctrlKey, _clonedEvent.altKey, _clonedEvent.shiftKey, _clonedEvent.buttonDown,
					int(delta)));
		}
		
		static public const 	eb_mouseWheelEventHandler_jscode : XML =
			<script><![CDATA[
			function()
			{
			if(typeof eb == "undefined" || !eb)	window["eb"] = eb = {};
			eb.wheelHandlerEnabled = true;
			
				eb.enableMouseWheelHandler = function(enable){
					eb.wheelHandlerEnabled = enable;
				}
			}
			
			]]></script>;
		
		// javascript mouse handling code
		static private const 	c_jscode : XML =
			<script><![CDATA[
				function()
				{
					// create unique namespace
					if(typeof eb == "undefined" || !eb)	window["eb"] = eb = {};
					
					var userAgent = navigator.userAgent.toLowerCase();
					eb.platform = {
						win:/win/.test(userAgent),
						mac:/mac/.test(userAgent)
					};
					eb.browser = {
						version: (userAgent.match(/.+(?:rv|it|ra|ie)[\/: ]([\d.]+)/) || [])[1],
						safari: /webkit/.test(userAgent),
						opera: /opera/.test(userAgent),
						msie: /msie/.test(userAgent) && !/opera/.test(userAgent),
						mozilla: /mozilla/.test(userAgent) && !/(compatible|webkit)/.test(userAgent),
						chrome: /chrome/.test(userAgent)
					};
			
					eb.focusSwf = function(id){
						var swf = eb.findSwf(id);
						swf.focus();
					}
					
					// find the function we added
					eb.findSwf = function(id) {
						var objects = document.getElementsByTagName("object");
						for(var i = 0; i < objects.length; i++)
							if(typeof objects[i][id] != "undefined")
								return objects[i];
						
						var embeds = document.getElementsByTagName("embed");
						for(var j = 0; j < embeds.length; j++)
							if(typeof embeds[j][id] != "undefined")
								return embeds[j];
								
						return null;
					}
					
					eb.flashMouseMoveHandler = function(){
						if(eb.browser.mozilla || eb.browser.msie){
							eb.mouseOver = true;
						}
					}
			
					eb.InitMacMouseWheel = function(id) {
						var swf = eb.findSwf(id);
						
						if(swf && eb.platform.mac) {
							eb.mouseOver = false;
							
							/// Mouse move detection for mouse wheel support
							function _mousemove(event) {
								eb.mouseOver = event && event.target && (event.target == swf);
							}
		
							/// Mousewheel support
							var _mousewheel = function(event) {
								if(!eb.wheelHandlerEnabled){return true;}
			
								try{
									if(!swf.hasFocus()){return true;}
									swf.setViewerFocus(true);
									swf.focus();
									
									if(!swf.hasFocus()){return true;}
								}catch(err){return true;}
			
							 	if(eb.browser.chrome || eb.browser.safari){
									swf.externalMouseEvent(event.wheelDelta);
									if(event.preventDefault)	event.preventDefault();
									return true;
								}
			
								if(eb.mouseOver) {
									var delta = 0;
									if(event.wheelDelta)		delta = event.wheelDelta / (eb.browser.opera ? 12 : 120);
									else if(event.detail)		delta = -event.detail;
									if(event.preventDefault)	event.preventDefault();
									swf.externalMouseEvent(delta);
									if (event.stopPropagation) event.stopPropagation();    
									if (event.returnValue) event.returnValue = false;
									if (event.cancelBubble) event.cancelBubble = true;
			
									return true;
								}
								return false;
							}
		
							// install mouse listeners
							if(typeof window.addEventListener != 'undefined') {
								window.addEventListener('DOMMouseScroll', _mousewheel, false);
								window.addEventListener('DOMMouseMove', _mousemove, false);
							}
							window.onmousewheel = document.onmousewheel = _mousewheel;
							
							if(eb.browser.mozilla){
								window.onmousemove = document.onmousemove = _mousemove;
							}
			
							window.addEventListener("mousemove",_mousemove);
							document.addEventListener("mousemove",_mousemove);
			
						}else if(swf && !eb.platform.mac){
							eb.mouseOver = false;
							
							/// Mouse move detection for mouse wheel support
							function _mousemove(event) {
							eb.mouseOver = event && event.target && (event.target == swf);
							}
							
							var _handleWheel = function(event){
								try{
									if(!eb.wheelHandlerEnabled){return true;}
			
									if(!swf.hasFocus()){return true;}
										swf.setViewerFocus(true);
										swf.focus();
										
										if(!swf.hasFocus()){return true;}
								}catch(err){return true;}
			
								try{
									if(eb.browser.chrome || eb.browser.safari){
										swf.externalMouseEvent(event.wheelDelta);
										if(event.preventDefault)	event.preventDefault();
										return true;
									}
									
									if(eb.mouseOver) {
										var delta = 0;
										if(event.wheelDelta)		delta = event.wheelDelta / (eb.browser.opera ? 12 : 120);
										else if(event.detail)		delta = -event.detail;
										if(event.preventDefault)	event.preventDefault();
										if (delta > 0.0)
										delta += 1.0;
										swf.externalMouseEvent(delta);
										if (event.stopPropagation) event.stopPropagation();    
										if (event.returnValue) event.returnValue = false;
										if (event.cancelBubble) event.cancelBubble = true;
										return true;
									}
								}catch(err){return true;}
			
								return false;
							}
			
							if(window.addEventListener)
							window.addEventListener('DOMMouseScroll', _handleWheel, false);
							window.onmousewheel = document.onmousewheel = _handleWheel;

							if (window.attachEvent) 
								window.attachEvent("onmousewheel", _handleWheel);
						}
					}	
				}
			]]></script>;
	}
	
}