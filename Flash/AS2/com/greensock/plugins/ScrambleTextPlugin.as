/**
 * VERSION: 12.0.5
 * DATE: 2013-03-27
 * AS2 
 * UPDATES AND DOCS AT: http://www.greensock.com
 **/
import com.greensock.TweenLite;
import com.greensock.plugins.core.CharSet;
import com.greensock.plugins.TweenPlugin;
/**
 * <p><strong>See AS3 files for full ASDocs</strong></p>
 * 
 * <p><strong>Copyright 2008-2013, GreenSock. All rights reserved.</strong> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for <a href="http://www.greensock.com/club/">Club GreenSock</a> members, the software agreement that was issued with the membership.</p>
 * 
 * @author Jack Doyle, jack@greensock.com
 */
class com.greensock.plugins.ScrambleTextPlugin extends TweenPlugin {
		public static var API:Number = 2; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		private static var _upper:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		private static var _lower:String = _upper.toLowerCase();
		private static var _charsLookup:Object;
		private var _tween:TweenLite;
		private var _target:Object;
		private var _delimiter:String;
		private var _original:Array;
		private var _text:Array;
		private var _length:Number;
		private var _lengthDif:Number;
		private var _charSet:Object;
		private var _speed:Number;
		private var _prevScrambleTime:Number;
		private var _setIndex:Number;
		private var _chars:String;
		private var _revealDelay:Number;
		private var _tweenLength:Boolean;
		
		public function ScrambleTextPlugin() {
			super("scrambleText");
			if (_charsLookup == null) {
				_charsLookup = {upperCase: new CharSet(_upper), lowerCase: new CharSet(_lower), upperAndLowerCase: new CharSet(_upper + _lower)};
				for (var p:String in _charsLookup) {
					_charsLookup[p.toLowerCase()] = _charsLookup[p];
					_charsLookup[p.toUpperCase()] = _charsLookup[p];
				}
			}
		}
		
		public function _onInitTween(target:Object, value:Object, tween:TweenLite):Boolean {
			if (target.text == null) {
				trace("scrambleText only works on objects with a 'text' property.");
				return false;
			}
			_target = target;
			if (typeof(value) !== "object") {
				value = {text:value};
			}
			var delim:String, i:Number, maxLength:Number, charset:CharSet;
			_delimiter = delim = value.delimiter || "";
			_original = target.text.split(delim);
			_text = (value.text || value.value || "").split(delim);
			
			i = _text.length - _original.length;
			_length = _original.join(delim).length;
			_lengthDif = _text.join(delim).length - _length;
			_charSet = charset = _charsLookup[(value.chars || "upperCase")] || new CharSet(value.chars);
			_speed = 0.016 / (value.speed || 1);
			_prevScrambleTime = 0;
			_setIndex = (Math.random() * 20) | 0;
			maxLength = _length + Math.max(_lengthDif, 0);
			if (maxLength > charset.length) {
				charset.grow(maxLength);
			}
			_chars = charset.sets[_setIndex];
			_revealDelay = value.revealDelay || 0;
			_tweenLength = (value.tweenLength !== false);
			_tween = tween;
			return true;
		}
		
		public function setRatio(ratio:Number):Void {
			var l:Number = _text.length,
				delim:String = _delimiter,
				time:Number = _tween._time,
				timeDif:Number = time - _prevScrambleTime,
				i:Number, newText:String, oldText:String;
			if (_revealDelay !== 0) {
				if (_tween.vars.runBackwards) {
					time = _tween._duration - time; //invert the time for from() tweens
				}
				ratio = (time === 0) ? 0 : (time < _revealDelay) ? 0.000001 : (time === _tween._duration) ? 1 : _tween._ease.getRatio((time - _revealDelay) / (_tween._duration - _revealDelay));
			}
			if (ratio < 0) {
				ratio = 0;
			} else if (ratio > 1) {
				ratio = 1;
			}
			i = (ratio * l + 0.5) | 0;
			newText = _text.slice(0, i).join(delim);
			oldText = _original.slice(i).join(delim);
			if (ratio) {
				if (timeDif > _speed || timeDif < -_speed) {
					_setIndex = (_setIndex + ((Math.random() * 19) | 0)) % 20;
					_chars = _charSet.sets[_setIndex];
					_prevScrambleTime += timeDif;
				}
				oldText = _chars.substr(newText.length, ((_length + (_tweenLength ? 1 - ((ratio = 1 - ratio) * ratio * ratio * ratio) : 1) * _lengthDif) - newText.length + 0.5) | 0);
			}
			_target.text = newText + delim + oldText;
		}
	
}