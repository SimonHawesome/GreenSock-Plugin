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
class com.greensock.plugins.PhysicsPropsPlugin extends TweenPlugin {
		public static var API:Number = 2; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		private var _tween:TweenLite;
		private var _target:Object;
		private var _props:Array;
		private var _hasFriction:Boolean;
		private var _runBackwards:Boolean;
		private var _step:Number; 
		private var _stepsPerTimeUnit:Number;
		
		public function PhysicsPropsPlugin() {
			super("physicsProps");
			_overwriteProps.pop();
		}
		
		public function _onInitTween(target:Object, value:Object, tween:TweenLite):Boolean {
			_target = target;
			_tween = tween;
			_runBackwards = (_tween.vars.runBackwards == true);
			_step = 0;
			var tl:SimpleTimeline = _tween.timeline,
				cnt:Number = 0,
				p:String, curProp:Object;
			while (tl.timeline) {
				tl = tl.timeline;
			}
			_stepsPerTimeUnit = (tl == Animation._rootFramesTimeline) ? 1 : 30;
			_props = [];
			for (p in value) {
				curProp = value[p];
				if (curProp.velocity || curProp.acceleration) {
					_props[cnt++] = _createProp(p, curProp.velocity, curProp.acceleration, curProp.friction);
					_overwriteProps[cnt] = p;
					if (curProp.friction) {
						_hasFriction = true;
					}
				}
			}
			return true;
		}
		
		private function _createProp(p:String, velocity:Number, acceleration:Number, friction:Number):Object {
			var obj:Object = {p:p, r:false, f:(typeof(_target[p]) == "function"), velocity:velocity || 0};
			obj.start = obj.value = (!obj.f) ? Number(_target[p]) : _target[ ((p.indexOf("set") || typeof(_target["get" + p.substr(3)]) !== "function") ? p : "get" + p.substr(3)) ]();
			obj.v = obj.velocity / _stepsPerTimeUnit;
			if (acceleration || acceleration == 0) {
				obj.acceleration = acceleration;
				obj.a = obj.acceleration / (_stepsPerTimeUnit * _stepsPerTimeUnit);
			} else {
				obj.acceleration = obj.a = 0;
			}
			obj.friction = (friction || friction == 0) ? 1 - friction : 1;
			return obj;
		}
		
		public function _kill(lookup:Object):Boolean {
			var i:Number = _props.length;
			while (--i > -1) {
				if (lookup[_props[i].p] != null) {
					_props.splice(i, 1);
				}
			}
			return super._kill(lookup);
		}
		
		public function _roundProps(lookup:Object, value:Boolean):Void {
			var i:Number = _props.length;
			while (--i > -1) {
				if (lookup.physicsProps || lookup[_props[i].p]) {
					_props[i].r = value;
				}
			}
		}
		
		public function setRatio(v:Number):Void {
			var i:Number = _props.length, 
				time:Number = _tween._time, 
				curProp:Object, val:Number, steps:Number, remainder:Number, j:Number, tt:Number;
			if (_runBackwards) {
				time = _tween._duration - time;
			}
			if (_hasFriction) {
				time *= _stepsPerTimeUnit;
				steps = (time | 0) - _step;
				remainder = time % 1;
				if (steps >= 0) { 	//going forward
					while (--i > -1) {
						curProp = _props[i];
						j = steps;
						while (--j > -1) {
							curProp.v += curProp.a;
							curProp.v *= curProp.friction;
							curProp.value += curProp.v;
						}
						val = curProp.value + (curProp.v * remainder);
						if (curProp.r) {
							val = (val + (val < 0 ? -0.5 : 0.5)) | 0;
						}
						if (curProp.f) {
							_target[curProp.p](val);
						} else {
							_target[curProp.p] = val;
						}
					}
					
				} else { 			//going backwards
					while (--i > -1) {
						curProp = _props[i];
						j = -steps;
						while (--j > -1) {
							curProp.value -= curProp.v;
							curProp.v /= curProp.friction;
							curProp.v -= curProp.a;
						}
						val = curProp.value + (curProp.v * remainder);
						if (curProp.r) {
							val = (val + (val < 0 ? -0.5 : 0.5)) | 0;
						}
						if (curProp.f) {
							_target[curProp.p](val);
						} else {
							_target[curProp.p] = val;
						}
					}
				}
				_step += steps;
				
			} else {
				tt = time * time * 0.5;
				while (--i > -1) {
					curProp = _props[i];
					val = curProp.start + ((curProp.velocity * time) + (curProp.acceleration * tt));
					if (curProp.r) {
						val = (val + (val < 0 ? -0.5 : 0.5)) | 0;
					}
					if (curProp.f) {
						_target[curProp.p](val);
					} else {
						_target[curProp.p] = val;
					}
				}
			}
		}
	
}