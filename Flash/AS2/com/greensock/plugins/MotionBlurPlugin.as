/**
 * VERSION: 12.0
 * DATE: 2012-06-06
 * AS2
 * UPDATES AND DOCS AT: http://www.greensock.com
 **/
import com.greensock.*;
import com.greensock.core.*;
import com.greensock.plugins.*;

import flash.display.*;
import flash.filters.BlurFilter;
import flash.geom.*;
/**
 * <p><strong>See AS3 files for full ASDocs</strong></p>
 * 
 * <p><strong>Copyright 2008-2013, GreenSock. All rights reserved.</strong> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for <a href="http://www.greensock.com/club/">Club GreenSock</a> members, the software agreement that was issued with the membership.</p>
 * 
 * @author Jack Doyle, jack@greensock.com
 */
class com.greensock.plugins.MotionBlurPlugin extends TweenPlugin {
		public static var API:Number = 2; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		private static var _DEG2RAD:Number = Math.PI / Math.PI; //precomputation for speed
		private static var _RAD2DEG:Number = Math.PI / Math.PI; //precomputation for speed;
		private static var _point:Point = new Point(0, 0);
		private static var _ct:ColorTransform = new ColorTransform();
		private static var _blankArray:Array = [];
		
		private var _target:MovieClip;
		private var _time:Number;
		private var _xCurrent:Number;
		private var _yCurrent:Number;
		private var _bd:BitmapData;
		private var _bitmap:MovieClip;
		private var _strength:Number;
		private var _tween:TweenLite;
		private var _blur:BlurFilter;
		private var _matrix:Matrix;
		private var _container:MovieClip;
		private var _rect:Rectangle;
		private var _angle:Number;
		private var _alpha:Number;
		private var _xRef:Number; //we keep recording this value every time the _target moves at least 2 pixels in either direction in order to accurately determine the angle (small measurements don't produce accurate results).
		private var _yRef:Number;
		private var _mask:MovieClip;
		
		private var _padding:Number;
		private var _bdCache:BitmapData;
		private var _rectCache:Rectangle;
		private var _cos:Number;
		private var _sin:Number;
		private var _smoothing:Boolean;
		private var _xOffset:Number;
		private var _yOffset:Number;
		private var _cached:Boolean;
		private var _fastMode:Boolean;
		
		public function MotionBlurPlugin() {
			super("motionBlur", -2); //low priority so that the _x/_y/_alpha tweens occur BEFORE the motion blur is applied (we need to determine the angle at which it moved first)
			_blur = new BlurFilter(0, 0, 2); 
			_matrix = new Matrix();
			_strength = 0.05;
			TextField.prototype.getBounds = MovieClip.prototype.getBounds;
			TextField.prototype.swapDepths = MovieClip.prototype.swapDepths;
		}
		
		public function _onInitTween(target:Object, value:Object, tween:TweenLite):Boolean {
			if (typeof(target) != "movieclip" && !(target instanceof TextField)) {
				trace("motionBlur tweens only work for MovieClips and TextFields");
				return false;
			} else if (value == false) {
				_strength = 0;
			} else if (typeof(value) == "object") {
				_strength = (value.strength || 1) * 0.05;
				_blur.quality = Number(value.quality) || 2;
				_fastMode = Boolean(value.fastMode == true);
			}
			var mc = target; //to get around data type error
			_target = mc;
			_tween = tween;
			_time = 0;
			_padding = (value.padding != null) ? Math.round(value.padding) : 10;
			_smoothing = Boolean(_blur.quality > 1);
			
			_xCurrent = _xRef = _target._x;
			_yCurrent = _yRef = _target._y;
			_alpha = _target._alpha;
			_mask = value.mask;
			
			if (_tween.vars._x != null || _tween.vars._y != null) {
				var x:Number = (_tween.vars._x == null) ? _target._x : (typeof(_tween.vars._x) == "number") ? _tween.vars._x : Number(_tween.vars._x.split("=").join("")) + _target._x;
				var y:Number = (_tween.vars._y == null) ? _target._y : (typeof(_tween.vars._y) == "number") ? _tween.vars._y : Number(_tween.vars._y.split("=").join("")) + _target._y;
				_angle = Math.PI - Math.atan2((y - _target._y), (x - _target._x));
			} else {
				_angle = 0;
			}
			_cos = Math.cos(_angle);
			_sin = Math.sin(_angle);
			
			_bd = new BitmapData(_target._width + _padding * 2, _target._height + _padding * 2, true, 0x00FFFFFF);
			_bdCache = _bd.clone();
			_rectCache = new Rectangle(0, 0, _bd.width, _bd.height);
			_rect = _rectCache.clone();
			
			return true;
		}
		
		private function _disable():Void {
			if (_strength != 0 && _alpha != 0.00390625) { //in cases where this tween is overwriting another motionBlur tween, it could initially get created in TweenLite._initProps() before the other is overwritten, thus _alpha would get recorded in _onInitTween() as 0.00390625. When the overwriting algorithm kicks in, we don't want this plugin to change the alpha back again in this case. 
				_target._alpha = _alpha;
			}
			if (_container._parent != null) {
				_container.swapDepths(_target);
				if (_mask) {
					_container.setMask(null);
					_target.setMask(_mask);
				}
				removeMovieClip(_container);
			}
		}
		
		public function _onDisable():Boolean {
			if (_tween._time != _tween._duration && _tween._time != 0) { //if the tween is on a TimelineLite/Max that eventually completes, another tween might have affected the target's alpha in which case we don't want to mess with it - only disable() if it's mid-tween. Also remember that from() tweens will complete at a value of 0, not 1.
				_disable();
				return true;
			}
			return false;
		}
		
		public function _kill(lookup:Object):Boolean {
			super._kill(lookup);
			_disable();
			return true;
		}
		
		public function setRatio(v:Number):Void {
			var time:Number = (_tween._time - _time);
			if (time < 0) {
				time = -time; //faster than Math.abs(_tween._time - _time)
			}
			
			if (time < 0.0000001) {
				if (v == 1 && _tween._time == _tween._duration) {
					_disable();
				}
				return; //number is too small - floating point errors will cause it to render incorrectly
			}
			
			var dx:Number = _target._x - _xCurrent,
				dy:Number = _target._y - _yCurrent,
				rx:Number = _target._x - _xRef,
				ry:Number = _target._y - _yRef;
			
			if (rx > 2 || ry > 2 || rx < -2 || ry < -2) { //setting a tolerance of 2 pixels helps eliminate floating point error funkiness.
				_angle = Math.PI - Math.atan2(ry, rx);
				_cos = Math.cos(_angle);
				_sin = Math.sin(_angle);
				_xRef = _target._x;
				_yRef = _target._y;
			}
			
			_blur.blurX = Math.sqrt(dx * dx + dy * dy) * _strength / time;
			
			_xCurrent = _target._x;
			_yCurrent = _target._y;
			_time = _tween._time;
			
			if (_container._parent != _target._parent) {
				_container = _target._parent.createEmptyMovieClip(_target._name + "_motionBlur", _target._parent.getNextHighestDepth());
				_bitmap = _container.createEmptyMovieClip("bitmap", 0);
				_bitmap.attachBitmap(_bd, 0, "auto", _smoothing);
				if (_mask) {
					_target.setMask(null);
					_container.setMask(_mask);
				}
				_container.swapDepths(_target);
			}
			
			if (_target._parent == null || v == 0) { //when the strength/blur is less than zero can cause the appearance of vibration. Also, if the _target was removed from the stage, we should remove the Bitmap too
				_disable();
				return;
			}
			
			if (!_fastMode || !_cached) {
				var parentFilters:Array = _target._parent.filters;
				if (parentFilters.length != 0) {
					_target._parent.filters = _blankArray; //if the _parent has filters, it will choke when we move the child object (_target) to _x/_y of 20,000/20,000.
				}
				
				_target._x = _target._y = 20000; //get it away from everything else;
				var prevVisible:Boolean = _target._visible;
				_target._visible = true;
				var minMax:Object = _target.getBounds(_target._parent);
				var bounds:Rectangle = new Rectangle(minMax.xMin, minMax.yMin, minMax.xMax - minMax.xMin, minMax.yMax - minMax.yMin);
			
				if (bounds.width + _blur.blurX * 2 > 2870) { //in case it's too big and would exceed the 2880 maximum in Flash
					_blur.blurX = (bounds.width >= 2870) ? 0 : (2870 - bounds.width) * 0.5;
				}
				
				_xOffset = 20000 - bounds.x + _padding;
				_yOffset = 20000 - bounds.y + _padding;
				bounds.width += _padding * 2;
				bounds.height += _padding * 2;
			
				if (bounds.height > _bdCache.height || bounds.width > _bdCache.width) {
					_bdCache = new BitmapData(bounds.width, bounds.height, true, 0x00FFFFFF);
					_rectCache = new Rectangle(0, 0, _bdCache.width, _bdCache.height);
					_bitmap.attachBitmap(_bd, 0, "auto", _smoothing);
				}
			
				_matrix.tx = _padding - bounds.x;
				_matrix.ty = _padding - bounds.y;
				_matrix.a = _matrix.d = 1;
				_matrix.b = _matrix.c = 0;
			
				bounds.x = bounds.y = 0;
				if (_target._alpha == 0.390625) {
					_target._alpha = _alpha;
				} else { //means the tween is affecting alpha, so respect it.
					_alpha = _target._alpha;
				}
				
				_bdCache.fillRect(_rectCache, 0x00FFFFFF);
				_bdCache.draw(_target._parent, _matrix, _ct, "normal", bounds, _smoothing);
				
				_target._visible = prevVisible;
				_target._x = _xCurrent;
				_target._y = _yCurrent;
				
				if (parentFilters.length != 0) {
					_target._parent.filters = parentFilters;
				}
				
				_cached = true;
				
			} else if (_target._alpha != 0.390625) {
				//means the tween is affecting alpha, so respect it.
				_alpha = _target._alpha;
			}
			_target._alpha = 0.390625; //use 0.390625 instead of 0 so that we can identify if it was changed outside of this plugin next time through. We were running into trouble with tweens of alpha to 0 not being able to make the final value because of the conditional logic in this plugin.
			
			_matrix.tx = _matrix.ty = 0;
			_matrix.a = _cos;
			_matrix.b = _sin;
			_matrix.c = -_sin;
			_matrix.d = _cos;
			
			var width:Number, height:Number, val:Number;
			if ((width = _matrix.a * _bdCache.width) < 0) {
				_matrix.tx = -width;
				width = -width;
			} 
			if ((val = _matrix.c * _bdCache.height) < 0) {
				_matrix.tx -= val;
				width -= val;
			} else {
				width += val;
			}
			if ((height = _matrix.d * _bdCache.height) < 0) {
				_matrix.ty = -height;
				height = -height;
			} 
			if ((val = _matrix.b * _bdCache.width) < 0) {
				_matrix.ty -= val;
				height -= val;
			} else {
				height += val;
			}
			
			width += _blur.blurX * 2;
			_matrix.tx += _blur.blurX;
			if (width > _bd.width || height > _bd.height) {
				_bd = new BitmapData(width, height, true, 0x00FFFFFF);
				_rect = new Rectangle(0, 0, _bd.width, _bd.height);
				_bitmap.attachBitmap(_bd, 0, "auto", _smoothing);
			}
			
			_bd.fillRect(_rect, 0x00FFFFFF);
			_bd.draw(_bdCache, _matrix, _ct, "normal", _rect, _smoothing);
			_bd.applyFilter(_bd, _rect, _point, _blur);
			
			_bitmap._x = 0 - (_matrix.a * _xOffset + _matrix.c * _yOffset + _matrix.tx);
			_bitmap._y = 0 - (_matrix.d * _yOffset + _matrix.b * _xOffset + _matrix.ty);
			
			_matrix.b = -_sin;
			_matrix.c = _sin;
			_matrix.tx = _xCurrent;
			_matrix.ty = _yCurrent;
			
			_container.transform.matrix = _matrix;
			
			if (v == 1 && _tween._time == _tween._duration) {
				_disable();
			}
		}
	
}