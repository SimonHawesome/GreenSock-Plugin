/**
 * VERSION: 12.0.5
 * DATE: 2013-03-27
 * AS2 
 * UPDATES AND DOCS AT: http://www.greensock.com
 **/
import com.greensock.TweenLite;
import com.greensock.core.Animation;
import com.greensock.core.SimpleTimeline;
import com.greensock.plugins.TweenPlugin;
/**
 * <p><strong>See AS3 files for full ASDocs</strong></p>
 * 
 * <p><strong>Copyright 2008-2013, GreenSock. All rights reserved.</strong> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for <a href="http://www.greensock.com/club/">Club GreenSock</a> members, the software agreement that was issued with the membership.</p>
 * 
 * @author Jack Doyle, jack@greensock.com
 */
class com.greensock.plugins.Physics2DPlugin extends TweenPlugin {
		public static var API:Number = 2; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		private static var _DEG2RAD:Number = Math.PI / 180;
		private var _tween:TweenLite;
		private var _target:MovieClip;
		private var _x:Object;
		private var _y:Object;
		private var _skipX:Boolean;
		private var _skipY:Boolean;
		private var _friction:Number;
		private var _runBackwards:Boolean;
		private var _step:Number; 
		private var _stepsPerTimeUnit:Number;
		
		public function Physics2DPlugin() {
			super("physics2D");
			_stepsPerTimeUnit = 30; //default
		}
		
		public function _onInitTween(target:Object, value:Object, tween:TweenLite):Boolean {
			if (!(target instanceof MovieClip)) {
				trace("physics2D requires that the target be a MovieClip.");
				return false;
			}
			_target = MovieClip(target);
			_tween = tween;
			_runBackwards = Boolean(_tween.vars.runBackwards == true);
			_step = 0;
			var tl:SimpleTimeline = _tween._timeline,
				angle:Number = Number(value.angle) || 0,
				velocity:Number = Number(value.velocity) || 0,
				acceleration:Number = Number(value.acceleration) || 0,
				xProp:String = value.xProp || "_x",
				yProp:String = value.yProp || "_y",
				aAngle:Number = (value.accelerationAngle || value.accelerationAngle == 0) ? Number(value.accelerationAngle) : angle;
			while (tl._timeline) {
				tl = tl._timeline;
			}
			if (tl == Animation._rootFramesTimeline) { //indicates the tween uses frames instead of seconds.
				_stepsPerTimeUnit = 1;
			}
			if (value.gravity) {
				acceleration = Number(value.gravity);
				aAngle = 90;
			}
			angle *= _DEG2RAD;
			aAngle *= _DEG2RAD;
			_overwriteProps.push(xProp);
			_overwriteProps.push(yProp);
			_friction = 1 - Number(value.friction || 0);
			_x = _createProp(_target, xProp, Math.cos(angle) * velocity, Math.cos(aAngle) * acceleration);
			_y = _createProp(_target, yProp, Math.sin(angle) * velocity, Math.sin(aAngle) * acceleration);
			return true;
		}
		
		/** @private **/
		private function _createProp(target, p:String, velocity:Number, acceleration:Number):Object {
			var obj:Object = {p:p, f:(typeof(target[p]) === "function"), r:false, velocity:velocity || 0};
			obj.start = obj.value = (!obj.f) ? parseFloat(target[p]) : target[ ((p.indexOf("set") || typeof(target["get" + p.substr(3)]) !== "function") ? p : "get" + p.substr(3)) ]();
			obj.v = obj.velocity / _stepsPerTimeUnit;
			if (acceleration || acceleration == 0) {
				obj.acceleration = acceleration;
				obj.a = obj.acceleration / (_stepsPerTimeUnit * _stepsPerTimeUnit);
			} else {
				obj.acceleration = obj.a = 0;
			}
			return obj;
		}
		
		public function _kill(lookup:Object):Boolean {
			if (lookup[_x.p] != null) {
				_skipX = true;
			}
			if (lookup[_y.p] != null) {
				_skipY = true;
			}
			return super._kill(lookup);
		}
		
		public function _roundProps(lookup:Object, value:Boolean):Void {
			if (lookup.physics2D || lookup[_x.p]) {
				_x.r = value;
			}
			if (lookup.physics2D || lookup[_y.p]) {
				_y.r = value;
			}
		}
		
		public function setRatio(v:Number):Void {
			var time:Number = _tween._time, 
				x:Number, y:Number, tt:Number, steps:Number, remainder:Number, i:Number;
			if (_runBackwards === true) {
				time = _tween._duration - time;
			}
			if (_friction === 1) {
				tt = time * time * 0.5;
				x = _x.start + ((_x.velocity * time) + (_x.acceleration * tt));
				y = _y.start + ((_y.velocity * time) + (_y.acceleration * tt));
			} else {
				time *= _stepsPerTimeUnit;
				steps = i = (time | 0) - _step;
				remainder = (time % 1);
				if (i >= 0) { 	//going forward
					while (--i > -1) {
						_x.v += _x.a;
						_y.v += _y.a;
						_x.v *= _friction;
						_y.v *= _friction;
						_x.value += _x.v;
						_y.value += _y.v;
					}	
					
				} else { 		//going backwards
					i = -i;
					while (--i > -1) {
						_x.value -= _x.v;
						_y.value -= _y.v;
						_x.v /= _friction;
						_y.v /= _friction;
						_x.v -= _x.a;
						_y.v -= _y.a;
					}
				}
				x = _x.value + (_x.v * remainder);
				y = _y.value + (_y.v * remainder);	
				_step += steps;
			}
			if (!_skipX) {
				if (_x.r) {
					x = (x + (x < 0 ? -0.5 : 0.5)) | 0;
				}
				if (_x.f) {
					_target[_x.p](x);
				} else {
					_target[_x.p] = x;
				}
			}
			if (!_skipY) {
				if (_y.r) {
					y = (y + (y < 0 ? -0.5 : 0.5)) | 0;
				}
				if (_y.f) {
					_target[_y.p](y);
				} else {
					_target[_y.p] = y;
				}
			}
			
		}
	
}