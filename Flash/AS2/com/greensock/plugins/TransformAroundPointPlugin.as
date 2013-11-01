/**
 * VERSION: 12.1
 * DATE: 2012-12-24
 * AS2
 * UPDATES AND DOCS AT: http://www.greensock.com
 **/
import com.greensock.TweenLite;
import com.greensock.plugins.TweenPlugin;
import com.greensock.plugins.ShortRotationPlugin;

import flash.geom.Point;
/**
 * <p><strong>See AS3 files for full ASDocs</strong></p>
 * 
 * <p><strong>Copyright 2008-2013, GreenSock. All rights reserved.</strong> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for <a href="http://www.greensock.com/club/">Club GreenSock</a> members, the software agreement that was issued with the membership.</p>
 * 
 * @author Jack Doyle, jack@greensock.com
 */
class com.greensock.plugins.TransformAroundPointPlugin extends TweenPlugin {
		public static var API:Number = 2; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		private static var _classInitted:Boolean;
		private var _target:Object;
		private var _local:Point;
		private var _point:Point;
		private var _temp:Point; //speeds things up when doing localToGlobal and globalToLocal.
		private var _shortRotation:ShortRotationPlugin;
		private var _xRound:Boolean;
		private var _yRound:Boolean;
		private var _pointIsLocal:Boolean;
		
		public function TransformAroundPointPlugin() {
			super("transformAroundPoint,_x,_y,transformAroundCenter", -1);// lower priority so that the x/y tweens occur BEFORE the transformAroundPoint is applied
			
			if (!_classInitted) { //so that the plugin can work with TextFields.
				TextField.prototype.getBounds = MovieClip.prototype.getBounds;
				TextField.prototype.localToGlobal = MovieClip.prototype.localToGlobal;
				TextField.prototype.globalToLocal = MovieClip.prototype.globalToLocal;
				_classInitted = true;
			}
			
		}
		
		public function _onInitTween(target:Object, value:Object, tween:TweenLite):Boolean {
			if (!(value.point instanceof Point)) {
				return false;
			}
			_target = target;
			
			if (value.pointIsLocal == true) {
				_pointIsLocal = true;
				_local = value.point.clone();
				_point = _local.clone();
				_target.localToGlobal(_point);
				_target._parent.globalToLocal(_point);
			} else {
				_point = value.point.clone();
				_local = _point.clone();
				_target._parent.localToGlobal(_local);
				_target.globalToLocal(_local);
			}
			
			_temp = _local.clone();
			
			var p:String, short:ShortRotationPlugin, sp:String, pp:String;
			for (p in value) {
				if (p == "point" || p == "pointIsLocal") {
					//ignore - we already set it above
				} else if (p == "shortRotation") {
					_shortRotation = new ShortRotationPlugin();
					_shortRotation._onInitTween(_target, value[p], tween);
					_addTween(_shortRotation, "setRatio", 0, 1, "shortRotation");
					for (sp in value[p]) {
						_overwriteProps[_overwriteProps.length] = sp;
					}
				} else if (p == "_x" || p == "_y") {
					pp = (p == "_x") ? "x" : "y"; //point property (x instead of _x and y instead of _y)
					_addTween(_point, pp, _point[pp], value[p], p);
				} else if (p == "scale") {
					_addTween(_target, "_xscale", _target._xscale, value.scale, "_xscale");
					_addTween(_target, "_yscale", _target._yscale, value.scale, "_yscale");
					_overwriteProps[_overwriteProps.length] = "_xscale";
					_overwriteProps[_overwriteProps.length] = "_yscale";
				} else {
					_addTween(_target, p, _target[p], value[p], p);
					_overwriteProps[_overwriteProps.length] = p;
				}
			}
			
			if (tween.vars._x != null || tween.vars._y != null) { //if the tween is supposed to affect _x and _y based on the original registration point, we need to make special adjustments here...
				var endX:Number, endY:Number;
				if (tween.vars._x != null) {
					endX = (typeof(tween.vars._x) == "number") ? tween.vars._x : _target._x + Number(tween.vars._x.split("=").join(""));
				}
				if (tween.vars._y != null) {
					endY = (typeof(tween.vars._y) == "number") ? tween.vars._y : _target._y + Number(tween.vars._y.split("=").join(""));
				}
				tween._kill({_x:true, _y:true, _tempKill:true}, _target); //we're taking over.
				this.setRatio(1);
				if (!isNaN(endX)) {
					_addTween(_point, "x", _point.x, _point.x + (endX - _target._x), "_x");
				}
				if (!isNaN(endY)) {
					_addTween(_point, "y", _point.y, _point.y + (endY - _target._y), "_y");
				}
				this.setRatio(0);
			}
			
			return true;
		}
		
		public function _kill(lookup:Object):Boolean {
			if (_shortRotation != null) {
				_shortRotation._kill(lookup);
				if (_shortRotation._overwriteProps.length == 0) {
					lookup.shortRotation = true;
				}
			}
			return super._kill(lookup);
		}
		
		public function _roundProps(lookup:Object, value:Boolean):Void {
			if (lookup.transformAroundPoint) {
				_xRound = _yRound = value;
			} else if (lookup._x) {
				_xRound = value;
			} else if (lookup._y) {
				_yRound = value;
			}
		}
		
		public function setRatio(v:Number):Void {
			_temp.x = _local.x;
			_temp.y = _local.y;
			if (_pointIsLocal && _target._parent) {
				_point.x = _local.x;
				_point.y = _local.y;
				_target.localToGlobal(_point);
				_target._parent.globalToLocal(_point);
			}
			super.setRatio(v);
			_target.localToGlobal(_temp);
			_target._parent.globalToLocal(_temp);
			var val:Number;
			if (_xRound) {
				_target._x = ((val = _target._x + _point.x - _temp.x) > 0) ? (val + 0.5) >> 0 : (val - 0.5) >> 0;
			} else {
				_target._x += _point.x - _temp.x;
			}
			if (_yRound) {
				_target._y = ((val = _target._y + _point.y - _temp.y) > 0) ? (val + 0.5) >> 0 : (val - 0.5) >> 0;
			} else {
				_target._y += _point.y - _temp.y;
			}
		}

}