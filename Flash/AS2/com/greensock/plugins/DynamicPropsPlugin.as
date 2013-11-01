/**
 * VERSION: 12.0
 * DATE: 2012-02-14
 * AS2
 * UPDATES AND DOCS AT: http://www.greensock.com
 **/
import com.greensock.TweenLite;
import com.greensock.plugins.TweenPlugin;
/**
 * <p><strong>See AS3 files for full ASDocs</strong></p>
 * 
 * <p><strong>Copyright 2008-2013, GreenSock. All rights reserved.</strong> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for <a href="http://www.greensock.com/club/">Club GreenSock</a> members, the software agreement that was issued with the membership.</p>
 * 
 * @author Jack Doyle, jack@greensock.com
 */
class com.greensock.plugins.DynamicPropsPlugin extends TweenPlugin {
		public static var API:Number = 2; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		private var _tween:TweenLite;
		private var _target:Object;
		private var _props:Array;
		private var _prevFactor:Number;
		private var _prevTime:Number;
		
		public function DynamicPropsPlugin() {
			super("dynamicProps");
			_overwriteProps = [];
			_props = [];
		}
		
		public function _onInitTween(target:Object, value:Object, tween:TweenLite):Boolean {
			_target = target;
			_tween = tween;
			_prevFactor = _prevTime = 0;
			var params:Object = value.params || {}, isFunc:Boolean, getProp:String;
			for (var p:String in value) {
				if (p != "params") {
					isFunc = (typeof(_target[p]) == "function");
					getProp = (!isFunc || p.indexOf("set") || typeof(_target["get" + p.substr(3)]) !== "function") ? p : "get" + p.substr(3);
					_props[_props.length] = {s:( isFunc ? _target[getProp]() : Number(_target[getProp])), p:p, getProp:getProp, f:isFunc, getter:value[p], params:params[p], r:false};
					_overwriteProps[_overwriteProps.length] = p;
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
				if (lookup.dynamicProps || lookup[_props[i].p]) {
					_props[i].r = value;
				}
			}
		}
		
		public function setRatio(v:Number):Void {
			if (v != _prevFactor) {
				var i:Number = _props.length, pt:Object, cur:Number, end:Number, ratio:Number, val:Number;
				
				//going forwards towards the end
				if (_tween._time > _prevTime) {
					ratio = (v == 1 || _prevFactor == 1) ? 0 : 1 - ((v - _prevFactor) / (1 - _prevFactor));
					while (--i > -1) {
						pt = _props[i];
						end = (pt.params) ? pt.getter.apply(null, pt.params) : pt.getter();
						cur = (!pt.f) ? _target[pt.getProp] : _target[pt.getProp]();
						val = (!pt.r) ? end - ((end - cur) * ratio) : ((val = end - ((end - cur) * ratio)) > 0) ? (val + 0.5) >> 0 : (val - 0.5) >> 0; //about 4x faster than Math.round()
						if (pt.f) {
							_target[pt.p](val);
						} else {
							_target[pt.p] = val;
						}
					}
					
				//going backwards towards the start
				} else {
					ratio = (v == 0 || _prevFactor == 0) ? 0 : 1 - ((v - _prevFactor) / -_prevFactor);
					while (--i > -1) {
						pt = _props[i];
						cur = (!pt.f) ? _target[pt.getProp] : _target[pt.getProp]();
						val = (!pt.r) ? pt.s + ((cur - pt.s) * ratio) : ((val = pt.s + ((cur - pt.s) * ratio)) > 0) ? (val + 0.5) >> 0 : (val - 0.5) >> 0; //about 4x faster than Math.round()
						if (pt.f) {
							_target[pt.p](val);
						} else {
							_target[pt.p] = val;
						}
					}
				}
				
				_prevFactor = v;
			}
			_prevTime = _tween._time;
		}
}