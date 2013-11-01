/**
 * VERSION: 12.0
 * DATE: 2012-01-12
 * AS2
 * UPDATES AND DOCS AT: http://www.greensock.com
 **/
import com.greensock.TweenLite;
import com.greensock.core.SimpleTimeline;
import com.greensock.plugins.TweenPlugin;
import com.greensock.easing.Ease;
/**
 * <p><strong>See AS3 files for full ASDocs</strong></p>
 * 
 * <p><strong>Copyright 2008-2013, GreenSock. All rights reserved.</strong> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for <a href="http://www.greensock.com/club/">Club GreenSock</a> members, the software agreement that was issued with the membership.</p>
 * 
 * @author Jack Doyle, jack@greensock.com
 */
class com.greensock.plugins.ThrowPropsPlugin extends TweenPlugin {
		public static var API:Number = 2; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		public static var defaultResistance:Number = 100;
		private var _target:Object;
		private var _props:Array;
		
		public function ThrowPropsPlugin() {
			super("throwProps");
			_overwriteProps = [];
		}
		
		static public function to(target:Object, vars:Object, maxDuration:Number, minDuration:Number, overshootTolerance:Number):TweenLite {
			if (vars.throwProps == undefined) {
				vars = {throwProps:vars};
			}
			return new TweenLite(target, calculateTweenDuration(target, vars, maxDuration, minDuration, overshootTolerance), vars);
		}
		
		public static function calculateChange(velocity:Number, ease:Object, duration:Number, checkpoint:Number):Number {
			if (checkpoint == null) {
				checkpoint = 0.05;
			}
			var e:Ease = (ease instanceof Ease) ? Ease(ease) : (ease == null) ? TweenLite.defaultEase : new Ease(Function(ease));
			return (duration * checkpoint * velocity) / e.getRatio(checkpoint);
		}
		
		public static function calculateDuration(start:Number, end:Number, velocity:Number, ease:Object, checkpoint:Number):Number {
			if (checkpoint == null) {
				checkpoint = 0.05;
			}
			var e:Ease = (ease instanceof Ease) ? ease : (ease == null) ? TweenLite.defaultEase : new Ease(Function(ease));
			return Math.abs( (end - start) * e.getRatio(checkpoint) / velocity / checkpoint );
		}
		
		public static function calculateTweenDuration(target:Object, vars:Object, maxDuration:Number, minDuration:Number, overshootTolerance:Number):Number {
			var duration:Number = 0;
			var clippedDuration:Number = 9999999999;
			var throwPropsVars:Object = (vars.throwProps != null) ? vars.throwProps : vars;
			var ease:Ease = (vars.ease instanceof Ease) ? vars.ease : (vars.ease == null) ? TweenLite.defaultEase : new Ease(vars.ease);
			var checkpoint:Number = isNaN(throwPropsVars.checkpoint) ? 0.05 : Number(throwPropsVars.checkpoint);
			var resistance:Number = isNaN(throwPropsVars.resistance) ? defaultResistance : Number(throwPropsVars.resistance);
			var curProp:Object, curDuration:Number, curVelocity:Number, curResistance:Number, curVal:Number, end:Number, curClippedDuration:Number;
			for (var p:String in throwPropsVars) {
				
				if (p != "resistance" && p != "checkpoint") {
					curProp = throwPropsVars[p];
					if (typeof(curProp) == "number") {
						curVelocity = Number(curProp);
						curDuration = (curVelocity * resistance > 0) ? curVelocity / resistance : curVelocity / -resistance;
						
					} else {
						curVelocity = Number(curProp.velocity) || 0;
						curResistance = isNaN(curProp.resistance) ? resistance : Number(curProp.resistance);
						curDuration = (curVelocity * curResistance > 0) ? curVelocity / curResistance : curVelocity / -curResistance;
						curVal = (typeof(target[p]) == "function") ? target[ ((p.indexOf("set") || typeof(target["get" + p.substr(3)]) !== "function") ? p : "get" + p.substr(3)) ]() : target[p];
						end = curVal + calculateChange(curVelocity, ease, curDuration, checkpoint);
						if (curProp.max != null && end > Number(curProp.max)) {
							//if the value is already exceeding the max or the velocity is too low, the duration can end up being uncomfortably long but in most situations, users want the snapping to occur relatively quickly (0.75 seconds), so we implement a cap here to make things more intuitive.
							curClippedDuration = (curVal > curProp.max || (curVelocity > -15 && curVelocity < 45)) ? 0.75 : calculateDuration(curVal, curProp.max, curVelocity, ease, checkpoint);
							if (curClippedDuration + overshootTolerance < clippedDuration) {
								clippedDuration = curClippedDuration + overshootTolerance;
							}
							
						} else if (curProp.min != null && end < Number(curProp.min)) {
							//if the value is already exceeding the min or if the velocity is too low, the duration can end up being uncomfortably long but in most situations, users want the snapping to occur relatively quickly (0.75 seconds), so we implement a cap here to make things more intuitive.
							curClippedDuration = (curVal < curProp.min || (curVelocity > -45 && curVelocity < 15)) ? 0.75 : calculateDuration(curVal, curProp.min, curVelocity, ease, checkpoint);
							if (curClippedDuration + overshootTolerance < clippedDuration) {
								clippedDuration = curClippedDuration + overshootTolerance;
							}
						}
						
						if (curClippedDuration > duration) {
							duration = curClippedDuration;
						}
					}
					
					if (curDuration > duration) {
						duration = curDuration;
					}
					
				}
			}
			if (duration > clippedDuration) {
				duration = clippedDuration;
			}
			if (duration > maxDuration) {
				return maxDuration;
			} else if (duration < minDuration) {
				return minDuration;
			}
			return duration;
		}
		
		public function _onInitTween(target:Object, value:Object, tween:TweenLite):Boolean {
			_target = target;
			_props = [];
			var ease:Ease = tween._ease;
			var checkpoint:Number = isNaN(value.checkpoint) ? 0.05 : Number(value.checkpoint);
			var p:String, curProp:Object, curVal:Number, isFunc:Boolean, velocity:Number, change1:Number, end:Number, change2:Number, duration:Number = tween._duration, cnt:Number = 0;
			for (p in value) {
				if (p != "resistance" && p != "checkpoint") {
					curProp = value[p];
					if (typeof(curProp) == "number") {
						velocity = Number(curProp);
					} else if (!isNaN(curProp.velocity)) {
						velocity = Number(curProp.velocity);
					} else {
						trace("ERROR: No velocity was defined in the throwProps tween of " + target + " property: " + p);
						velocity = 0;
					}
					change1 = calculateChange(velocity, ease, duration, checkpoint);
					change2 = 0;
					isFunc = (typeof(_target[p]) == "function");
					curVal = (isFunc) ? _target[ ((p.indexOf("set") || typeof(_target["get" + p.substr(3)]) !== "function") ? p : "get" + p.substr(3)) ]() : _target[p];
					if (typeof(curProp) != "number") {
						end = curVal + change1;
						if (curProp.max != undefined && Number(curProp.max) < end) {
							change2 = (curProp.max - curVal) - change1;
							
						} else if (curProp.min != undefined && Number(curProp.min) > end) {							
							change2 = (curProp.min - curVal) - change1;
						}
					}
					_props[cnt++] = {p:p, s:curVal, c1:change1, c2:change2, f:isFunc, r:false};
					_overwriteProps[cnt] = p;
				}
			}
			return true;
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
				if (lookup.throwProps || lookup[_props[i].p]) {
					_props[i].r = value;
				}
			}
		}
		
		public function setRatio(v:Number):Void {
			var i:Number = _props.length, cp:Object, val:Number;
			while (--i > -1) {
				cp = _props[i];
				val = cp.s + cp.c1 * v + cp.c2 * v * v;
				if (cp.r) {
					val = (val > 0) ? (val + 0.5) >> 0 : (val - 0.5) >> 0;
				}
				if (cp.f) {
					_target[cp.p](val);
				} else {
					_target[cp.p] = val;
				}
			}			
		}
	
}