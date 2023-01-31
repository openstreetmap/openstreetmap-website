/* Polyfill service v3.111.0
 * For detailed credits and licence information see https://github.com/financial-times/polyfill-service.
 * 
 * Features requested: es6
 * 
 * - _ESAbstract.ArrayCreate, License: CC0 (required by "Symbol.unscopables", "Symbol", "Array.prototype.filter", "_ESAbstract.ArraySpeciesCreate", "es6")
 * - _ESAbstract.Call, License: CC0 (required by "String.prototype.startsWith", "_ESAbstract.ToString", "_ESAbstract.ToPrimitive", "_ESAbstract.OrdinaryToPrimitive", "es6")
 * - _ESAbstract.Get, License: CC0 (required by "String.prototype.startsWith", "_ESAbstract.ToString", "_ESAbstract.ToPrimitive", "_ESAbstract.OrdinaryToPrimitive", "es6")
 * - _ESAbstract.HasOwnProperty, License: CC0 (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyDescriptor", "es6")
 * - _ESAbstract.HasProperty, License: CC0 (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyNames", "Array.prototype.indexOf", "es6")
 * - _ESAbstract.IsArray, License: CC0 (required by "Symbol.unscopables", "Symbol", "Array.prototype.filter", "_ESAbstract.ArraySpeciesCreate", "es6")
 * - _ESAbstract.IsCallable, License: CC0 (required by "String.prototype.startsWith", "_ESAbstract.ToString", "_ESAbstract.ToPrimitive", "_ESAbstract.OrdinaryToPrimitive", "es6")
 * - _ESAbstract.RequireObjectCoercible, License: CC0 (required by "Number.parseInt", "String.prototype.trim", "_ESAbstract.TrimString", "es6")
 * - _ESAbstract.SameValueNonNumber, License: CC0 (required by "WeakMap", "_ESAbstract.SameValue", "es6")
 * - _ESAbstract.ToBoolean, License: CC0 (required by "Symbol.unscopables", "Symbol", "Array.prototype.filter", "es6")
 * - _ESAbstract.ToNumber, License: CC0 (required by "String.fromCodePoint", "es6")
 * - _ESAbstract.ToObject, License: CC0 (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyNames", "Array.prototype.indexOf", "es6")
 * - _ESAbstract.GetV, License: CC0 (required by "WeakSet", "_ESAbstract.GetIterator", "es6")
 * - _ESAbstract.GetMethod, License: CC0 (required by "String.prototype.startsWith", "_ESAbstract.ToString", "_ESAbstract.ToPrimitive", "es6")
 * - _ESAbstract.ToUint32, License: CC0 (required by "Math.imul", "es6")
 * - _ESAbstract.Type, License: CC0 (required by "String.prototype.startsWith", "_ESAbstract.ToString", "_ESAbstract.ToPrimitive", "_ESAbstract.OrdinaryToPrimitive", "es6")
 * - _ESAbstract.GetPrototypeFromConstructor, License: CC0 (required by "Array.of", "_ESAbstract.Construct", "_ESAbstract.OrdinaryCreateFromConstructor", "es6")
 * - _ESAbstract.IsConstructor, License: CC0 (required by "Symbol.unscopables", "Symbol", "Array.prototype.filter", "_ESAbstract.ArraySpeciesCreate", "es6")
 * - _ESAbstract.IsRegExp, License: CC0 (required by "String.prototype.startsWith", "es6")
 * - _ESAbstract.IteratorClose, License: CC0 (required by "WeakSet", "es6")
 * - _ESAbstract.IteratorComplete, License: CC0 (required by "WeakSet", "_ESAbstract.IteratorStep", "es6")
 * - _ESAbstract.IteratorNext, License: CC0 (required by "WeakSet", "_ESAbstract.IteratorStep", "es6")
 * - _ESAbstract.IteratorStep, License: CC0 (required by "WeakSet", "es6")
 * - _ESAbstract.IteratorValue, License: CC0 (required by "WeakSet", "es6")
 * - _ESAbstract.OrdinaryToPrimitive, License: CC0 (required by "String.prototype.startsWith", "_ESAbstract.ToString", "_ESAbstract.ToPrimitive", "es6")
 * - _ESAbstract.SameValue, License: CC0 (required by "WeakMap", "es6")
 * - _ESAbstract.SameValueZero, License: CC0 (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyNames", "Array.prototype.includes", "es6")
 * - _ESAbstract.ToInteger, License: CC0 (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyNames", "Array.prototype.indexOf", "es6")
 * - _ESAbstract.ToLength, License: CC0 (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyNames", "Array.prototype.indexOf", "es6")
 * - _ESAbstract.ToPrimitive, License: CC0 (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyDescriptor", "_ESAbstract.ToPropertyKey", "es6")
 * - _ESAbstract.ToString, License: CC0 (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyNames", "Array.prototype.indexOf", "es6")
 * - _ESAbstract.ToPropertyKey, License: CC0 (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyDescriptor", "es6")
 * - _ESAbstract.TrimString, License: CC0 (required by "Number.parseInt", "String.prototype.trim", "es6")
 * - _ESAbstract.UTF16Decode, License: CC0 (required by "String.prototype.codePointAt", "es6")
 * - _ESAbstract.UTF16Encoding, License: CC0 (required by "String.fromCodePoint", "es6")
 * - ArrayBuffer, License: MIT (required by "Math.fround", "es6")
 * - Object.defineProperty, License: CC0 (required by "String.prototype.@@iterator", "_StringIterator", "_Iterator", "Object.defineProperties", "es6")
 * - _ESAbstract.CreateDataProperty, License: CC0 (required by "Array.from", "Set", "_ESAbstract.CreateIterResultObject", "es6")
 * - _ESAbstract.CreateDataPropertyOrThrow, License: CC0 (required by "Symbol.unscopables", "Symbol", "Array.prototype.filter", "es6")
 * - _ESAbstract.CreateIterResultObject, License: CC0 (required by "Array.from", "Set", "es6")
 * - _ESAbstract.CreateMethodProperty, License: CC0 (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyNames", "Array.prototype.indexOf", "es6")
 * - Array.isArray, License: CC0 (required by "WeakMap", "es6")
 * - Array.prototype.copyWithin, License: MIT (required by "es6")
 * - Array.prototype.fill, License: CC0 (required by "es6")
 * - Array.prototype.find, License: CC0 (required by "es6")
 * - Array.prototype.findIndex, License: CC0 (required by "es6")
 * - Array.prototype.forEach, License: CC0 (required by "Symbol.unscopables", "Symbol", "es6")
 * - Array.prototype.includes, License: MIT (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyNames", "es6")
 * - Array.prototype.indexOf, License: CC0 (required by "Symbol.unscopables", "Symbol", "Object.getOwnPropertyNames", "es6")
 * - Function.prototype.bind, License: MIT (required by "String.prototype.@@iterator", "_StringIterator", "_Iterator", "es6")
 * - Math.acosh, License: CC0 (required by "es6")
 * - Math.asinh, License: CC0 (required by "es6")
 * - Math.atanh, License: CC0 (required by "es6")
 * - Math.cbrt, License: CC0 (required by "es6")
 * - Math.clz32, License: CC0 (required by "es6")
 * - Math.cosh, License: CC0 (required by "es6")
 * - Math.expm1, License: CC0 (required by "es6")
 * - Math.fround, License: CC0 (required by "es6")
 * - Math.hypot, License: CC0 (required by "es6")
 * - Math.imul, License: CC0 (required by "es6")
 * - Math.log10, License: CC0 (required by "es6")
 * - Math.log1p, License: CC0 (required by "es6")
 * - Math.log2, License: CC0 (required by "es6")
 * - Math.sign, License: CC0 (required by "es6")
 * - Math.sinh, License: CC0 (required by "es6")
 * - Math.tanh, License: CC0 (required by "es6")
 * - Math.trunc, License: CC0 (required by "es6")
 * - Number.isFinite, License: MIT (required by "es6")
 * - Number.isInteger, License: MIT (required by "es6")
 * - Number.isNaN, License: MIT (required by "es6")
 * - Number.isSafeInteger, License: MIT (required by "es6")
 * - Function.prototype.name, License: MIT (required by "es6")
 * - Number.Epsilon, License: MIT (required by "es6")
 * - Number.MAX_SAFE_INTEGER, License: MIT (required by "es6")
 * - Number.MIN_SAFE_INTEGER, License: MIT (required by "es6")
 * - Object.freeze, License: CC0 (required by "Symbol.unscopables", "Symbol", "es6")
 * - Object.getOwnPropertyDescriptor, License: CC0 (required by "String.prototype.@@iterator", "_StringIterator", "_Iterator", "Object.defineProperties", "es6")
 * - Object.getPrototypeOf, License: CC0 (required by "Array.of", "_ESAbstract.Construct", "_ESAbstract.OrdinaryCreateFromConstructor", "es6")
 * - Object.is, License: CC0 (required by "es6")
 * - Object.isExtensible, License: CC0 (required by "Array.from", "Map", "es6")
 * - Object.keys, License: MIT (required by "String.prototype.@@iterator", "_StringIterator", "_Iterator", "Object.defineProperties", "es6")
 * - Object.assign, License: CC0 (required by "String.prototype.@@iterator", "_StringIterator", "_Iterator", "es6")
 * - Object.defineProperties, License: CC0 (required by "String.prototype.@@iterator", "_StringIterator", "_Iterator", "es6")
 * - Object.create, License: CC0 (required by "String.prototype.@@iterator", "_StringIterator", "es6")
 * - _ESAbstract.OrdinaryCreateFromConstructor, License: CC0 (required by "Array.of", "_ESAbstract.Construct", "es6")
 * - _ESAbstract.Construct, License: CC0 (required by "Symbol.unscopables", "Symbol", "Array.prototype.filter", "_ESAbstract.ArraySpeciesCreate", "es6")
 * - _ESAbstract.ArraySpeciesCreate, License: CC0 (required by "Symbol.unscopables", "Symbol", "Array.prototype.filter", "es6")
 * - Array.prototype.filter, License: CC0 (required by "Symbol.unscopables", "Symbol", "es6")
 * - Array.prototype.map, License: CC0 (required by "Symbol.unscopables", "Symbol", "es6")
 * - Array.prototype.sort, License: MIT (required by "es6")
 * - Array.of, License: CC0 (required by "es6")
 * - Object.getOwnPropertyNames, License: CC0 (required by "Symbol.unscopables", "Symbol", "es6")
 * - Object.seal, License: MIT (required by "es6")
 * - Object.setPrototypeOf, License: MIT (required by "String.prototype.@@iterator", "_StringIterator", "es6")
 * - RegExp.prototype.flags, License: MIT (required by "es6")
 * - String.fromCodePoint, License: MIT (required by "es6")
 * - String.prototype.codePointAt, License: MIT (required by "es6")
 * - String.prototype.endsWith, License: CC0 (required by "es6")
 * - String.prototype.includes, License: CC0 (required by "Array.prototype.@@iterator", "Array.prototype.values", "_ArrayIterator", "es6")
 * - String.prototype.repeat, License: CC0 (required by "es6")
 * - String.prototype.startsWith, License: CC0 (required by "es6")
 * - String.prototype.trim, License: CC0 (required by "Number.parseInt", "es6")
 * - Number.parseFloat, License: MIT (required by "es6")
 * - Number.parseInt, License: MIT (required by "es6")
 * - Symbol, License: MIT (required by "String.prototype.@@iterator", "_StringIterator", "_Iterator", "es6")
 * - Symbol.hasInstance, License: MIT (required by "es6")
 * - Symbol.isConcatSpreadable, License: MIT (required by "es6")
 * - Symbol.iterator, License: MIT (required by "String.prototype.@@iterator", "_StringIterator", "_Iterator", "es6")
 * - _ESAbstract.GetIterator, License: CC0 (required by "WeakSet", "es6")
 * - Symbol.match, License: MIT (required by "es6")
 * - Symbol.replace, License: MIT (required by "es6")
 * - Symbol.search, License: MIT (required by "es6")
 * - Symbol.species, License: MIT (required by "Array.from", "Set", "es6")
 * - Map, License: CC0 (required by "Array.from", "es6")
 * - Set, License: CC0 (required by "Array.from", "es6")
 * - Array.from, License: CC0 (required by "es6")
 * - Symbol.split, License: MIT (required by "es6")
 * - Symbol.toPrimitive, License: MIT (required by "es6")
 * - Symbol.toStringTag, License: MIT (required by "String.prototype.@@iterator", "_StringIterator", "_Iterator", "es6")
 * - _Iterator, License: MIT (required by "String.prototype.@@iterator", "_StringIterator", "es6")
 * - _ArrayIterator, License: MIT (required by "Array.prototype.@@iterator", "Array.prototype.values", "es6")
 * - Array.prototype.entries, License: CC0 (required by "es6")
 * - Array.prototype.keys, License: CC0 (required by "es6")
 * - Array.prototype.values, License: MIT (required by "Array.prototype.@@iterator", "es6")
 * - Array.prototype.@@iterator, License: CC0 (required by "es6")
 * - _StringIterator, License: MIT (required by "String.prototype.@@iterator", "es6")
 * - String.prototype.@@iterator, License: CC0 (required by "es6")
 * - Promise, License: MIT (required by "es6")
 * - Symbol.unscopables, License: MIT (required by "es6")
 * - WeakMap, License: MIT (required by "es6")
 * - WeakSet, License: MIT (required by "es6") */

(function(self, undefined) {

// _ESAbstract.ArrayCreate
// 9.4.2.2. ArrayCreate ( length [ , proto ] )
function ArrayCreate(length /* [, proto] */) { // eslint-disable-line no-unused-vars
	// 1. Assert: length is an integer Number ≥ 0.
	// 2. If length is -0, set length to +0.
	if (1 / length === -Infinity) {
		length = 0;
	}
	// 3. If length>2^32-1, throw a RangeError exception.
	if (length > (Math.pow(2, 32) - 1)) {
		throw new RangeError('Invalid array length');
	}
	// 4. If proto is not present, set proto to the intrinsic object %ArrayPrototype%.
	// 5. Let A be a newly created Array exotic object.
	var A = [];
	// 6. Set A's essential internal methods except for [[DefineOwnProperty]] to the default ordinary object definitions specified in 9.1.
	// 7. Set A.[[DefineOwnProperty]] as specified in 9.4.2.1.
	// 8. Set A.[[Prototype]] to proto.
	// 9. Set A.[[Extensible]] to true.
	// 10. Perform ! OrdinaryDefineOwnProperty(A, "length", PropertyDescriptor{[[Value]]: length, [[Writable]]: true, [[Enumerable]]: false, [[Configurable]]: false}).
	A.length = length;
	// 11. Return A.
	return A;
}

// _ESAbstract.Call
/* global IsCallable */
// 7.3.12. Call ( F, V [ , argumentsList ] )
function Call(F, V /* [, argumentsList] */) { // eslint-disable-line no-unused-vars
	// 1. If argumentsList is not present, set argumentsList to a new empty List.
	var argumentsList = arguments.length > 2 ? arguments[2] : [];
	// 2. If IsCallable(F) is false, throw a TypeError exception.
	if (IsCallable(F) === false) {
		throw new TypeError(Object.prototype.toString.call(F) + 'is not a function.');
	}
	// 3. Return ? F.[[Call]](V, argumentsList).
	return F.apply(V, argumentsList);
}

// _ESAbstract.Get
// 7.3.1. Get ( O, P )
function Get(O, P) { // eslint-disable-line no-unused-vars
	// 1. Assert: Type(O) is Object.
	// 2. Assert: IsPropertyKey(P) is true.
	// 3. Return ? O.[[Get]](P, O).
	return O[P];
}

// _ESAbstract.HasOwnProperty
// 7.3.11 HasOwnProperty (O, P)
function HasOwnProperty(o, p) { // eslint-disable-line no-unused-vars
	// 1. Assert: Type(O) is Object.
	// 2. Assert: IsPropertyKey(P) is true.
	// 3. Let desc be ? O.[[GetOwnProperty]](P).
	// 4. If desc is undefined, return false.
	// 5. Return true.
	// Polyfill.io - As we expect user agents to support ES3 fully we can skip the above steps and use Object.prototype.hasOwnProperty to do them for us.
	return Object.prototype.hasOwnProperty.call(o, p);
}

// _ESAbstract.HasProperty
// 7.3.10. HasProperty ( O, P )
function HasProperty(O, P) { // eslint-disable-line no-unused-vars
	// Assert: Type(O) is Object.
	// Assert: IsPropertyKey(P) is true.
	// Return ? O.[[HasProperty]](P).
	return P in O;
}

// _ESAbstract.IsArray
// 7.2.2. IsArray ( argument )
function IsArray(argument) { // eslint-disable-line no-unused-vars
	// 1. If Type(argument) is not Object, return false.
	// 2. If argument is an Array exotic object, return true.
	// 3. If argument is a Proxy exotic object, then
		// a. If argument.[[ProxyHandler]] is null, throw a TypeError exception.
		// b. Let target be argument.[[ProxyTarget]].
		// c. Return ? IsArray(target).
	// 4. Return false.

	// Polyfill.io - We can skip all the above steps and check the string returned from Object.prototype.toString().
	return Object.prototype.toString.call(argument) === '[object Array]';
}

// _ESAbstract.IsCallable
// 7.2.3. IsCallable ( argument )
function IsCallable(argument) { // eslint-disable-line no-unused-vars
	// 1. If Type(argument) is not Object, return false.
	// 2. If argument has a [[Call]] internal method, return true.
	// 3. Return false.

	// Polyfill.io - Only function objects have a [[Call]] internal method. This means we can simplify this function to check that the argument has a type of function.
	return typeof argument === 'function';
}

// _ESAbstract.RequireObjectCoercible
// 7.2.1. RequireObjectCoercible ( argument )
// The abstract operation ToObject converts argument to a value of type Object according to Table 12:
// Table 12: ToObject Conversions
/*
|----------------------------------------------------------------------------------------------------------------------------------------------------|
| Argument Type | Result                                                                                                                             |
|----------------------------------------------------------------------------------------------------------------------------------------------------|
| Undefined     | Throw a TypeError exception.                                                                                                       |
| Null          | Throw a TypeError exception.                                                                                                       |
| Boolean       | Return argument.                                                                                                                   |
| Number        | Return argument.                                                                                                                   |
| String        | Return argument.                                                                                                                   |
| Symbol        | Return argument.                                                                                                                   |
| Object        | Return argument.                                                                                                                   |
|----------------------------------------------------------------------------------------------------------------------------------------------------|
*/
function RequireObjectCoercible(argument) { // eslint-disable-line no-unused-vars
	if (argument === null || argument === undefined) {
		throw TypeError(Object.prototype.toString.call(argument) + ' is not coercible to Object.');
	}
	return argument;
}

// _ESAbstract.SameValueNonNumber
// 7.2.12. SameValueNonNumber ( x, y )
function SameValueNonNumber(x, y) { // eslint-disable-line no-unused-vars
	// 1. Assert: Type(x) is not Number.
	// 2. Assert: Type(x) is the same as Type(y).
	// 3. If Type(x) is Undefined, return true.
	// 4. If Type(x) is Null, return true.
	// 5. If Type(x) is String, then
		// a. If x and y are exactly the same sequence of code units (same length and same code units at corresponding indices), return true; otherwise, return false.
	// 6. If Type(x) is Boolean, then
		// a. If x and y are both true or both false, return true; otherwise, return false.
	// 7. If Type(x) is Symbol, then
		// a. If x and y are both the same Symbol value, return true; otherwise, return false.
	// 8. If x and y are the same Object value, return true. Otherwise, return false.

	// Polyfill.io - We can skip all above steps because the === operator does it all for us.
	return x === y;
}

// _ESAbstract.ToBoolean
// 7.1.2. ToBoolean ( argument )
// The abstract operation ToBoolean converts argument to a value of type Boolean according to Table 9:
/*
--------------------------------------------------------------------------------------------------------------
| Argument Type | Result                                                                                     |
--------------------------------------------------------------------------------------------------------------
| Undefined     | Return false.                                                                              |
| Null          | Return false.                                                                              |
| Boolean       | Return argument.                                                                           |
| Number        | If argument is +0, -0, or NaN, return false; otherwise return true.                        |
| String        | If argument is the empty String (its length is zero), return false; otherwise return true. |
| Symbol        | Return true.                                                                               |
| Object        | Return true.                                                                               |
--------------------------------------------------------------------------------------------------------------
*/
function ToBoolean(argument) { // eslint-disable-line no-unused-vars
	return Boolean(argument);
}

// _ESAbstract.ToNumber
// 7.1.3. ToNumber ( argument )
function ToNumber(argument) { // eslint-disable-line no-unused-vars
	return Number(argument);
}

// _ESAbstract.ToObject
// 7.1.13 ToObject ( argument )
// The abstract operation ToObject converts argument to a value of type Object according to Table 12:
// Table 12: ToObject Conversions
/*
|----------------------------------------------------------------------------------------------------------------------------------------------------|
| Argument Type | Result                                                                                                                             |
|----------------------------------------------------------------------------------------------------------------------------------------------------|
| Undefined     | Throw a TypeError exception.                                                                                                       |
| Null          | Throw a TypeError exception.                                                                                                       |
| Boolean       | Return a new Boolean object whose [[BooleanData]] internal slot is set to argument. See 19.3 for a description of Boolean objects. |
| Number        | Return a new Number object whose [[NumberData]] internal slot is set to argument. See 20.1 for a description of Number objects.    |
| String        | Return a new String object whose [[StringData]] internal slot is set to argument. See 21.1 for a description of String objects.    |
| Symbol        | Return a new Symbol object whose [[SymbolData]] internal slot is set to argument. See 19.4 for a description of Symbol objects.    |
| Object        | Return argument.                                                                                                                   |
|----------------------------------------------------------------------------------------------------------------------------------------------------|
*/
function ToObject(argument) { // eslint-disable-line no-unused-vars
	if (argument === null || argument === undefined) {
		throw TypeError();
	}
	return Object(argument);
}

// _ESAbstract.GetV
/* global ToObject */
// 7.3.2 GetV (V, P)
function GetV(v, p) { // eslint-disable-line no-unused-vars
	// 1. Assert: IsPropertyKey(P) is true.
	// 2. Let O be ? ToObject(V).
	var o = ToObject(v);
	// 3. Return ? O.[[Get]](P, V).
	return o[p];
}

// _ESAbstract.GetMethod
/* global GetV, IsCallable */
// 7.3.9. GetMethod ( V, P )
function GetMethod(V, P) { // eslint-disable-line no-unused-vars
	// 1. Assert: IsPropertyKey(P) is true.
	// 2. Let func be ? GetV(V, P).
	var func = GetV(V, P);
	// 3. If func is either undefined or null, return undefined.
	if (func === null || func === undefined) {
		return undefined;
	}
	// 4. If IsCallable(func) is false, throw a TypeError exception.
	if (IsCallable(func) === false) {
		throw new TypeError('Method not callable: ' + P);
	}
	// 5. Return func.
	return func;
}

// _ESAbstract.ToUint32
// 7.1.6. ToUint32 ( argument )
function ToUint32(argument) { // eslint-disable-line no-unused-vars
	// 1. Let number be ? ToNumber(argument).
	var number = Number(argument);
	// 2. If number is NaN, +0, -0, +∞, or -∞, return +0.
	if (isNaN(number) || 1/number === Infinity || 1/number === -Infinity || number === Infinity || number === -Infinity) {
		return 0;
	}
	// 3. Let int be the mathematical value that is the same sign as number and whose magnitude is floor(abs(number)).
	var int = ((number < 0) ? -1 : 1) * Math.floor(Math.abs(number));
	// 4. Let int32bit be int modulo 2^32.
	var int32bit = int >>> 0;
	// 5. Return int32bit.
	return int32bit;
}

// _ESAbstract.Type
// "Type(x)" is used as shorthand for "the type of x"...
function Type(x) { // eslint-disable-line no-unused-vars
	switch (typeof x) {
		case 'undefined':
			return 'undefined';
		case 'boolean':
			return 'boolean';
		case 'number':
			return 'number';
		case 'string':
			return 'string';
		case 'symbol':
			return 'symbol';
		default:
			// typeof null is 'object'
			if (x === null) return 'null';
			// Polyfill.io - This is here because a Symbol polyfill will have a typeof `object`.
			if ('Symbol' in self && (x instanceof self.Symbol || x.constructor === self.Symbol)) return 'symbol';

			return 'object';
	}
}

// _ESAbstract.GetPrototypeFromConstructor
/* global Get, Type */
// 9.1.14. GetPrototypeFromConstructor ( constructor, intrinsicDefaultProto )
function GetPrototypeFromConstructor(constructor, intrinsicDefaultProto) { // eslint-disable-line no-unused-vars
	// 1. Assert: intrinsicDefaultProto is a String value that is this specification's name of an intrinsic object. The corresponding object must be an intrinsic that is intended to be used as the [[Prototype]] value of an object.
	// 2. Assert: IsCallable(constructor) is true.
	// 3. Let proto be ? Get(constructor, "prototype").
	var proto = Get(constructor, "prototype");
	// 4. If Type(proto) is not Object, then
	if (Type(proto) !== 'object') {
		// a. Let realm be ? GetFunctionRealm(constructor).
		// b. Set proto to realm's intrinsic object named intrinsicDefaultProto.
		proto = intrinsicDefaultProto;
	}
	// 5. Return proto.
	return proto;
}

// _ESAbstract.IsConstructor
/* global Type */
// 7.2.4. IsConstructor ( argument )
function IsConstructor(argument) { // eslint-disable-line no-unused-vars
	// 1. If Type(argument) is not Object, return false.
	if (Type(argument) !== 'object') {
		return false;
	}
	// 2. If argument has a [[Construct]] internal method, return true.
	// 3. Return false.

	// Polyfill.io - `new argument` is the only way  to truly test if a function is a constructor.
	// We choose to not use`new argument` because the argument could have side effects when called.
	// Instead we check to see if the argument is a function and if it has a prototype.
	// Arrow functions do not have a [[Construct]] internal method, nor do they have a prototype.
	return typeof argument === 'function' && !!argument.prototype;
}

// _ESAbstract.IsRegExp
/* global Type, Get, ToBoolean */
// 7.2.8. IsRegExp ( argument )
function IsRegExp(argument) { // eslint-disable-line no-unused-vars
	// 1. If Type(argument) is not Object, return false.
	if (Type(argument) !== 'object') {
		return false;
	}
	// 2. Let matcher be ? Get(argument, @@match).
	var matcher = 'Symbol' in self && 'match' in self.Symbol ? Get(argument, self.Symbol.match) : undefined;
	// 3. If matcher is not undefined, return ToBoolean(matcher).
	if (matcher !== undefined) {
		return ToBoolean(matcher);
	}
	// 4. If argument has a [[RegExpMatcher]] internal slot, return true.
	try {
		var lastIndex = argument.lastIndex;
		argument.lastIndex = 0;
		RegExp.prototype.exec.call(argument);
		return true;
	// eslint-disable-next-line no-empty
	} catch (e) {} finally {
		argument.lastIndex = lastIndex;
	}
	// 5. Return false.
	return false;
}

// _ESAbstract.IteratorClose
/* global GetMethod, Type, Call */
// 7.4.6. IteratorClose ( iteratorRecord, completion )
function IteratorClose(iteratorRecord, completion) { // eslint-disable-line no-unused-vars
	// 1. Assert: Type(iteratorRecord.[[Iterator]]) is Object.
	if (Type(iteratorRecord['[[Iterator]]']) !== 'object') {
		throw new Error(Object.prototype.toString.call(iteratorRecord['[[Iterator]]']) + 'is not an Object.');
	}
	// 2. Assert: completion is a Completion Record.
	// Polyfill.io - Ignoring this step as there is no way to check if something is a Completion Record in userland JavaScript.

	// 3. Let iterator be iteratorRecord.[[Iterator]].
	var iterator = iteratorRecord['[[Iterator]]'];
	// 4. Let return be ? GetMethod(iterator, "return").
	// Polyfill.io - We name it  returnMethod because return is a keyword and can not be used as an identifier (E.G. variable name, function name etc).
	var returnMethod = GetMethod(iterator, "return");
	// 5. If return is undefined, return Completion(completion).
	if (returnMethod === undefined) {
		return completion;
	}
	// 6. Let innerResult be Call(return, iterator, « »).
	try {
		var innerResult = Call(returnMethod, iterator);
	} catch (error) {
		var innerException = error;
	}
	// 7. If completion.[[Type]] is throw, return Completion(completion).
	if (completion) {
		return completion;
	}
	// 8. If innerResult.[[Type]] is throw, return Completion(innerResult).
	if (innerException) {
		throw innerException;
	}
	// 9. If Type(innerResult.[[Value]]) is not Object, throw a TypeError exception.
	if (Type(innerResult) !== 'object') {
		throw new TypeError("Iterator's return method returned a non-object.");
	}
	// 10. Return Completion(completion).
	return completion;
}

// _ESAbstract.IteratorComplete
/* global Type, ToBoolean, Get */
// 7.4.3 IteratorComplete ( iterResult )
function IteratorComplete(iterResult) { // eslint-disable-line no-unused-vars
	// 1. Assert: Type(iterResult) is Object.
	if (Type(iterResult) !== 'object') {
		throw new Error(Object.prototype.toString.call(iterResult) + 'is not an Object.');
	}
	// 2. Return ToBoolean(? Get(iterResult, "done")).
	return ToBoolean(Get(iterResult, "done"));
}

// _ESAbstract.IteratorNext
/* global Call, Type */
// 7.4.2. IteratorNext ( iteratorRecord [ , value ] )
function IteratorNext(iteratorRecord /* [, value] */) { // eslint-disable-line no-unused-vars
	// 1. If value is not present, then
	if (arguments.length < 2) {
		// a. Let result be ? Call(iteratorRecord.[[NextMethod]], iteratorRecord.[[Iterator]], « »).
		var result = Call(iteratorRecord['[[NextMethod]]'], iteratorRecord['[[Iterator]]']);
	// 2. Else,
	} else {
		// a. Let result be ? Call(iteratorRecord.[[NextMethod]], iteratorRecord.[[Iterator]], « value »).
		result = Call(iteratorRecord['[[NextMethod]]'], iteratorRecord['[[Iterator]]'], [arguments[1]]);
	}
	// 3. If Type(result) is not Object, throw a TypeError exception.
	if (Type(result) !== 'object') {
		throw new TypeError('bad iterator');
	}
	// 4. Return result.
	return result;
}

// _ESAbstract.IteratorStep
/* global IteratorNext, IteratorComplete */
// 7.4.5. IteratorStep ( iteratorRecord )
function IteratorStep(iteratorRecord) { // eslint-disable-line no-unused-vars
	// 1. Let result be ? IteratorNext(iteratorRecord).
	var result = IteratorNext(iteratorRecord);
	// 2. Let done be ? IteratorComplete(result).
	var done = IteratorComplete(result);
	// 3. If done is true, return false.
	if (done === true) {
		return false;
	}
	// 4. Return result.
	return result;
}

// _ESAbstract.IteratorValue
/* global Type, Get */
// 7.4.4 IteratorValue ( iterResult )
function IteratorValue(iterResult) { // eslint-disable-line no-unused-vars
	// Assert: Type(iterResult) is Object.
	if (Type(iterResult) !== 'object') {
		throw new Error(Object.prototype.toString.call(iterResult) + 'is not an Object.');
	}
	// Return ? Get(iterResult, "value").
	return Get(iterResult, "value");
}

// _ESAbstract.OrdinaryToPrimitive
/* global Get, IsCallable, Call, Type */
// 7.1.1.1. OrdinaryToPrimitive ( O, hint )
function OrdinaryToPrimitive(O, hint) { // eslint-disable-line no-unused-vars
	// 1. Assert: Type(O) is Object.
	// 2. Assert: Type(hint) is String and its value is either "string" or "number".
	// 3. If hint is "string", then
	if (hint === 'string') {
		// a. Let methodNames be « "toString", "valueOf" ».
		var methodNames = ['toString', 'valueOf'];
		// 4. Else,
	} else {
		// a. Let methodNames be « "valueOf", "toString" ».
		methodNames = ['valueOf', 'toString'];
	}
	// 5. For each name in methodNames in List order, do
	for (var i = 0; i < methodNames.length; ++i) {
		var name = methodNames[i];
		// a. Let method be ? Get(O, name).
		var method = Get(O, name);
		// b. If IsCallable(method) is true, then
		if (IsCallable(method)) {
			// i. Let result be ? Call(method, O).
			var result = Call(method, O);
			// ii. If Type(result) is not Object, return result.
			if (Type(result) !== 'object') {
				return result;
			}
		}
	}
	// 6. Throw a TypeError exception.
	throw new TypeError('Cannot convert to primitive.');
}

// _ESAbstract.SameValue
/* global Type, SameValueNonNumber */
// 7.2.10. SameValue ( x, y )
function SameValue(x, y) { // eslint-disable-line no-unused-vars
	// 1. If Type(x) is different from Type(y), return false.
	if (Type(x) !== Type(y)) {
		return false;
	}
	// 2. If Type(x) is Number, then
	if (Type(x) === 'number') {
		// a. If x is NaN and y is NaN, return true.
		if (isNaN(x) && isNaN(y)) {
			return true;
		}
		// Polyfill.io - 0 === -0 is true, but they are not the same value.
		// b. If x is +0 and y is -0, return false.
		// c. If x is -0 and y is +0, return false.
		if (x === 0 && y === 0 && 1/x !== 1/y) {
			return false;
		}
		// d. If x is the same Number value as y, return true.
		if (x === y) {
			return true;
		}
		// e. Return false.
		return false;
	}
	// 3. Return SameValueNonNumber(x, y).
	return SameValueNonNumber(x, y);
}

// _ESAbstract.SameValueZero
/* global Type, SameValueNonNumber */
// 7.2.11. SameValueZero ( x, y )
function SameValueZero (x, y) { // eslint-disable-line no-unused-vars
	// 1. If Type(x) is different from Type(y), return false.
	if (Type(x) !== Type(y)) {
		return false;
	}
	// 2. If Type(x) is Number, then
	if (Type(x) === 'number') {
		// a. If x is NaN and y is NaN, return true.
		if (isNaN(x) && isNaN(y)) {
			return true;
		}
		// b. If x is +0 and y is -0, return true.
		if (1/x === Infinity && 1/y === -Infinity) {
			return true;
		}
		// c. If x is -0 and y is +0, return true.
		if (1/x === -Infinity && 1/y === Infinity) {
			return true;
		}
		// d. If x is the same Number value as y, return true.
		if (x === y) {
			return true;
		}
		// e. Return false.
		return false;
	}
	// 3. Return SameValueNonNumber(x, y).
	return SameValueNonNumber(x, y);
}

// _ESAbstract.ToInteger
/* global Type */
// 7.1.4. ToInteger ( argument )
function ToInteger(argument) { // eslint-disable-line no-unused-vars
	if (Type(argument) === 'symbol') {
		throw new TypeError('Cannot convert a Symbol value to a number');
	}

	// 1. Let number be ? ToNumber(argument).
	var number = Number(argument);
	// 2. If number is NaN, return +0.
	if (isNaN(number)) {
		return 0;
	}
	// 3. If number is +0, -0, +∞, or -∞, return number.
	if (1/number === Infinity || 1/number === -Infinity || number === Infinity || number === -Infinity) {
		return number;
	}
	// 4. Return the number value that is the same sign as number and whose magnitude is floor(abs(number)).
	return ((number < 0) ? -1 : 1) * Math.floor(Math.abs(number));
}

// _ESAbstract.ToLength
/* global ToInteger */
// 7.1.15. ToLength ( argument )
function ToLength(argument) { // eslint-disable-line no-unused-vars
	// 1. Let len be ? ToInteger(argument).
	var len = ToInteger(argument);
	// 2. If len ≤ +0, return +0.
	if (len <= 0) {
		return 0;
	}
	// 3. Return min(len, 253-1).
	return Math.min(len, Math.pow(2, 53) -1);
}

// _ESAbstract.ToPrimitive
/* global Type, GetMethod, Call, OrdinaryToPrimitive */
// 7.1.1. ToPrimitive ( input [ , PreferredType ] )
function ToPrimitive(input /* [, PreferredType] */) { // eslint-disable-line no-unused-vars
	var PreferredType = arguments.length > 1 ? arguments[1] : undefined;
	// 1. Assert: input is an ECMAScript language value.
	// 2. If Type(input) is Object, then
	if (Type(input) === 'object') {
		// a. If PreferredType is not present, let hint be "default".
		if (arguments.length < 2) {
			var hint = 'default';
			// b. Else if PreferredType is hint String, let hint be "string".
		} else if (PreferredType === String) {
			hint = 'string';
			// c. Else PreferredType is hint Number, let hint be "number".
		} else if (PreferredType === Number) {
			hint = 'number';
		}
		// d. Let exoticToPrim be ? GetMethod(input, @@toPrimitive).
		var exoticToPrim = typeof self.Symbol === 'function' && typeof self.Symbol.toPrimitive === 'symbol' ? GetMethod(input, self.Symbol.toPrimitive) : undefined;
		// e. If exoticToPrim is not undefined, then
		if (exoticToPrim !== undefined) {
			// i. Let result be ? Call(exoticToPrim, input, « hint »).
			var result = Call(exoticToPrim, input, [hint]);
			// ii. If Type(result) is not Object, return result.
			if (Type(result) !== 'object') {
				return result;
			}
			// iii. Throw a TypeError exception.
			throw new TypeError('Cannot convert exotic object to primitive.');
		}
		// f. If hint is "default", set hint to "number".
		if (hint === 'default') {
			hint = 'number';
		}
		// g. Return ? OrdinaryToPrimitive(input, hint).
		return OrdinaryToPrimitive(input, hint);
	}
	// 3. Return input
	return input;
}

// _ESAbstract.ToString
/* global Type, ToPrimitive */
// 7.1.12. ToString ( argument )
// The abstract operation ToString converts argument to a value of type String according to Table 11:
// Table 11: ToString Conversions
/*
|---------------|--------------------------------------------------------|
| Argument Type | Result                                                 |
|---------------|--------------------------------------------------------|
| Undefined     | Return "undefined".                                    |
|---------------|--------------------------------------------------------|
| Null	        | Return "null".                                         |
|---------------|--------------------------------------------------------|
| Boolean       | If argument is true, return "true".                    |
|               | If argument is false, return "false".                  |
|---------------|--------------------------------------------------------|
| Number        | Return NumberToString(argument).                       |
|---------------|--------------------------------------------------------|
| String        | Return argument.                                       |
|---------------|--------------------------------------------------------|
| Symbol        | Throw a TypeError exception.                           |
|---------------|--------------------------------------------------------|
| Object        | Apply the following steps:                             |
|               | Let primValue be ? ToPrimitive(argument, hint String). |
|               | Return ? ToString(primValue).                          |
|---------------|--------------------------------------------------------|
*/
function ToString(argument) { // eslint-disable-line no-unused-vars
	switch(Type(argument)) {
		case 'symbol':
			throw new TypeError('Cannot convert a Symbol value to a string');
		case 'object':
			var primValue = ToPrimitive(argument, String);
			return ToString(primValue); // eslint-disable-line no-unused-vars
		default:
			return String(argument);
	}
}

// _ESAbstract.ToPropertyKey
/* globals ToPrimitive, Type, ToString */
// 7.1.14. ToPropertyKey ( argument )
function ToPropertyKey(argument) { // eslint-disable-line no-unused-vars
	// 1. Let key be ? ToPrimitive(argument, hint String).
	var key = ToPrimitive(argument, String);
	// 2. If Type(key) is Symbol, then
	if (Type(key) === 'symbol') {
		// a. Return key.
		return key;
	}
	// 3. Return ! ToString(key).
	return ToString(key);
}

// _ESAbstract.TrimString
/* eslint-disable no-control-regex */
/* global RequireObjectCoercible, ToString */
// TrimString ( string, where )
function TrimString(string, where) { // eslint-disable-line no-unused-vars
	// 1. Let str be ? RequireObjectCoercible(string).
	var str = RequireObjectCoercible(string);
	// 2. Let S be ? ToString(str).
	var S = ToString(str);
	// 3. If where is "start", let T be a String value that is a copy of S with leading white space removed.
	// The definition of white space is the union of WhiteSpace and LineTerminator. When determining whether a Unicode code point is in Unicode general category “Space_Separator” (“Zs”), code unit sequences are interpreted as UTF-16 encoded code point sequences as specified in 6.1.4.
	var whitespace = /[\x09\x0A\x0B\x0C\x0D\x20\xA0\u1680\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000\u2028\u2029\uFEFF]+/.source;
	if (where === 'start') {
		var T = String.prototype.replace.call(S, new RegExp('^' + whitespace, 'g'), '');
		// 4. Else if where is "end", let T be a String value that is a copy of S with trailing white space removed.
	} else if (where === "end") {
		T = String.prototype.replace.call(S, new RegExp(whitespace + '$', 'g'), '');
		// 5. Else,
	} else {
		// a. Assert: where is "start+end".
		// b. Let T be a String value that is a copy of S with both leading and trailing white space removed.
		T = String.prototype.replace.call(S, new RegExp('^' + whitespace + '|' + whitespace + '$', 'g'), '');
	}
	// 6. Return T.
	return T;
}

// _ESAbstract.UTF16Decode
// 10.1.2. Static Semantics: UTF16Decode( lead, trail )
function UTF16Decode(lead, trail) { // eslint-disable-line no-unused-vars
	// 1. Assert: 0xD800 ≤ lead ≤ 0xDBFF and 0xDC00 ≤ trail ≤ 0xDFFF.
	// 2. Let cp be (lead - 0xD800) × 0x400 + (trail - 0xDC00) + 0x10000.
	var cp = (lead - 0xD800) * 0x400 + (trail - 0xDC00) + 0x10000;
	// 3. Return the code point cp.
	return cp;
}

// _ESAbstract.UTF16Encoding
// 10.1.1. Static Semantics: UTF16Encoding ( cp )
function UTF16Encoding(cp) { // eslint-disable-line no-unused-vars
	// 1. Assert: 0 ≤ cp ≤ 0x10FFFF.
	// 2. If cp ≤ 0xFFFF, return cp.
	if (cp <= 0xFFFF) {
		return cp;
	} else {
		// 3. Let cu1 be floor((cp - 0x10000) / 0x400) + 0xD800.
		var cu1 = Math.floor((cp - 0x10000) / 0x400) + 0xD800;
		// 4. Let cu2 be ((cp - 0x10000) modulo 0x400) + 0xDC00.
		var cu2 = ((cp - 0x10000) % 0x400) + 0xDC00;
		// 5. Return the code unit sequence consisting of cu1 followed by cu2.
		return [cu1, cu2];
	}
}

// ArrayBuffer
/*
 Copyright (c) 2010, Linden Research, Inc.
 Copyright (c) 2014, Joshua Bell

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 $/LicenseInfo$
 */

// Original can be found at:
//   https://bitbucket.org/lindenlab/llsd
// Modifications by Joshua Bell inexorabletash@gmail.com
//   https://github.com/inexorabletash/polyfill

// ES3/ES5 implementation of the Krhonos Typed Array Specification
//   Ref: http://www.khronos.org/registry/typedarray/specs/latest/
//   Date: 2011-02-01
//
// Variations:
//  * Allows typed_array.get/set() as alias for subscripts (typed_array[])
//  * Gradually migrating structure from Khronos spec to ES2015 spec
//
// Caveats:
//  * Beyond 10000 or so entries, polyfilled array accessors (ta[0],
//    etc) become memory-prohibitive, so array creation will fail. Set
//    self.TYPED_ARRAY_POLYFILL_NO_ARRAY_ACCESSORS=true to disable
//    creation of accessors. Your code will need to use the
//    non-standard get()/set() instead, and will need to add those to
//    native arrays for interop.
(function(global) {
  'use strict';
  var undefined = (void 0); // Paranoia

  // Beyond this value, index getters/setters (i.e. array[0], array[1]) are so slow to
  // create, and consume so much memory, that the browser appears frozen.
  var MAX_ARRAY_LENGTH = 1e5;

  // Approximations of internal ECMAScript conversion functions
  function Type(v) {
    switch(typeof v) {
    case 'undefined': return 'undefined';
    case 'boolean': return 'boolean';
    case 'number': return 'number';
    case 'string': return 'string';
    default: return v === null ? 'null' : 'object';
    }
  }

  // Class returns internal [[Class]] property, used to avoid cross-frame instanceof issues:
  function Class(v) { return Object.prototype.toString.call(v).replace(/^\[object *|\]$/g, ''); }
  function IsCallable(o) { return typeof o === 'function'; }
  function ToObject(v) {
    if (v === null || v === undefined) throw TypeError();
    return Object(v);
  }
  function ToInt32(v) { return v >> 0; }
  function ToUint32(v) { return v >>> 0; }

  // Snapshot intrinsics
  var LN2 = Math.LN2,
      abs = Math.abs,
      floor = Math.floor,
      log = Math.log,
      max = Math.max,
      min = Math.min,
      pow = Math.pow,
      round = Math.round;

  // emulate ES5 getter/setter API using legacy APIs
  // http://blogs.msdn.com/b/ie/archive/2010/09/07/transitioning-existing-code-to-the-es5-getter-setter-apis.aspx
  // (second clause tests for Object.defineProperty() in IE<9 that only supports extending DOM prototypes, but
  // note that IE<9 does not support __defineGetter__ or __defineSetter__ so it just renders the method harmless)

  (function() {
    var orig = Object.defineProperty;
    var dom_only = !(function(){try{return Object.defineProperty({},'x',{});}catch(_){return false;}}());

    if (!orig || dom_only) {
      Object.defineProperty = function (o, prop, desc) {
        // In IE8 try built-in implementation for defining properties on DOM prototypes.
        if (orig)
          try { return orig(o, prop, desc); } catch (_) {}
        if (o !== Object(o))
          throw TypeError('Object.defineProperty called on non-object');
        if (Object.prototype.__defineGetter__ && ('get' in desc))
          Object.prototype.__defineGetter__.call(o, prop, desc.get);
        if (Object.prototype.__defineSetter__ && ('set' in desc))
          Object.prototype.__defineSetter__.call(o, prop, desc.set);
        if ('value' in desc)
          o[prop] = desc.value;
        return o;
      };
    }
  }());

  // ES5: Make obj[index] an alias for obj._getter(index)/obj._setter(index, value)
  // for index in 0 ... obj.length
  function makeArrayAccessors(obj) {
    if ('TYPED_ARRAY_POLYFILL_NO_ARRAY_ACCESSORS' in global)
      return;

    if (obj.length > MAX_ARRAY_LENGTH) throw RangeError('Array too large for polyfill');

    function makeArrayAccessor(index) {
      try {
        Object.defineProperty(obj, index, {
          'get': function() { return obj._getter(index); },
          'set': function(v) { obj._setter(index, v); },
          enumerable: true,
          configurable: false
        });
      } catch (_){ }
    }

    var i;
    for (i = 0; i < obj.length; i += 1) {
      makeArrayAccessor(i);
    }
  }

  // Internal conversion functions:
  //    pack<Type>()   - take a number (interpreted as Type), output a byte array
  //    unpack<Type>() - take a byte array, output a Type-like number

  function as_signed(value, bits) { var s = 32 - bits; return (value << s) >> s; }
  function as_unsigned(value, bits) { var s = 32 - bits; return (value << s) >>> s; }

  function packI8(n) { return [n & 0xff]; }
  function unpackI8(bytes) { return as_signed(bytes[0], 8); }

  function packU8(n) { return [n & 0xff]; }
  function unpackU8(bytes) { return as_unsigned(bytes[0], 8); }

  function packU8Clamped(n) { n = round(Number(n)); return [n < 0 ? 0 : n > 0xff ? 0xff : n & 0xff]; }

  function packI16(n) { return [n & 0xff, (n >> 8) & 0xff]; }
  function unpackI16(bytes) { return as_signed(bytes[1] << 8 | bytes[0], 16); }

  function packU16(n) { return [n & 0xff, (n >> 8) & 0xff]; }
  function unpackU16(bytes) { return as_unsigned(bytes[1] << 8 | bytes[0], 16); }

  function packI32(n) { return [n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff, (n >> 24) & 0xff]; }
  function unpackI32(bytes) { return as_signed(bytes[3] << 24 | bytes[2] << 16 | bytes[1] << 8 | bytes[0], 32); }

  function packU32(n) { return [n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff, (n >> 24) & 0xff]; }
  function unpackU32(bytes) { return as_unsigned(bytes[3] << 24 | bytes[2] << 16 | bytes[1] << 8 | bytes[0], 32); }

  function packIEEE754(v, ebits, fbits) {

    var bias = (1 << (ebits - 1)) - 1;

    function roundToEven(n) {
      var w = floor(n), f = n - w;
      if (f < 0.5)
        return w;
      if (f > 0.5)
        return w + 1;
      return w % 2 ? w + 1 : w;
    }

    // Compute sign, exponent, fraction
    var s, e, f;
    if (v !== v) {
      // NaN
      // http://dev.w3.org/2006/webapi/WebIDL/#es-type-mapping
      e = (1 << ebits) - 1; f = pow(2, fbits - 1); s = 0;
    } else if (v === Infinity || v === -Infinity) {
      e = (1 << ebits) - 1; f = 0; s = (v < 0) ? 1 : 0;
    } else if (v === 0) {
      e = 0; f = 0; s = (1 / v === -Infinity) ? 1 : 0;
    } else {
      s = v < 0;
      v = abs(v);

      if (v >= pow(2, 1 - bias)) {
        // Normalized
        e = min(floor(log(v) / LN2), 1023);
        var significand = v / pow(2, e);
        if (significand < 1) {
          e -= 1;
          significand *= 2;
        }
        if (significand >= 2) {
          e += 1;
          significand /= 2;
        }
        var d = pow(2, fbits);
        f = roundToEven(significand * d) - d;
        e += bias;
        if (f / d >= 1) {
          e += 1;
          f = 0;
        }
        if (e > 2 * bias) {
          // Overflow
          e = (1 << ebits) - 1;
          f = 0;
        }
      } else {
        // Denormalized
        e = 0;
        f = roundToEven(v / pow(2, 1 - bias - fbits));
      }
    }

    // Pack sign, exponent, fraction
    var bits = [], i;
    for (i = fbits; i; i -= 1) { bits.push(f % 2 ? 1 : 0); f = floor(f / 2); }
    for (i = ebits; i; i -= 1) { bits.push(e % 2 ? 1 : 0); e = floor(e / 2); }
    bits.push(s ? 1 : 0);
    bits.reverse();
    var str = bits.join('');

    // Bits to bytes
    var bytes = [];
    while (str.length) {
      bytes.unshift(parseInt(str.substring(0, 8), 2));
      str = str.substring(8);
    }
    return bytes;
  }

  function unpackIEEE754(bytes, ebits, fbits) {
    // Bytes to bits
    var bits = [], i, j, b, str,
        bias, s, e, f;

    for (i = 0; i < bytes.length; ++i) {
      b = bytes[i];
      for (j = 8; j; j -= 1) {
        bits.push(b % 2 ? 1 : 0); b = b >> 1;
      }
    }
    bits.reverse();
    str = bits.join('');

    // Unpack sign, exponent, fraction
    bias = (1 << (ebits - 1)) - 1;
    s = parseInt(str.substring(0, 1), 2) ? -1 : 1;
    e = parseInt(str.substring(1, 1 + ebits), 2);
    f = parseInt(str.substring(1 + ebits), 2);

    // Produce number
    if (e === (1 << ebits) - 1) {
      return f !== 0 ? NaN : s * Infinity;
    } else if (e > 0) {
      // Normalized
      return s * pow(2, e - bias) * (1 + f / pow(2, fbits));
    } else if (f !== 0) {
      // Denormalized
      return s * pow(2, -(bias - 1)) * (f / pow(2, fbits));
    } else {
      return s < 0 ? -0 : 0;
    }
  }

  function unpackF64(b) { return unpackIEEE754(b, 11, 52); }
  function packF64(v) { return packIEEE754(v, 11, 52); }
  function unpackF32(b) { return unpackIEEE754(b, 8, 23); }
  function packF32(v) { return packIEEE754(v, 8, 23); }

  //
  // 3 The ArrayBuffer Type
  //

  (function() {

    function ArrayBuffer(length) {
      length = ToInt32(length);
      if (length < 0) throw RangeError('ArrayBuffer size is not a small enough positive integer.');
      Object.defineProperty(this, 'byteLength', {value: length});
      Object.defineProperty(this, '_bytes', {value: Array(length)});

      for (var i = 0; i < length; i += 1)
        this._bytes[i] = 0;
    }

    global.ArrayBuffer = global.ArrayBuffer || ArrayBuffer;

    //
    // 5 The Typed Array View Types
    //

    function $TypedArray$() {

      // %TypedArray% ( length )
      if (!arguments.length || typeof arguments[0] !== 'object') {
        return (function(length) {
          length = ToInt32(length);
          if (length < 0) throw RangeError('length is not a small enough positive integer.');
          Object.defineProperty(this, 'length', {value: length});
          Object.defineProperty(this, 'byteLength', {value: length * this.BYTES_PER_ELEMENT});
          Object.defineProperty(this, 'buffer', {value: new ArrayBuffer(this.byteLength)});
          Object.defineProperty(this, 'byteOffset', {value: 0});

         }).apply(this, arguments);
      }

      // %TypedArray% ( typedArray )
      if (arguments.length >= 1 &&
          Type(arguments[0]) === 'object' &&
          arguments[0] instanceof $TypedArray$) {
        return (function(typedArray){
          if (this.constructor !== typedArray.constructor) throw TypeError();

          var byteLength = typedArray.length * this.BYTES_PER_ELEMENT;
          Object.defineProperty(this, 'buffer', {value: new ArrayBuffer(byteLength)});
          Object.defineProperty(this, 'byteLength', {value: byteLength});
          Object.defineProperty(this, 'byteOffset', {value: 0});
          Object.defineProperty(this, 'length', {value: typedArray.length});

          for (var i = 0; i < this.length; i += 1)
            this._setter(i, typedArray._getter(i));

        }).apply(this, arguments);
      }

      // %TypedArray% ( array )
      if (arguments.length >= 1 &&
          Type(arguments[0]) === 'object' &&
          !(arguments[0] instanceof $TypedArray$) &&
          !(arguments[0] instanceof ArrayBuffer || Class(arguments[0]) === 'ArrayBuffer')) {
        return (function(array) {

          var byteLength = array.length * this.BYTES_PER_ELEMENT;
          Object.defineProperty(this, 'buffer', {value: new ArrayBuffer(byteLength)});
          Object.defineProperty(this, 'byteLength', {value: byteLength});
          Object.defineProperty(this, 'byteOffset', {value: 0});
          Object.defineProperty(this, 'length', {value: array.length});

          for (var i = 0; i < this.length; i += 1) {
            var s = array[i];
            this._setter(i, Number(s));
          }
        }).apply(this, arguments);
      }

      // %TypedArray% ( buffer, byteOffset=0, length=undefined )
      if (arguments.length >= 1 &&
          Type(arguments[0]) === 'object' &&
          (arguments[0] instanceof ArrayBuffer || Class(arguments[0]) === 'ArrayBuffer')) {
        return (function(buffer, byteOffset, length) {

          byteOffset = ToUint32(byteOffset);
          if (byteOffset > buffer.byteLength)
            throw RangeError('byteOffset out of range');

          // The given byteOffset must be a multiple of the element
          // size of the specific type, otherwise an exception is raised.
          if (byteOffset % this.BYTES_PER_ELEMENT)
            throw RangeError('buffer length minus the byteOffset is not a multiple of the element size.');

          if (length === undefined) {
            var byteLength = buffer.byteLength - byteOffset;
            if (byteLength % this.BYTES_PER_ELEMENT)
              throw RangeError('length of buffer minus byteOffset not a multiple of the element size');
            length = byteLength / this.BYTES_PER_ELEMENT;

          } else {
            length = ToUint32(length);
            byteLength = length * this.BYTES_PER_ELEMENT;
          }

          if ((byteOffset + byteLength) > buffer.byteLength)
            throw RangeError('byteOffset and length reference an area beyond the end of the buffer');

          Object.defineProperty(this, 'buffer', {value: buffer});
          Object.defineProperty(this, 'byteLength', {value: byteLength});
          Object.defineProperty(this, 'byteOffset', {value: byteOffset});
          Object.defineProperty(this, 'length', {value: length});

        }).apply(this, arguments);
      }

      // %TypedArray% ( all other argument combinations )
      throw TypeError();
    }

    // Properties of the %TypedArray Instrinsic Object

    // %TypedArray%.from ( source , mapfn=undefined, thisArg=undefined )
    Object.defineProperty($TypedArray$, 'from', {value: function(iterable) {
      return new this(iterable);
    }});

    // %TypedArray%.of ( ...items )
    Object.defineProperty($TypedArray$, 'of', {value: function(/*...items*/) {
      return new this(arguments);
    }});

    // %TypedArray%.prototype
    var $TypedArrayPrototype$ = {};
    $TypedArray$.prototype = $TypedArrayPrototype$;

    // WebIDL: getter type (unsigned long index);
    Object.defineProperty($TypedArray$.prototype, '_getter', {value: function(index) {
      if (arguments.length < 1) throw SyntaxError('Not enough arguments');

      index = ToUint32(index);
      if (index >= this.length)
        return undefined;

      var bytes = [], i, o;
      for (i = 0, o = this.byteOffset + index * this.BYTES_PER_ELEMENT;
           i < this.BYTES_PER_ELEMENT;
           i += 1, o += 1) {
        bytes.push(this.buffer._bytes[o]);
      }
      return this._unpack(bytes);
    }});

    // NONSTANDARD: convenience alias for getter: type get(unsigned long index);
    Object.defineProperty($TypedArray$.prototype, 'get', {value: $TypedArray$.prototype._getter});

    // WebIDL: setter void (unsigned long index, type value);
    Object.defineProperty($TypedArray$.prototype, '_setter', {value: function(index, value) {
      if (arguments.length < 2) throw SyntaxError('Not enough arguments');

      index = ToUint32(index);
      if (index >= this.length)
        return;

      var bytes = this._pack(value), i, o;
      for (i = 0, o = this.byteOffset + index * this.BYTES_PER_ELEMENT;
           i < this.BYTES_PER_ELEMENT;
           i += 1, o += 1) {
        this.buffer._bytes[o] = bytes[i];
      }
    }});

    // get %TypedArray%.prototype.buffer
    // get %TypedArray%.prototype.byteLength
    // get %TypedArray%.prototype.byteOffset
    // -- applied directly to the object in the constructor

    // %TypedArray%.prototype.constructor
    Object.defineProperty($TypedArray$.prototype, 'constructor', {value: $TypedArray$});

    // %TypedArray%.prototype.copyWithin (target, start, end = this.length )
    Object.defineProperty($TypedArray$.prototype, 'copyWithin', {value: function(target, start) {
      var end = arguments[2];

      var o = ToObject(this);
      var lenVal = o.length;
      var len = ToUint32(lenVal);
      len = max(len, 0);
      var relativeTarget = ToInt32(target);
      var to;
      if (relativeTarget < 0)
        to = max(len + relativeTarget, 0);
      else
        to = min(relativeTarget, len);
      var relativeStart = ToInt32(start);
      var from;
      if (relativeStart < 0)
        from = max(len + relativeStart, 0);
      else
        from = min(relativeStart, len);
      var relativeEnd;
      if (end === undefined)
        relativeEnd = len;
      else
        relativeEnd = ToInt32(end);
      var final;
      if (relativeEnd < 0)
        final = max(len + relativeEnd, 0);
      else
        final = min(relativeEnd, len);
      var count = min(final - from, len - to);
      var direction;
      if (from < to && to < from + count) {
        direction = -1;
        from = from + count - 1;
        to = to + count - 1;
      } else {
        direction = 1;
      }
      while (count > 0) {
        o._setter(to, o._getter(from));
        from = from + direction;
        to = to + direction;
        count = count - 1;
      }
      return o;
    }});

    // %TypedArray%.prototype.entries ( )
    // -- defined in es6.js to shim browsers w/ native TypedArrays

    // %TypedArray%.prototype.every ( callbackfn, thisArg = undefined )
    Object.defineProperty($TypedArray$.prototype, 'every', {value: function(callbackfn) {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      if (!IsCallable(callbackfn)) throw TypeError();
      var thisArg = arguments[1];
      for (var i = 0; i < len; i++) {
        if (!callbackfn.call(thisArg, t._getter(i), i, t))
          return false;
      }
      return true;
    }});

    // %TypedArray%.prototype.fill (value, start = 0, end = this.length )
    Object.defineProperty($TypedArray$.prototype, 'fill', {value: function(value) {
      var start = arguments[1],
          end = arguments[2];

      var o = ToObject(this);
      var lenVal = o.length;
      var len = ToUint32(lenVal);
      len = max(len, 0);
      var relativeStart = ToInt32(start);
      var k;
      if (relativeStart < 0)
        k = max((len + relativeStart), 0);
      else
        k = min(relativeStart, len);
      var relativeEnd;
      if (end === undefined)
        relativeEnd = len;
      else
        relativeEnd = ToInt32(end);
      var final;
      if (relativeEnd < 0)
        final = max((len + relativeEnd), 0);
      else
        final = min(relativeEnd, len);
      while (k < final) {
        o._setter(k, value);
        k += 1;
      }
      return o;
    }});

    // %TypedArray%.prototype.filter ( callbackfn, thisArg = undefined )
    Object.defineProperty($TypedArray$.prototype, 'filter', {value: function(callbackfn) {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      if (!IsCallable(callbackfn)) throw TypeError();
      var res = [];
      var thisp = arguments[1];
      for (var i = 0; i < len; i++) {
        var val = t._getter(i); // in case fun mutates this
        if (callbackfn.call(thisp, val, i, t))
          res.push(val);
      }
      return new this.constructor(res);
    }});

    // %TypedArray%.prototype.find (predicate, thisArg = undefined)
    Object.defineProperty($TypedArray$.prototype, 'find', {value: function(predicate) {
      var o = ToObject(this);
      var lenValue = o.length;
      var len = ToUint32(lenValue);
      if (!IsCallable(predicate)) throw TypeError();
      var t = arguments.length > 1 ? arguments[1] : undefined;
      var k = 0;
      while (k < len) {
        var kValue = o._getter(k);
        var testResult = predicate.call(t, kValue, k, o);
        if (Boolean(testResult))
          return kValue;
        ++k;
      }
      return undefined;
    }});

    // %TypedArray%.prototype.findIndex ( predicate, thisArg = undefined )
    Object.defineProperty($TypedArray$.prototype, 'findIndex', {value: function(predicate) {
      var o = ToObject(this);
      var lenValue = o.length;
      var len = ToUint32(lenValue);
      if (!IsCallable(predicate)) throw TypeError();
      var t = arguments.length > 1 ? arguments[1] : undefined;
      var k = 0;
      while (k < len) {
        var kValue = o._getter(k);
        var testResult = predicate.call(t, kValue, k, o);
        if (Boolean(testResult))
          return k;
        ++k;
      }
      return -1;
    }});

    // %TypedArray%.prototype.forEach ( callbackfn, thisArg = undefined )
    Object.defineProperty($TypedArray$.prototype, 'forEach', {value: function(callbackfn) {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      if (!IsCallable(callbackfn)) throw TypeError();
      var thisp = arguments[1];
      for (var i = 0; i < len; i++)
        callbackfn.call(thisp, t._getter(i), i, t);
    }});

    // %TypedArray%.prototype.indexOf (searchElement, fromIndex = 0 )
    Object.defineProperty($TypedArray$.prototype, 'indexOf', {value: function(searchElement) {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      if (len === 0) return -1;
      var n = 0;
      if (arguments.length > 0) {
        n = Number(arguments[1]);
        if (n !== n) {
          n = 0;
        } else if (n !== 0 && n !== (1 / 0) && n !== -(1 / 0)) {
          n = (n > 0 || -1) * floor(abs(n));
        }
      }
      if (n >= len) return -1;
      var k = n >= 0 ? n : max(len - abs(n), 0);
      for (; k < len; k++) {
        if (t._getter(k) === searchElement) {
          return k;
        }
      }
      return -1;
    }});

    // %TypedArray%.prototype.join ( separator )
    Object.defineProperty($TypedArray$.prototype, 'join', {value: function(separator) {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      var tmp = Array(len);
      for (var i = 0; i < len; ++i)
        tmp[i] = t._getter(i);
      return tmp.join(separator === undefined ? ',' : separator); // Hack for IE7
    }});

    // %TypedArray%.prototype.keys ( )
    // -- defined in es6.js to shim browsers w/ native TypedArrays

    // %TypedArray%.prototype.lastIndexOf ( searchElement, fromIndex = this.length-1 )
    Object.defineProperty($TypedArray$.prototype, 'lastIndexOf', {value: function(searchElement) {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      if (len === 0) return -1;
      var n = len;
      if (arguments.length > 1) {
        n = Number(arguments[1]);
        if (n !== n) {
          n = 0;
        } else if (n !== 0 && n !== (1 / 0) && n !== -(1 / 0)) {
          n = (n > 0 || -1) * floor(abs(n));
        }
      }
      var k = n >= 0 ? min(n, len - 1) : len - abs(n);
      for (; k >= 0; k--) {
        if (t._getter(k) === searchElement)
          return k;
      }
      return -1;
    }});

    // get %TypedArray%.prototype.length
    // -- applied directly to the object in the constructor

    // %TypedArray%.prototype.map ( callbackfn, thisArg = undefined )
    Object.defineProperty($TypedArray$.prototype, 'map', {value: function(callbackfn) {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      if (!IsCallable(callbackfn)) throw TypeError();
      var res = []; res.length = len;
      var thisp = arguments[1];
      for (var i = 0; i < len; i++)
        res[i] = callbackfn.call(thisp, t._getter(i), i, t);
      return new this.constructor(res);
    }});

    // %TypedArray%.prototype.reduce ( callbackfn [, initialValue] )
    Object.defineProperty($TypedArray$.prototype, 'reduce', {value: function(callbackfn) {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      if (!IsCallable(callbackfn)) throw TypeError();
      // no value to return if no initial value and an empty array
      if (len === 0 && arguments.length === 1) throw TypeError();
      var k = 0;
      var accumulator;
      if (arguments.length >= 2) {
        accumulator = arguments[1];
      } else {
        accumulator = t._getter(k++);
      }
      while (k < len) {
        accumulator = callbackfn.call(undefined, accumulator, t._getter(k), k, t);
        k++;
      }
      return accumulator;
    }});

    // %TypedArray%.prototype.reduceRight ( callbackfn [, initialValue] )
    Object.defineProperty($TypedArray$.prototype, 'reduceRight', {value: function(callbackfn) {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      if (!IsCallable(callbackfn)) throw TypeError();
      // no value to return if no initial value, empty array
      if (len === 0 && arguments.length === 1) throw TypeError();
      var k = len - 1;
      var accumulator;
      if (arguments.length >= 2) {
        accumulator = arguments[1];
      } else {
        accumulator = t._getter(k--);
      }
      while (k >= 0) {
        accumulator = callbackfn.call(undefined, accumulator, t._getter(k), k, t);
        k--;
      }
      return accumulator;
    }});

    // %TypedArray%.prototype.reverse ( )
    Object.defineProperty($TypedArray$.prototype, 'reverse', {value: function() {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      var half = floor(len / 2);
      for (var i = 0, j = len - 1; i < half; ++i, --j) {
        var tmp = t._getter(i);
        t._setter(i, t._getter(j));
        t._setter(j, tmp);
      }
      return t;
    }});

    // %TypedArray%.prototype.set(array, offset = 0 )
    // %TypedArray%.prototype.set(typedArray, offset = 0 )
    // WebIDL: void set(TypedArray array, optional unsigned long offset);
    // WebIDL: void set(sequence<type> array, optional unsigned long offset);
    Object.defineProperty($TypedArray$.prototype, 'set', {value: function(index, value) {
      if (arguments.length < 1) throw SyntaxError('Not enough arguments');
      var array, sequence, offset, len,
          i, s, d,
          byteOffset, byteLength, tmp;

      if (typeof arguments[0] === 'object' && arguments[0].constructor === this.constructor) {
        // void set(TypedArray array, optional unsigned long offset);
        array = arguments[0];
        offset = ToUint32(arguments[1]);

        if (offset + array.length > this.length) {
          throw RangeError('Offset plus length of array is out of range');
        }

        byteOffset = this.byteOffset + offset * this.BYTES_PER_ELEMENT;
        byteLength = array.length * this.BYTES_PER_ELEMENT;

        if (array.buffer === this.buffer) {
          tmp = [];
          for (i = 0, s = array.byteOffset; i < byteLength; i += 1, s += 1) {
            tmp[i] = array.buffer._bytes[s];
          }
          for (i = 0, d = byteOffset; i < byteLength; i += 1, d += 1) {
            this.buffer._bytes[d] = tmp[i];
          }
        } else {
          for (i = 0, s = array.byteOffset, d = byteOffset;
               i < byteLength; i += 1, s += 1, d += 1) {
            this.buffer._bytes[d] = array.buffer._bytes[s];
          }
        }
      } else if (typeof arguments[0] === 'object' && typeof arguments[0].length !== 'undefined') {
        // void set(sequence<type> array, optional unsigned long offset);
        sequence = arguments[0];
        len = ToUint32(sequence.length);
        offset = ToUint32(arguments[1]);

        if (offset + len > this.length) {
          throw RangeError('Offset plus length of array is out of range');
        }

        for (i = 0; i < len; i += 1) {
          s = sequence[i];
          this._setter(offset + i, Number(s));
        }
      } else {
        throw TypeError('Unexpected argument type(s)');
      }
    }});

    // %TypedArray%.prototype.slice ( start, end )
    Object.defineProperty($TypedArray$.prototype, 'slice', {value: function(start, end) {
      var o = ToObject(this);
      var lenVal = o.length;
      var len = ToUint32(lenVal);
      var relativeStart = ToInt32(start);
      var k = (relativeStart < 0) ? max(len + relativeStart, 0) : min(relativeStart, len);
      var relativeEnd = (end === undefined) ? len : ToInt32(end);
      var final = (relativeEnd < 0) ? max(len + relativeEnd, 0) : min(relativeEnd, len);
      var count = final - k;
      var c = o.constructor;
      var a = new c(count);
      var n = 0;
      while (k < final) {
        var kValue = o._getter(k);
        a._setter(n, kValue);
        ++k;
        ++n;
      }
      return a;
    }});

    // %TypedArray%.prototype.some ( callbackfn, thisArg = undefined )
    Object.defineProperty($TypedArray$.prototype, 'some', {value: function(callbackfn) {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      if (!IsCallable(callbackfn)) throw TypeError();
      var thisp = arguments[1];
      for (var i = 0; i < len; i++) {
        if (callbackfn.call(thisp, t._getter(i), i, t)) {
          return true;
        }
      }
      return false;
    }});

    // %TypedArray%.prototype.sort ( comparefn )
    Object.defineProperty($TypedArray$.prototype, 'sort', {value: function(comparefn) {
      if (this === undefined || this === null) throw TypeError();
      var t = Object(this);
      var len = ToUint32(t.length);
      var tmp = Array(len);
      for (var i = 0; i < len; ++i)
        tmp[i] = t._getter(i);
      function sortCompare(x, y) {
        if (x !== x && y !== y) return +0;
        if (x !== x) return 1;
        if (y !== y) return -1;
        if (comparefn !== undefined) {
          return comparefn(x, y);
        }
        if (x < y) return -1;
        if (x > y) return 1;
        return +0;
      }
      tmp.sort(sortCompare);
      for (i = 0; i < len; ++i)
        t._setter(i, tmp[i]);
      return t;
    }});

    // %TypedArray%.prototype.subarray(begin = 0, end = this.length )
    // WebIDL: TypedArray subarray(long begin, optional long end);
    Object.defineProperty($TypedArray$.prototype, 'subarray', {value: function(start, end) {
      function clamp(v, min, max) { return v < min ? min : v > max ? max : v; }

      start = ToInt32(start);
      end = ToInt32(end);

      if (arguments.length < 1) { start = 0; }
      if (arguments.length < 2) { end = this.length; }

      if (start < 0) { start = this.length + start; }
      if (end < 0) { end = this.length + end; }

      start = clamp(start, 0, this.length);
      end = clamp(end, 0, this.length);

      var len = end - start;
      if (len < 0) {
        len = 0;
      }

      return new this.constructor(
        this.buffer, this.byteOffset + start * this.BYTES_PER_ELEMENT, len);
    }});

    // %TypedArray%.prototype.toLocaleString ( )
    // %TypedArray%.prototype.toString ( )
    // %TypedArray%.prototype.values ( )
    // %TypedArray%.prototype [ @@iterator ] ( )
    // get %TypedArray%.prototype [ @@toStringTag ]
    // -- defined in es6.js to shim browsers w/ native TypedArrays

    function makeTypedArray(elementSize, pack, unpack) {
      // Each TypedArray type requires a distinct constructor instance with
      // identical logic, which this produces.
      var TypedArray = function() {
        Object.defineProperty(this, 'constructor', {value: TypedArray});
        $TypedArray$.apply(this, arguments);
        makeArrayAccessors(this);
      };
      if ('__proto__' in TypedArray) {
        TypedArray.__proto__ = $TypedArray$;
      } else {
        TypedArray.from = $TypedArray$.from;
        TypedArray.of = $TypedArray$.of;
      }

      TypedArray.BYTES_PER_ELEMENT = elementSize;

      var TypedArrayPrototype = function() {};
      TypedArrayPrototype.prototype = $TypedArrayPrototype$;

      TypedArray.prototype = new TypedArrayPrototype();

      Object.defineProperty(TypedArray.prototype, 'BYTES_PER_ELEMENT', {value: elementSize});
      Object.defineProperty(TypedArray.prototype, '_pack', {value: pack});
      Object.defineProperty(TypedArray.prototype, '_unpack', {value: unpack});

      return TypedArray;
    }

    var Int8Array = makeTypedArray(1, packI8, unpackI8);
    var Uint8Array = makeTypedArray(1, packU8, unpackU8);
    var Uint8ClampedArray = makeTypedArray(1, packU8Clamped, unpackU8);
    var Int16Array = makeTypedArray(2, packI16, unpackI16);
    var Uint16Array = makeTypedArray(2, packU16, unpackU16);
    var Int32Array = makeTypedArray(4, packI32, unpackI32);
    var Uint32Array = makeTypedArray(4, packU32, unpackU32);
    var Float32Array = makeTypedArray(4, packF32, unpackF32);
    var Float64Array = makeTypedArray(8, packF64, unpackF64);

    global.Int8Array = global.Int8Array || Int8Array;
    global.Uint8Array = global.Uint8Array || Uint8Array;
    global.Uint8ClampedArray = global.Uint8ClampedArray || Uint8ClampedArray;
    global.Int16Array = global.Int16Array || Int16Array;
    global.Uint16Array = global.Uint16Array || Uint16Array;
    global.Int32Array = global.Int32Array || Int32Array;
    global.Uint32Array = global.Uint32Array || Uint32Array;
    global.Float32Array = global.Float32Array || Float32Array;
    global.Float64Array = global.Float64Array || Float64Array;
  }());

  //
  // 6 The DataView View Type
  //

  (function() {
    function r(array, index) {
      return IsCallable(array.get) ? array.get(index) : array[index];
    }

    var IS_BIG_ENDIAN = (function() {
      var u16array = new Uint16Array([0x1234]),
          u8array = new Uint8Array(u16array.buffer);
      return r(u8array, 0) === 0x12;
    }());

    // DataView(buffer, byteOffset=0, byteLength=undefined)
    // WebIDL: Constructor(ArrayBuffer buffer,
    //                     optional unsigned long byteOffset,
    //                     optional unsigned long byteLength)
    function DataView(buffer, byteOffset, byteLength) {
      if (!(buffer instanceof ArrayBuffer || Class(buffer) === 'ArrayBuffer')) throw TypeError();

      byteOffset = ToUint32(byteOffset);
      if (byteOffset > buffer.byteLength)
        throw RangeError('byteOffset out of range');

      if (byteLength === undefined)
        byteLength = buffer.byteLength - byteOffset;
      else
        byteLength = ToUint32(byteLength);

      if ((byteOffset + byteLength) > buffer.byteLength)
        throw RangeError('byteOffset and length reference an area beyond the end of the buffer');

      Object.defineProperty(this, 'buffer', {value: buffer});
      Object.defineProperty(this, 'byteLength', {value: byteLength});
      Object.defineProperty(this, 'byteOffset', {value: byteOffset});
    };

    // get DataView.prototype.buffer
    // get DataView.prototype.byteLength
    // get DataView.prototype.byteOffset
    // -- applied directly to instances by the constructor

    function makeGetter(arrayType) {
      return function GetViewValue(byteOffset, littleEndian) {
        byteOffset = ToUint32(byteOffset);

        if (byteOffset + arrayType.BYTES_PER_ELEMENT > this.byteLength)
          throw RangeError('Array index out of range');

        byteOffset += this.byteOffset;

        var uint8Array = new Uint8Array(this.buffer, byteOffset, arrayType.BYTES_PER_ELEMENT),
            bytes = [];
        for (var i = 0; i < arrayType.BYTES_PER_ELEMENT; i += 1)
          bytes.push(r(uint8Array, i));

        if (Boolean(littleEndian) === Boolean(IS_BIG_ENDIAN))
          bytes.reverse();

        return r(new arrayType(new Uint8Array(bytes).buffer), 0);
      };
    }

    Object.defineProperty(DataView.prototype, 'getUint8', {value: makeGetter(Uint8Array)});
    Object.defineProperty(DataView.prototype, 'getInt8', {value: makeGetter(Int8Array)});
    Object.defineProperty(DataView.prototype, 'getUint16', {value: makeGetter(Uint16Array)});
    Object.defineProperty(DataView.prototype, 'getInt16', {value: makeGetter(Int16Array)});
    Object.defineProperty(DataView.prototype, 'getUint32', {value: makeGetter(Uint32Array)});
    Object.defineProperty(DataView.prototype, 'getInt32', {value: makeGetter(Int32Array)});
    Object.defineProperty(DataView.prototype, 'getFloat32', {value: makeGetter(Float32Array)});
    Object.defineProperty(DataView.prototype, 'getFloat64', {value: makeGetter(Float64Array)});

    function makeSetter(arrayType) {
      return function SetViewValue(byteOffset, value, littleEndian) {
        byteOffset = ToUint32(byteOffset);
        if (byteOffset + arrayType.BYTES_PER_ELEMENT > this.byteLength)
          throw RangeError('Array index out of range');

        // Get bytes
        var typeArray = new arrayType([value]),
            byteArray = new Uint8Array(typeArray.buffer),
            bytes = [], i, byteView;

        for (i = 0; i < arrayType.BYTES_PER_ELEMENT; i += 1)
          bytes.push(r(byteArray, i));

        // Flip if necessary
        if (Boolean(littleEndian) === Boolean(IS_BIG_ENDIAN))
          bytes.reverse();

        // Write them
        byteView = new Uint8Array(this.buffer, byteOffset, arrayType.BYTES_PER_ELEMENT);
        byteView.set(bytes);
      };
    }

    Object.defineProperty(DataView.prototype, 'setUint8', {value: makeSetter(Uint8Array)});
    Object.defineProperty(DataView.prototype, 'setInt8', {value: makeSetter(Int8Array)});
    Object.defineProperty(DataView.prototype, 'setUint16', {value: makeSetter(Uint16Array)});
    Object.defineProperty(DataView.prototype, 'setInt16', {value: makeSetter(Int16Array)});
    Object.defineProperty(DataView.prototype, 'setUint32', {value: makeSetter(Uint32Array)});
    Object.defineProperty(DataView.prototype, 'setInt32', {value: makeSetter(Int32Array)});
    Object.defineProperty(DataView.prototype, 'setFloat32', {value: makeSetter(Float32Array)});
    Object.defineProperty(DataView.prototype, 'setFloat64', {value: makeSetter(Float64Array)});

    global.DataView = global.DataView || DataView;

  }());

}(self));
if (!("defineProperty"in Object&&function(){try{var e={}
return Object.defineProperty(e,"test",{value:42}),!0}catch(t){return!1}}()
)) {

// Object.defineProperty
(function (nativeDefineProperty) {

	var supportsAccessors = Object.prototype.hasOwnProperty.call(Object.prototype, '__defineGetter__');
	var ERR_ACCESSORS_NOT_SUPPORTED = 'Getters & setters cannot be defined on this javascript engine';
	var ERR_VALUE_ACCESSORS = 'A property cannot both have accessors and be writable or have a value';

	// Polyfill.io - This does not use CreateMethodProperty because our CreateMethodProperty function uses Object.defineProperty.
	Object.defineProperty = function defineProperty(object, property, descriptor) {

		// Where native support exists, assume it
		if (nativeDefineProperty && (object === window || object === document || object === Element.prototype || object instanceof Element)) {
			return nativeDefineProperty(object, property, descriptor);
		}

		if (object === null || !(object instanceof Object || typeof object === 'object')) {
			throw new TypeError('Object.defineProperty called on non-object');
		}

		if (!(descriptor instanceof Object)) {
			throw new TypeError('Property description must be an object');
		}

		var propertyString = String(property);
		var hasValueOrWritable = 'value' in descriptor || 'writable' in descriptor;
		var getterType = 'get' in descriptor && typeof descriptor.get;
		var setterType = 'set' in descriptor && typeof descriptor.set;

		// handle descriptor.get
		if (getterType) {
			if (getterType === undefined) {
				return object;
			}
			if (getterType !== 'function') {
				throw new TypeError('Getter must be a function');
			}
			if (!supportsAccessors) {
				throw new TypeError(ERR_ACCESSORS_NOT_SUPPORTED);
			}
			if (hasValueOrWritable) {
				throw new TypeError(ERR_VALUE_ACCESSORS);
			}
			Object.__defineGetter__.call(object, propertyString, descriptor.get);
		} else {
			object[propertyString] = descriptor.value;
		}

		// handle descriptor.set
		if (setterType) {
			if (setterType === undefined) {
				return object;
			}
			if (setterType !== 'function') {
				throw new TypeError('Setter must be a function');
			}
			if (!supportsAccessors) {
				throw new TypeError(ERR_ACCESSORS_NOT_SUPPORTED);
			}
			if (hasValueOrWritable) {
				throw new TypeError(ERR_VALUE_ACCESSORS);
			}
			Object.__defineSetter__.call(object, propertyString, descriptor.set);
		}

		// OK to define value unconditionally - if a getter has been specified as well, an error would be thrown above
		if ('value' in descriptor) {
			object[propertyString] = descriptor.value;
		}

		return object;
	};
}(Object.defineProperty));

}


// _ESAbstract.CreateDataProperty
// 7.3.4. CreateDataProperty ( O, P, V )
// NOTE
// This abstract operation creates a property whose attributes are set to the same defaults used for properties created by the ECMAScript language assignment operator.
// Normally, the property will not already exist. If it does exist and is not configurable or if O is not extensible, [[DefineOwnProperty]] will return false.
function CreateDataProperty(O, P, V) { // eslint-disable-line no-unused-vars
	// 1. Assert: Type(O) is Object.
	// 2. Assert: IsPropertyKey(P) is true.
	// 3. Let newDesc be the PropertyDescriptor{ [[Value]]: V, [[Writable]]: true, [[Enumerable]]: true, [[Configurable]]: true }.
	var newDesc = {
		value: V,
		writable: true,
		enumerable: true,
		configurable: true
	};
	// 4. Return ? O.[[DefineOwnProperty]](P, newDesc).
	try {
		Object.defineProperty(O, P, newDesc);
		return true;
	} catch (e) {
		return false;
	}
}

// _ESAbstract.CreateDataPropertyOrThrow
/* global CreateDataProperty */
// 7.3.6. CreateDataPropertyOrThrow ( O, P, V )
function CreateDataPropertyOrThrow(O, P, V) { // eslint-disable-line no-unused-vars
	// 1. Assert: Type(O) is Object.
	// 2. Assert: IsPropertyKey(P) is true.
	// 3. Let success be ? CreateDataProperty(O, P, V).
	var success = CreateDataProperty(O, P, V);
	// 4. If success is false, throw a TypeError exception.
	if (!success) {
		throw new TypeError('Cannot assign value `' + Object.prototype.toString.call(V) + '` to property `' + Object.prototype.toString.call(P) + '` on object `' + Object.prototype.toString.call(O) + '`');
	}
	// 5. Return success.
	return success;
}

// _ESAbstract.CreateIterResultObject
/* global Type, CreateDataProperty */
// 7.4.7. CreateIterResultObject ( value, done )
function CreateIterResultObject(value, done) { // eslint-disable-line no-unused-vars
	// 1. Assert: Type(done) is Boolean.
	if (Type(done) !== 'boolean') {
		throw new Error();
	}
	// 2. Let obj be ObjectCreate(%ObjectPrototype%).
	var obj = {};
	// 3. Perform CreateDataProperty(obj, "value", value).
	CreateDataProperty(obj, "value", value);
	// 4. Perform CreateDataProperty(obj, "done", done).
	CreateDataProperty(obj, "done", done);
	// 5. Return obj.
	return obj;
}

// _ESAbstract.CreateMethodProperty
// 7.3.5. CreateMethodProperty ( O, P, V )
function CreateMethodProperty(O, P, V) { // eslint-disable-line no-unused-vars
	// 1. Assert: Type(O) is Object.
	// 2. Assert: IsPropertyKey(P) is true.
	// 3. Let newDesc be the PropertyDescriptor{[[Value]]: V, [[Writable]]: true, [[Enumerable]]: false, [[Configurable]]: true}.
	var newDesc = {
		value: V,
		writable: true,
		enumerable: false,
		configurable: true
	};
	// 4. Return ? O.[[DefineOwnProperty]](P, newDesc).
	Object.defineProperty(O, P, newDesc);
}
if (!("isArray"in Array
)) {

// Array.isArray
/* global CreateMethodProperty, IsArray */
// 22.1.2.2. Array.isArray ( arg )
CreateMethodProperty(Array, 'isArray', function isArray(arg) {
	// 1. Return ? IsArray(arg).
	return IsArray(arg);
});

}

if (!("copyWithin"in Array.prototype&&function(){try{var t=function n(){}
t.prototype[0]="foo"
var o=new t
o[1]=1,o[2]=2,o.length=3
var r=Array.prototype.copyWithin.call(o,1,0)
return!(!r[0]||Object.prototype.hasOwnProperty.call(r,"0")||!Object.prototype.hasOwnProperty.call(r,"1")||"foo"!==r[0]||"foo"!==r[1]||1!==r[2]||3!==r.length)}catch(e){return!1}}()
)) {

// Array.prototype.copyWithin
/* global CreateMethodProperty, HasProperty, ToInteger */
// 22.1.3.3 Array.prototype.copyWithin ( target, start [ , end ] )
CreateMethodProperty(Array.prototype, 'copyWithin', function copyWithin(target, start /* [ , end ] */ ) {
	'use strict';
	var end = arguments[2];

	// 22.1.3.3.1 Let O be ? ToObject(this value).
	if (this === null || this === undefined) {
		throw new TypeError('Cannot call method on ' + this);
	}

	var o = Object(this);

	// 22.1.3.3.2 Let len be ? ToLength(? Get(O, "length")).
	var len = ToInteger(o.length);
	if (len <= 0) {
		len = 0;
	}
	if (len === Infinity) {
		len = Math.pow(2, 53) - 1;
	} else {
		len = Math.min(len, Math.pow(2, 53) - 1);
	}
	len = Math.max(len, 0);

	// 22.1.3.3.3 Let relativeTarget be ? ToInteger(target).
	var relativeTarget = ToInteger(target);

	// 22.1.3.3.4 If relativeTarget < 0, let to be max((len + relativeTarget), 0); else let to be min(relativeTarget, len).
	var to;
	if (relativeTarget < 0) {
		to = Math.max(len + relativeTarget, 0);
	} else {
		to = Math.min(relativeTarget, len);
	}

	// 22.1.3.3.5 Let relativeStart be ? ToInteger(start).
	var relativeStart = ToInteger(start);

	// 22.1.3.3.6 If relativeStart < 0, let from be max((len + relativeStart), 0); else let from be min(relativeStart, len).
	var from;
	if (relativeStart < 0) {
		from = Math.max(len + relativeStart, 0);
	} else {
		from = Math.min(relativeStart, len);
	}

	// 22.1.3.3.7 If end is undefined, let relativeEnd be len; else let relativeEnd be ? ToInteger(end).
	var relativeEnd;
	if (end === undefined) {
		relativeEnd = len;
	} else {
		relativeEnd = ToInteger(end);
	}

	// 22.1.3.3.8 If relativeEnd < 0, let final be max((len + relativeEnd), 0); else let final be min(relativeEnd, len).
	var final;
	if (relativeEnd < 0) {
		final = Math.max(len + relativeEnd, 0);
	} else {
		final = Math.min(relativeEnd, len);
	}

	// 22.1.3.3.9 Let count be min(final-from, len-to).
	var count = Math.min(final - from, len - to);

	// 22.1.3.3.10 If from<to and to<from+count, then
	var direction;
	if (from < to && to < from + count) {
		// 22.1.3.3.10.a Let direction be -1.
		direction = -1;

		// 22.1.3.3.10.b Let from be from + count - 1.
		from = from + count - 1;

		// 22.1.3.3.10.c Let to be to + count - 1.
		to = to + count - 1;
	} else {
		// 22.1.3.3.11 Else,
		// 22.1.3.3.11.a Let direction be 1.
		direction = 1;
	}

	// 22.1.3.3.12 Repeat, while count > 0
	while (count > 0) {
		// 22.1.3.3.12.a Let fromKey be ! ToString(from).
		var fromKey = String(from);
		// 22.1.3.3.12.b Let toKey be ! ToString(to).
		var toKey = String(to);
		// 22.1.3.3.12.c Let fromPresent be ? HasProperty(O, fromKey).
		var fromPresent = HasProperty(o, fromKey);
		// 22.1.3.3.12.d If fromPresent is true, then
		if (fromPresent) {
			// 22.1.3.3.12.d.i Let fromVal be ? Get(O, fromKey).
			var fromVal = o[fromKey];
			// 22.1.3.3.12.d.ii Perform ? Set(O, toKey, fromVal, true).
			o[toKey] = fromVal;
		} else {
			// 22.1.3.3.12.e Else fromPresent is false,
			// 22.1.3.3.12.e.i Perform ? DeletePropertyOrThrow(O, toKey).
			delete o[toKey];
		}
		// 22.1.3.3.12.f Let from be from + direction.
		from = from + direction;
		// 22.1.3.3.12.g Let to be to + direction.
		to = to + direction;
		// 22.1.3.3.12.h Let count be count - 1.
		count = count - 1;
	}
	// 22.1.3.3.13 Return O.
	return o;
});

}

if (!("fill"in Array.prototype
)) {

// Array.prototype.fill
/* global CreateMethodProperty, Get, ToInteger, ToLength, ToObject, ToString */
// 22.1.3.6. Array.prototype.fill ( value [ , start [ , end ] ] )
CreateMethodProperty(Array.prototype, 'fill', function fill(value /* [ , start [ , end ] ] */) {
	var start = arguments[1];
	var end = arguments[2];
	// 1. Let O be ? ToObject(this value).
	var O = ToObject(this);
	// 2. Let len be ? ToLength(? Get(O, "length")).
	var len = ToLength(Get(O, "length"));
	// 3. Let relativeStart be ? ToInteger(start).
	var relativeStart = ToInteger(start);
	// 4. If relativeStart < 0, let k be max((len + relativeStart), 0); else let k be min(relativeStart, len)
	var k = relativeStart < 0 ? Math.max((len + relativeStart), 0) : Math.min(relativeStart, len);
	// 5. If end is undefined, let relativeEnd be len; else let relativeEnd be ? ToInteger(end).
	var relativeEnd = end === undefined ? len : ToInteger(end);
	// 6. If relativeEnd < 0, let final be max((len + relativeEnd), 0); else let final be min(relativeEnd, len).
	var final = relativeEnd < 0 ? Math.max((len + relativeEnd), 0) : Math.min(relativeEnd, len);
	// 7. Repeat, while k < final
	while (k < final) {
		// a. Let Pk be ! ToString(k).
		var Pk = ToString(k);
		// b. Perform ? Set(O, Pk, value, true).
		O[Pk] = value;
		// c. Increase k by 1.
		k = k + 1;
	}
	// 8. Return O.
	return O;
});

}

if (!("find"in Array.prototype
)) {

// Array.prototype.find
/* global Call, CreateMethodProperty, Get, IsCallable, ToBoolean, ToLength, ToObject, ToString */
// 22.1.3.8 Array.prototype.find ( predicate [ , thisArg ] )
CreateMethodProperty(Array.prototype, 'find', function find( predicate /* [ , thisArg ] */) {
	// 1. Let O be ? ToObject(this value).
	var O = ToObject(this);
	// 2. Let len be ? ToLength(? Get(O, "length")).
	var len = ToLength(Get(O, "length"));
	// 3. If IsCallable(predicate) is false, throw a TypeError exception.
	if (IsCallable(predicate) === false) {
		throw new TypeError(predicate + ' is not a function');
	}
	// 4. If thisArg is present, let T be thisArg; else let T be undefined.
	var T = arguments.length > 1 ? arguments[1] : undefined;
	// 5. Let k be 0.
	var k = 0;
	// 6. Repeat, while k < len
	while (k < len) {
		// a. Let Pk be ! ToString(k).
		var Pk = ToString(k);
		// b. Let kValue be ? Get(O, Pk).
		var kValue = Get(O, Pk);
		// c. Let testResult be ToBoolean(? Call(predicate, T, « kValue, k, O »)).
		var testResult = ToBoolean(Call(predicate, T, [kValue, k, O ]));
		// d. If testResult is true, return kValue.
		if (testResult) {
			return kValue;
		}
		// e. Increase k by 1.
		k = k + 1;
	}
	// 7. Return undefined.
	return undefined;
});

}

if (!("findIndex"in Array.prototype
)) {

// Array.prototype.findIndex
/* global Call, CreateMethodProperty, Get, IsCallable, ToBoolean, ToLength, ToObject, ToString */
// 22.1.3.9. Array.prototype.findIndex ( predicate [ , thisArg ] )
CreateMethodProperty(Array.prototype, 'findIndex', function findIndex(predicate /* [ , thisArg ] */) {
	// 1. Let O be ? ToObject(this value).
	var O = ToObject(this);
	// 2. Let len be ? ToLength(? Get(O, "length")).
	var len = ToLength(Get(O, "length"));
	// 3. If IsCallable(predicate) is false, throw a TypeError exception.
	if (IsCallable(predicate) === false) {
		throw new TypeError(predicate + ' is not a function');
	}
	// 4. If thisArg is present, let T be thisArg; else let T be undefined.
	var T = arguments.length > 1 ? arguments[1] : undefined;
	// 5. Let k be 0.
	var k = 0;
	// 6. Repeat, while k < len
	while (k < len) {
		// a. Let Pk be ! ToString(k).
		var Pk = ToString(k);
		// b. Let kValue be ? Get(O, Pk).
		var kValue = Get(O, Pk);
		// c. Let testResult be ToBoolean(? Call(predicate, T, « kValue, k, O »)).
		var testResult = ToBoolean(Call(predicate, T, [kValue, k, O]));
		// d. If testResult is true, return k.
		if (testResult) {
			return k;
		}
		// e. Increase k by 1.
		k = k + 1;
	}
	// 7. Return -1.
	return -1;
});

}

if (!("forEach"in Array.prototype
)) {

// Array.prototype.forEach
/* global Call, CreateMethodProperty, Get, HasProperty, IsCallable, ToLength, ToObject, ToString */
// 22.1.3.10. Array.prototype.forEach ( callbackfn [ , thisArg ] )
CreateMethodProperty(Array.prototype, 'forEach', function forEach(callbackfn /* [ , thisArg ] */) {
	// 1. Let O be ? ToObject(this value).
	var O = ToObject(this);
	// Polyfill.io - If O is a String object, split it into an array in order to iterate correctly.
	// We will use arrayLike in place of O when we are iterating through the list.
	var arraylike = O instanceof String ? O.split('') : O;
	// 2. Let len be ? ToLength(? Get(O, "length")).
	var len = ToLength(Get(O, "length"));
	// 3. If IsCallable(callbackfn) is false, throw a TypeError exception.
	if (IsCallable(callbackfn) === false) {
		throw new TypeError(callbackfn + ' is not a function');
	}
	// 4. If thisArg is present, let T be thisArg; else let T be undefined.
	var T = arguments.length > 1 ? arguments[1] : undefined;
	// 5. Let k be 0.
	var k = 0;
	// 6. Repeat, while k < len
	while (k < len) {
		// a. Let Pk be ! ToString(k).
		var Pk = ToString(k);
		// b. Let kPresent be ? HasProperty(O, Pk).
		var kPresent = HasProperty(arraylike, Pk);
		// c. If kPresent is true, then
		if (kPresent) {
			// i. Let kValue be ? Get(O, Pk).
			var kValue = Get(arraylike, Pk);
			// ii. Perform ? Call(callbackfn, T, « kValue, k, O »).
			Call(callbackfn, T, [kValue, k, O]);
		}
		// d. Increase k by 1.
		k = k + 1;
	}
	// 7. Return undefined.
	return undefined;
});

}

if (!("includes"in Array.prototype
)) {

// Array.prototype.includes
/* global CreateMethodProperty, Get, SameValueZero, ToInteger, ToLength, ToObject, ToString */
// 22.1.3.11. Array.prototype.includes ( searchElement [ , fromIndex ] )
CreateMethodProperty(Array.prototype, 'includes', function includes(searchElement /* [ , fromIndex ] */) {
	'use strict';
	// 1. Let O be ? ToObject(this value).
	var O = ToObject(this);
	// 2. Let len be ? ToLength(? Get(O, "length")).
	var len = ToLength(Get(O, "length"));
	// 3. If len is 0, return false.
	if (len === 0) {
		return false;
	}
	// 4. Let n be ? ToInteger(fromIndex). (If fromIndex is undefined, this step produces the value 0.)
	var n = ToInteger(arguments[1]);
	// 5. If n ≥ 0, then
	if (n >= 0) {
		// a. Let k be n.
		var k = n;
		// 6. Else n < 0,
	} else {
		// a. Let k be len + n.
		k = len + n;
		// b. If k < 0, let k be 0.
		if (k < 0) {
			k = 0;
		}
	}
	// 7. Repeat, while k < len
	while (k < len) {
		// a. Let elementK be the result of ? Get(O, ! ToString(k)).
		var elementK = Get(O, ToString(k));
		// b. If SameValueZero(searchElement, elementK) is true, return true.
		if (SameValueZero(searchElement, elementK)) {
			return true;
		}
		// c. Increase k by 1.
		k = k + 1;
	}
	// 8. Return false.
	return false;
});

}

if (!("indexOf"in Array.prototype
)) {

// Array.prototype.indexOf
/* global CreateMethodProperty, Get, HasProperty, ToInteger, ToLength, ToObject, ToString */
// 22.1.3.12. Array.prototype.indexOf ( searchElement [ , fromIndex ] )
CreateMethodProperty(Array.prototype, 'indexOf', function indexOf(searchElement /* [ , fromIndex ] */) {
	// 1. Let O be ? ToObject(this value).
	var O = ToObject(this);
	// 2. Let len be ? ToLength(? Get(O, "length")).
	var len = ToLength(Get(O, "length"));
	// 3. If len is 0, return -1.
	if (len === 0) {
		return -1;
	}
	// 4. Let n be ? ToInteger(fromIndex). (If fromIndex is undefined, this step produces the value 0.)
	var n = ToInteger(arguments[1]);
	// 5. If n ≥ len, return -1.
	if (n >= len) {
		return -1;
	}
	// 6. If n ≥ 0, then
	if (n >= 0) {
		// a. If n is -0, let k be +0; else let k be n.
		var k = 1/n === -Infinity ? 0 : n;
		// 7. Else n < 0,
	} else {
		// a. Let k be len + n.
		k = len + n;
		// b. If k < 0, let k be 0.
		if (k < 0) {
			k = 0;
		}
	}
	// 8. Repeat, while k < len
	while (k < len) {
		// a. Let kPresent be ? HasProperty(O, ! ToString(k)).
		var kPresent = HasProperty(O, ToString(k));
		// b. If kPresent is true, then
		if (kPresent) {
			// i. Let elementK be ? Get(O, ! ToString(k)).
			var elementK = Get(O, ToString(k));
			// ii. Let same be the result of performing Strict Equality Comparison searchElement === elementK.
			var same = searchElement === elementK;
			// iii. If same is true, return k.
			if (same) {
				return k;
			}
		}
		// c. Increase k by 1.
		k = k + 1;
	}
	// 9. Return -1.
	return -1;
});

}

if (!("bind"in Function.prototype
)) {

// Function.prototype.bind
/* global CreateMethodProperty, IsCallable */
// 19.2.3.2. Function.prototype.bind ( thisArg, ...args )
// https://github.com/es-shims/es5-shim/blob/d6d7ff1b131c7ba14c798cafc598bb6780d37d3b/es5-shim.js#L182
CreateMethodProperty(Function.prototype, 'bind', function bind(that) { // .length is 1
	// add necessary es5-shim utilities
	var $Array = Array;
	var $Object = Object;
	var ArrayPrototype = $Array.prototype;
	var Empty = function Empty() { };
	var array_slice = ArrayPrototype.slice;
	var array_concat = ArrayPrototype.concat;
	var array_push = ArrayPrototype.push;
	var max = Math.max;
	// /add necessary es5-shim utilities

	// 1. Let Target be the this value.
	var target = this;
	// 2. If IsCallable(Target) is false, throw a TypeError exception.
	if (!IsCallable(target)) {
		throw new TypeError('Function.prototype.bind called on incompatible ' + target);
	}
	// 3. Let A be a new (possibly empty) internal list of all of the
	//   argument values provided after thisArg (arg1, arg2 etc), in order.
	// XXX slicedArgs will stand in for "A" if used
	var args = array_slice.call(arguments, 1); // for normal call
	// 4. Let F be a new native ECMAScript object.
	// 11. Set the [[Prototype]] internal property of F to the standard
	//   built-in Function prototype object as specified in 15.3.3.1.
	// 12. Set the [[Call]] internal property of F as described in
	//   15.3.4.5.1.
	// 13. Set the [[Construct]] internal property of F as described in
	//   15.3.4.5.2.
	// 14. Set the [[HasInstance]] internal property of F as described in
	//   15.3.4.5.3.
	var bound;
	var binder = function () {

		if (this instanceof bound) {
			// 15.3.4.5.2 [[Construct]]
			// When the [[Construct]] internal method of a function object,
			// F that was created using the bind function is called with a
			// list of arguments ExtraArgs, the following steps are taken:
			// 1. Let target be the value of F's [[TargetFunction]]
			//   internal property.
			// 2. If target has no [[Construct]] internal method, a
			//   TypeError exception is thrown.
			// 3. Let boundArgs be the value of F's [[BoundArgs]] internal
			//   property.
			// 4. Let args be a new list containing the same values as the
			//   list boundArgs in the same order followed by the same
			//   values as the list ExtraArgs in the same order.
			// 5. Return the result of calling the [[Construct]] internal
			//   method of target providing args as the arguments.

			var result = target.apply(
				this,
				array_concat.call(args, array_slice.call(arguments))
			);
			if ($Object(result) === result) {
				return result;
			}
			return this;

		} else {
			// 15.3.4.5.1 [[Call]]
			// When the [[Call]] internal method of a function object, F,
			// which was created using the bind function is called with a
			// this value and a list of arguments ExtraArgs, the following
			// steps are taken:
			// 1. Let boundArgs be the value of F's [[BoundArgs]] internal
			//   property.
			// 2. Let boundThis be the value of F's [[BoundThis]] internal
			//   property.
			// 3. Let target be the value of F's [[TargetFunction]] internal
			//   property.
			// 4. Let args be a new list containing the same values as the
			//   list boundArgs in the same order followed by the same
			//   values as the list ExtraArgs in the same order.
			// 5. Return the result of calling the [[Call]] internal method
			//   of target providing boundThis as the this value and
			//   providing args as the arguments.

			// equiv: target.call(this, ...boundArgs, ...args)
			return target.apply(
				that,
				array_concat.call(args, array_slice.call(arguments))
			);

		}

	};

	// 15. If the [[Class]] internal property of Target is "Function", then
	//     a. Let L be the length property of Target minus the length of A.
	//     b. Set the length own property of F to either 0 or L, whichever is
	//       larger.
	// 16. Else set the length own property of F to 0.

	var boundLength = max(0, target.length - args.length);

	// 17. Set the attributes of the length own property of F to the values
	//   specified in 15.3.5.1.
	var boundArgs = [];
	for (var i = 0; i < boundLength; i++) {
		array_push.call(boundArgs, '$' + i);
	}

	// XXX Build a dynamic function with desired amount of arguments is the only
	// way to set the length property of a function.
	// In environments where Content Security Policies enabled (Chrome extensions,
	// for ex.) all use of eval or Function costructor throws an exception.
	// However in all of these environments Function.prototype.bind exists
	// and so this code will never be executed.
	bound = Function('binder', 'return function (' + boundArgs.join(',') + '){ return binder.apply(this, arguments); }')(binder);

	if (target.prototype) {
		Empty.prototype = target.prototype;
		bound.prototype = new Empty();
		// Clean up dangling references.
		Empty.prototype = null;
	}

	// TODO
	// 18. Set the [[Extensible]] internal property of F to true.

	// TODO
	// 19. Let thrower be the [[ThrowTypeError]] function Object (13.2.3).
	// 20. Call the [[DefineOwnProperty]] internal method of F with
	//   arguments "caller", PropertyDescriptor {[[Get]]: thrower, [[Set]]:
	//   thrower, [[Enumerable]]: false, [[Configurable]]: false}, and
	//   false.
	// 21. Call the [[DefineOwnProperty]] internal method of F with
	//   arguments "arguments", PropertyDescriptor {[[Get]]: thrower,
	//   [[Set]]: thrower, [[Enumerable]]: false, [[Configurable]]: false},
	//   and false.

	// TODO
	// NOTE Function objects created using Function.prototype.bind do not
	// have a prototype property or the [[Code]], [[FormalParameters]], and
	// [[Scope]] internal properties.
	// XXX can't delete prototype in pure-js.

	// 22. Return F.
	return bound;
});

}

if (!("acosh"in Math
)) {

// Math.acosh
/* global CreateMethodProperty */
// 20.2.2.3. Math.acosh ( x )
CreateMethodProperty(Math, 'acosh', function acosh(x) {
	// If x is NaN, the result is NaN.
	if (isNaN(x)) {
		return NaN;
	}
	// If x is less than 1, the result is NaN.
	if (x < 1) {
		return NaN;
	}
	// If x is 1, the result is +0.
	if (x === 1) {
		return 0;
	}
	// If x is +∞, the result is +∞.
	if (x === Infinity) {
		return Infinity;
	}
	return Math.log(x + Math.sqrt(x * x - 1));
});

}

if (!("asinh"in Math
)) {

// Math.asinh
/* global CreateMethodProperty */
// 20.2.2.5. Math.asinh ( x )
CreateMethodProperty(Math, 'asinh', function asinh(x) {
	// If x is NaN, the result is NaN.
	if (isNaN(x)) {
		return NaN;
	}
	// If x is +0, the result is +0.
	if (x === 0 && 1/x === Infinity) {
		return 0;
	}
	// If x is -0, the result is -0.
	if (x === 0 && 1/x === -Infinity) {
		return -0;
	}
	// If x is +∞, the result is +∞.
	if (x === Infinity) {
		return Infinity;
	}
	// If x is -∞, the result is -∞.
	if (x === -Infinity) {
		return -Infinity;
	}
	return Math.log(x + Math.sqrt(x * x + 1));
});

}

if (!("atanh"in Math
)) {

// Math.atanh
/* global CreateMethodProperty */
// 20.2.2.7. Math.atanh ( x )
CreateMethodProperty(Math, 'atanh', function atanh(x) {
	// If x is NaN, the result is NaN.
	if (isNaN(x)) {
		return NaN;
	}
	// If x is less than -1, the result is NaN.
	if (x < -1) {
		return NaN;
	}
	// If x is greater than 1, the result is NaN.
	if (x > 1) {
		return NaN;
	}
	// If x is -1, the result is -∞.
	if (x === -1) {
		return -Infinity;
	}
	// If x is +1, the result is +∞.
	if (x === 1) {
		return Infinity;
	}
	// If x is +0, the result is +0.
	if (x === 0 && 1/x === Infinity) {
		return 0;
	}
	// If x is -0, the result is -0.
	if (x === 0 && 1/x === -Infinity) {
		return -0;
	}
	return Math.log((1 + x) / (1 - x)) / 2;
});

}

if (!("cbrt"in Math
)) {

// Math.cbrt
/* global CreateMethodProperty */
// 20.2.2.9. Math.cbrt ( x )
CreateMethodProperty(Math, 'cbrt', function cbrt(x) {
	// If x is NaN, the result is NaN.
	if (isNaN(x)) {
		return NaN;
	}
	// If x is +0, the result is +0.
	if (x === 0 && 1/x === Infinity) {
		return 0;
	}
	// If x is -0, the result is -0.
	if (x === 0 && 1/x === -Infinity) {
		return -0;
	}
	// If x is +∞, the result is +∞.
	if (x === Infinity) {
		return Infinity;
	}
	// If x is -∞, the result is -∞.
	if (x === -Infinity) {
		return -Infinity;
	}
	var y = Math.pow(Math.abs(x), 1 / 3);
	return x < 0 ? -y : y;
});

}

if (!("clz32"in Math
)) {

// Math.clz32
/* global CreateMethodProperty, ToUint32 */
// 20.2.2.11. Math.clz32 ( x )
CreateMethodProperty(Math, 'clz32', function clz32(x) {
	// 1. Let n be ToUint32(x).
	var n = ToUint32(x);
	// 2. Let p be the number of leading zero bits in the 32-bit binary representation of n.
	var p = n ? 32 - n.toString(2).length : 32;
	// 3. Return p.
	return p;
});

}

if (!("cosh"in Math
)) {

// Math.cosh
/* global CreateMethodProperty */
// 20.2.2.1. 3Math.cosh ( x )
CreateMethodProperty(Math, 'cosh', function cosh(x) {
	// If x is NaN, the result is NaN.
	if (isNaN(x)) {
		return NaN;
	}
	// If x is +0, the result is 1.
	if (x === 0 && 1/x === Infinity) {
		return 1;
	}
	// If x is -0, the result is 1.
	if (x === 0 && 1/x === -Infinity) {
		return 1;
	}
	// If x is +∞, the result is +∞.
	if (x === Infinity) {
		return Infinity;
	}
	// If x is -∞, the result is +∞.
	if (x === -Infinity) {
		return Infinity;
	}
	x = Math.abs(x);
	if (x > 709) {
		var y = Math.exp(0.5 * x);
		return y / 2 * y;
	}
	y = Math.exp(x);
	return (y + 1 / y) / 2;
});

}

if (!("expm1"in Math
)) {

// Math.expm1
/* global CreateMethodProperty */
// 20.2.2.15. Math.expm1 ( x )
CreateMethodProperty(Math, 'expm1', function expm1(x) {
	// If x is NaN, the result is NaN.
	if (isNaN(x)) {
		return NaN;
	}
	// If x is +0, the result is +0.
	if (x === 0 && 1/x === Infinity) {
		return 0;
	}
	// If x is -0, the result is -0.
	if (x === 0 && 1/x === -Infinity) {
		return -0;
	}
	// If x is +∞, the result is +∞.
	if (x === Infinity) {
		return Infinity;
	}
	// If x is -∞, the result is -1.
	if (x === -Infinity) {
		return -1;
	}

	if (x > -1e-6 && x < 1e-6) {
		return x + x * x / 2;
	} else {
		return Math.exp(x) - 1;
	}
});

}

if (!("fround"in Math
)) {

// Math.fround
/* global Float32Array, CreateMethodProperty */
// 20.2.2.17 Math.fround ( x )
CreateMethodProperty(Math, 'fround', function (x) {
	// 1. If x is NaN, return NaN.
	if (isNaN(x)) {
		return NaN;
	}
	// 2. If x is one of +0, -0, +∞, -∞, return x.
	if (1 / x === +Infinity || 1 / x === -Infinity || x === +Infinity || x === -Infinity) {
		return x;
	}
	// 3. Let x32 be the result of converting x to a value in IEEE 754-2008 binary32 format using roundTiesToEven.
	// 4. Let x64 be the result of converting x32 to a value in IEEE 754-2008 binary64 format.
	// 5. Return the ECMAScript Number value corresponding to x64.
	return (new Float32Array([x]))[0];
});

}

if (!("hypot"in Math
)) {

// Math.hypot
/* global CreateMethodProperty */
// 20.2.2.18. Math.hypot ( value1, value2, ...values )
CreateMethodProperty(Math, 'hypot', function hypot(value1, value2) { // eslint-disable-line no-unused-vars
	// If no arguments are passed, the result is +0.
	if (arguments.length === 0) {
		return 0;
	}
	var y = 0;
	var max = 0;
	for (var i = 0; i < arguments.length; ++i) {
		// If any argument is +∞, the result is +∞.
		if (arguments[i] === Infinity) {
			return Infinity;
		}

		// If any argument is -∞, the result is +∞.
		if (arguments[i] === -Infinity) {
			return Infinity;
		}

		// If no argument is +∞ or -∞, and any argument is NaN, the result is NaN.
		// If all arguments are either +0 or -0, the result is +0.
		// Polyfill.io - The two conditions above are handled in the math.

		var arg = Math.abs(Number(arguments[i]));
		if (arg > max) {
			y = y * Math.pow(max / arg, 2);
			max = arg;
		}
		if (arg !== 0 || max !== 0) {
			y = y + Math.pow(arg / max, 2);
		}
	}

	return max * Math.sqrt(y);
});

}

if (!("imul"in Math
)) {

// Math.imul
/* global CreateMethodProperty, ToUint32 */
// 20.2.2.19. Math.imul ( x, y )
CreateMethodProperty(Math, 'imul', function imul(x, y) {
	// 1. Let a be ToUint32(x).
	var a = ToUint32(x);
	// 2. Let b be ToUint32(y).
	var b = ToUint32(y);
	var UINT16 = 0xffff;
	var aHigh = a >>> 16 & UINT16;
	var aLow = UINT16 & a;
	var bHigh = b >>> 16 & UINT16;
	var bLow = UINT16 & b;
	// the shift by 0 fixes the sign on the high part
	// the final |0 converts the unsigned value into a signed value
	return aLow * bLow + (aHigh * bLow + aLow * bHigh << 16 >>> 0) | 0;
});

}

if (!("log10"in Math
)) {

// Math.log10
/* global CreateMethodProperty */
// 20.2.2.22. Math.log10 ( x )
CreateMethodProperty(Math, 'log10', function log10(x) {
	return Math.log(x) / Math.LN10;
});

}

if (!("log1p"in Math
)) {

// Math.log1p
/* global CreateMethodProperty */
// 20.2.2.21. Math.log1p ( x )
CreateMethodProperty(Math, 'log1p', function log1p(x) {
	x = Number(x);
	if (-1 < x && x < 1) {
		// Polyfill.io - For numbers in the range −1 < x < 1
		// Because we are using log, the precision of the result will be identical to log(1).
		// To fix this we avoid using log and use the Taylor Series expansion of log.
		// This series converges when |x| < 1. As we can not sum to infinity,
		// we instead sum the first 300 parts of the series to give a close approximation.
		// |x|<1, log(1+x) = x - x^2/2 + x^3/3 - ... + (-1)^(n-1)*x^n/n + ...
		var y = x;
		for (var i = 2; i <= 300; i++) {
			y += Math.pow((-1), (i - 1)) * Math.pow(x, i) / i;
		}
		return y;
	}

	return Math.log(1 + x);
});

}

if (!("log2"in Math
)) {

// Math.log2
/* global CreateMethodProperty */
// 20.2.2.23. Math.log2 ( x )
CreateMethodProperty(Math, 'log2', function log2(x) {
	return Math.log(x) / Math.LN2;
});

}

if (!("sign"in Math
)) {

// Math.sign
/* global CreateMethodProperty */
// 20.2.2.29. Math.sign ( x )
CreateMethodProperty(Math, 'sign', function sign(x) {
	x = Number(x);
	// If x is NaN, the result is NaN.
	if (isNaN(x)) {
		return NaN;
	}
	// If x is -0, the result is -0.
	if (1 / x === -Infinity) {
		return -0;
	}
	// If x is +0, the result is +0.
	if (1 / x === Infinity) {
		return 0;
	}
	// If x is negative and not -0, the result is -1.
	if (x < 0) {
		return -1;
	}
	// If x is positive and not +0, the result is +1.
	if (x > 0) {
		return 1;
	}
});

}

if (!("sinh"in Math
)) {

// Math.sinh
/* global CreateMethodProperty */
// 20.2.2.31. Math.sinh ( x )
CreateMethodProperty(Math, 'sinh', function sinh(x) {
	var s = (x < 0) ? -1 : 1;
	var absx = Math.abs(x);
	if (absx < 22) {
		if (absx < Math.pow(2, -28)) {
			return x;
		}
		var t = Math.exp(absx) - 1;
		if (absx < 1) {
			return (s * (2 * t - t * t / (t + 1)))/2;
		}
		return (s * (t + t / (t + 1)))/2;
	}
	if (absx < 709.7822265625) {
		return (s * Math.exp(absx))/2;
	}
	var w = Math.exp(0.5 * absx);
	t = (s * w)/2;
	return t * w;
});

}

if (!("tanh"in Math
)) {

// Math.tanh
/* global CreateMethodProperty */
// 20.2.2.34. Math.tanh ( x )
CreateMethodProperty(Math, 'tanh', function tanh(x) {
	var y;

	return x === Infinity ? 1 : x === -Infinity ? -1 : (y = Math.exp(2 * x), (y - 1) / (y + 1));
});

}

if (!("trunc"in Math
)) {

// Math.trunc
/* global CreateMethodProperty */
CreateMethodProperty(Math, 'trunc', function trunc(x) {
	return x < 0 ? Math.ceil(x) : Math.floor(x);
});

}

if (!("isFinite"in Number
)) {

// Number.isFinite
/* global CreateMethodProperty, Type */
(function () {
	var that = self;
	// 20.1.2.2. Number.isFinite ( number )
	CreateMethodProperty(Number, 'isFinite', function isFinite(number) {
		// 1. If Type(number) is not Number, return false.
		if (Type(number) !== 'number') {
			return false;
		}
		// 2. If number is NaN, +∞, or -∞, return false.
		// 3. Otherwise, return true.
		// Polyfill.io - We use isFinite as it implements steps 2 and 3.
		return that.isFinite(number);
	});
}());

}

if (!("isInteger"in Number
)) {

// Number.isInteger
/* global CreateMethodProperty, ToInteger, Type */
// 20.1.2.3. Number.isInteger ( number )
CreateMethodProperty(Number, 'isInteger', function isInteger(number) {
	// 1. If Type(number) is not Number, return false.
	if (Type(number) !== 'number') {
		return false;
	}
	// 2. If number is NaN, +∞, or -∞, return false.
	if (isNaN(number) || number === Infinity || number === -Infinity) {
		return false;
	}
	// 3. Let integer be ToInteger(number).
	var integer = ToInteger(number);
	// 4. If integer is not equal to number, return false.
	if (integer !== number) {
		return false;
	}
	// 5. Otherwise, return true.
	return true;
});

}

if (!("isNaN"in Number
)) {

// Number.isNaN
/* global CreateMethodProperty, Type */
(function () {
	var that = self;
	// 20.1.2.4. Number.isNaN ( number )
	CreateMethodProperty(Number, 'isNaN', function isNaN(number) {
		// 1. If Type(number) is not Number, return false.
		if (Type(number) !== 'number') {
			return false;
		}
		// 2. If number is NaN, return true.
		if (that.isNaN(number)) {
			return true;
		}
		// 3. Otherwise, return false.
		return false;
	});
}());

}

if (!("isSafeInteger"in Number
)) {

// Number.isSafeInteger
/* global CreateMethodProperty, Type, ToInteger */
// 20.1.2.5. Number.isSafeInteger ( number )
CreateMethodProperty(Number, 'isSafeInteger', function isSafeInteger(number) {
	// 1. If Type(number) is not Number, return false.
	if (Type(number) !== 'number') {
		return false;
	}
	// 2. If number is NaN, +∞, or -∞, return false.
	if (isNaN(number) || number === Infinity || number === -Infinity) {
		return false;
	}
	// 3. Let integer be ToInteger(number).
	var integer = ToInteger(number);
	// 4. If integer is not equal to number, return false.
	if (integer !== number) {
		return false;
	}
	// 5. If abs(integer) ≤ 2^53-1, return true.
	if (Math.abs(integer) <= (Math.pow(2, 53) - 1)) {
		return true;
	}
	// 6. Otherwise, return false.
	return false;
});

}

if (!("name"in Function.prototype
)) {

// Function.prototype.name
(function () {

	var
	accessorName = 'name',
	fnNameMatchRegex = /^\s*function\s+([^(\s]*)\s*/,
	$Function = Function,
	FunctionName = 'Function',
	FunctionProto = $Function.prototype,
	FunctionProtoCtor = FunctionProto.constructor,

	getFunctionName = function(fn) {
		var match, name;

		if (fn === $Function || fn === FunctionProtoCtor) {
			name = FunctionName;
		}
		else if (fn !== FunctionProto) {
			match = ('' + fn).match(fnNameMatchRegex);
			name = match && match[1];
		}
		return name || '';
	};


	Object.defineProperty(FunctionProto, accessorName, {
		get: function Function$name() {
			var
			fn = this,
			fnName = getFunctionName(fn);

			// Since named function definitions have immutable names, also memoize the
			// output by defining the `name` property directly on this Function
			// instance so the accessor function will not need to be invoked again.
			if (fn !== FunctionProto) {
				Object.defineProperty(fn, accessorName, {
					value: fnName,
					configurable: true
				});
			}

			return fnName;
		},
		configurable: true
	});

}());

}

if (!("EPSILON"in Number
)) {

// Number.Epsilon
// 20.1.2.1. Number.EPSILON
// The value of Number.EPSILON is the difference between 1 and the smallest value greater than 1 that is representable as a Number value, which is approximately 2.2204460492503130808472633361816 x 10-16.
// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: false }.
Object.defineProperty(Number, 'EPSILON', {
	enumerable: false,
	configurable: false,
	writable: false,
	value: Math.pow(2, -52)
});

}

if (!("MAX_SAFE_INTEGER"in Number
)) {

// Number.MAX_SAFE_INTEGER
// 20.1.2.6. Number.MAX_SAFE_INTEGER
// The value of Number.MAX_SAFE_INTEGER is 9007199254740991 (2^53-1).
// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: false }.
Object.defineProperty(Number, 'MAX_SAFE_INTEGER', {
	enumerable: false,
	configurable: false,
	writable: false,
	value: Math.pow(2, 53) - 1
});

}

if (!("MIN_SAFE_INTEGER"in Number
)) {

// Number.MIN_SAFE_INTEGER
// 20.1.2.8. Number.MIN_SAFE_INTEGER
// The value of Number.MIN_SAFE_INTEGER is -9007199254740991 (-(253-1)).
// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: false }.
Object.defineProperty(Number, 'MIN_SAFE_INTEGER', {
	enumerable: false,
	configurable: false,
	writable: false,
	value: -(Math.pow(2, 53) - 1)
});

}

if (!("freeze"in Object
)) {

// Object.freeze
/* global CreateMethodProperty */
// 19.1.2.6. Object.freeze ( O )
CreateMethodProperty(Object, 'freeze', function freeze(O) {
	// This feature cannot be implemented fully as a polyfill.
	// We choose to silently fail which allows "securable" code
	// to "gracefully" degrade to working but insecure code.
	return O;
});

}

if (!("getOwnPropertyDescriptor"in Object&&"function"==typeof Object.getOwnPropertyDescriptor&&function(){try{return"3"===Object.getOwnPropertyDescriptor("13.7",1).value}catch(t){return!1}}()
)) {

// Object.getOwnPropertyDescriptor
/* global CreateMethodProperty, ToObject, ToPropertyKey, HasOwnProperty, Type */
(function () {
	var nativeGetOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;

	var supportsDOMDescriptors = (function () {
		try {
			return Object.defineProperty(document.createElement('div'), 'one', {
				get: function () {
					return 1;
				}
			}).one === 1;
		} catch (e) {
			return false;
		}
	});

	var toString = ({}).toString;
	var split = ''.split;

	// 19.1.2.8 Object.getOwnPropertyDescriptor ( O, P )
	CreateMethodProperty(Object, 'getOwnPropertyDescriptor', function getOwnPropertyDescriptor(O, P) {
		// 1. Let obj be ? ToObject(O).
		var obj = ToObject(O);
		// Polyfill.io fallback for non-array-like strings which exist in some ES3 user-agents (IE 8)
		obj = (Type(obj) === 'string' || obj instanceof String) && toString.call(O) == '[object String]' ? split.call(O, '') : Object(O);

		// 2. Let key be ? ToPropertyKey(P).
		var key = ToPropertyKey(P);

		// 3. Let desc be ? obj.[[GetOwnProperty]](key).
		// 4. Return FromPropertyDescriptor(desc).
		// Polyfill.io Internet Explorer 8 natively supports property descriptors only on DOM objects.
		// We will fallback to the polyfill implementation if the native implementation throws an error.
		if (supportsDOMDescriptors) {
			try {
				return nativeGetOwnPropertyDescriptor(obj, key);
			// eslint-disable-next-line no-empty
			} catch (error) {}
		}
		if (HasOwnProperty(obj, key)) {
			return {
				enumerable: true,
				configurable: true,
				writable: true,
				value: obj[key]
			};
		}
	});
}());

}

if (!("getPrototypeOf"in Object
)) {

// Object.getPrototypeOf
/* global CreateMethodProperty */
// Based on: https://github.com/es-shims/es5-shim/blob/master/es5-sham.js

// https://github.com/es-shims/es5-shim/issues#issue/2
// http://ejohn.org/blog/objectgetprototypeof/
// recommended by fschaefer on github
//
// sure, and webreflection says ^_^
// ... this will nerever possibly return null
// ... Opera Mini breaks here with infinite loops
CreateMethodProperty(Object, 'getPrototypeOf', function getPrototypeOf(object) {
	if (object !== Object(object)) {
		throw new TypeError('Object.getPrototypeOf called on non-object');
	}
	var proto = object.__proto__;
	if (proto || proto === null) {
		return proto;
	} else if (typeof object.constructor == 'function' && object instanceof object.constructor) {
		return object.constructor.prototype;
	} else if (object instanceof Object) {
		return Object.prototype;
	} else {
		// Correctly return null for Objects created with `Object.create(null)`
		// (shammed or native) or `{ __proto__: null}`.  Also returns null for
		// cross-realm objects on browsers that lack `__proto__` support (like
		// IE <11), but that's the best we can do.
		return null;
	}
});

}

if (!("is"in Object
)) {

// Object.is
/* global CreateMethodProperty, SameValue */
// 19.1.2.12. Object.is ( value1, value2 )
CreateMethodProperty(Object, 'is', function is(value1, value2) {
	// 1. Return SameValue(value1, value2).
	return SameValue(value1, value2);
});

}

if (!("isExtensible"in Object
)) {

// Object.isExtensible
/* global CreateMethodProperty, Type */

(function (nativeIsExtensible) {
	// 19.1.2.13 Object.isExtensible ( O )
	CreateMethodProperty(Object, 'isExtensible', function isExtensible(O) {
		// 1. If Type(O) is not Object, return false.
		if (Type(O) !== "object") {
			return false;
		}
		// 2. Return ? IsExtensible(O).
		return nativeIsExtensible ? nativeIsExtensible(O) : true;
	});
}(Object.isExtensible));

}

if (!("keys"in Object&&function(){return 2===Object.keys(arguments).length}(1,2)&&function(){try{return Object.keys(""),!0}catch(t){return!1}}()
)) {

// Object.keys
/* global CreateMethodProperty */
CreateMethodProperty(Object, "keys", (function() {
	'use strict';

	// modified from https://github.com/es-shims/object-keys

	var has = Object.prototype.hasOwnProperty;
	var toStr = Object.prototype.toString;
	var isEnumerable = Object.prototype.propertyIsEnumerable;
	var hasDontEnumBug = !isEnumerable.call({ toString: null }, 'toString');
	var hasPrototypeEnumBug = isEnumerable.call(function () { }, 'prototype');
	function hasProtoEnumBug() {
		// Object.create polyfill creates an enumerable __proto__
		var createdObj;
		try {
			createdObj = Object.create({});
		} catch (e) {
			// If this fails the polyfil isn't loaded yet, but will be.
			// Can't add it to depedencies because of it would create a circular depedency.
			return true;
		}

		return isEnumerable.call(createdObj, '__proto__')
	}

	var dontEnums = [
		'toString',
		'toLocaleString',
		'valueOf',
		'hasOwnProperty',
		'isPrototypeOf',
		'propertyIsEnumerable',
		'constructor'
	];
	var equalsConstructorPrototype = function (o) {
		var ctor = o.constructor;
		return ctor && ctor.prototype === o;
	};
	var excludedKeys = {
		$console: true,
		$external: true,
		$frame: true,
		$frameElement: true,
		$frames: true,
		$innerHeight: true,
		$innerWidth: true,
		$outerHeight: true,
		$outerWidth: true,
		$pageXOffset: true,
		$pageYOffset: true,
		$parent: true,
		$scrollLeft: true,
		$scrollTop: true,
		$scrollX: true,
		$scrollY: true,
		$self: true,
		$webkitIndexedDB: true,
		$webkitStorageInfo: true,
		$window: true
	};
	var hasAutomationEqualityBug = (function () {
		if (typeof window === 'undefined') { return false; }
		for (var k in window) {
			try {
				if (!excludedKeys['$' + k] && has.call(window, k) && window[k] !== null && typeof window[k] === 'object') {
					try {
						equalsConstructorPrototype(window[k]);
					} catch (e) {
						return true;
					}
				}
			} catch (e) {
				return true;
			}
		}
		return false;
	}());
	var equalsConstructorPrototypeIfNotBuggy = function (o) {
		if (typeof window === 'undefined' || !hasAutomationEqualityBug) {
			return equalsConstructorPrototype(o);
		}
		try {
			return equalsConstructorPrototype(o);
		} catch (e) {
			return false;
		}
	};

	function isArgumentsObject(value) {
		var str = toStr.call(value);
		var isArgs = str === '[object Arguments]';
		if (!isArgs) {
			isArgs = str !== '[object Array]' &&
				value !== null &&
				typeof value === 'object' &&
				typeof value.length === 'number' &&
				value.length >= 0 &&
				toStr.call(value.callee) === '[object Function]';
		}
		return isArgs;
	}

	return function keys(object) {
		var isFunction = toStr.call(object) === '[object Function]';
		var isArguments = isArgumentsObject(object);
		var isString = toStr.call(object) === '[object String]';
		var theKeys = [];

		if (object === undefined || object === null) {
			throw new TypeError('Cannot convert undefined or null to object');
		}

		var skipPrototype = hasPrototypeEnumBug && isFunction;
		if (isString && object.length > 0 && !has.call(object, 0)) {
			for (var i = 0; i < object.length; ++i) {
				theKeys.push(String(i));
			}
		}

		if (isArguments && object.length > 0) {
			for (var j = 0; j < object.length; ++j) {
				theKeys.push(String(j));
			}
		} else {
			for (var name in object) {
				if (!(hasProtoEnumBug() && name === '__proto__') && !(skipPrototype && name === 'prototype') && has.call(object, name)) {
					theKeys.push(String(name));
				}
			}
		}

		if (hasDontEnumBug) {
			var skipConstructor = equalsConstructorPrototypeIfNotBuggy(object);

			for (var k = 0; k < dontEnums.length; ++k) {
				if (!(skipConstructor && dontEnums[k] === 'constructor') && has.call(object, dontEnums[k])) {
					theKeys.push(dontEnums[k]);
				}
			}
		}
		return theKeys;
	};
}()));

}

if (!("assign"in Object
)) {

// Object.assign
/* global CreateMethodProperty, Get, ToObject */
// 19.1.2.1 Object.assign ( target, ...sources )
CreateMethodProperty(Object, 'assign', function assign(target, source) { // eslint-disable-line no-unused-vars
	// 1. Let to be ? ToObject(target).
	var to = ToObject(target);

	// 2. If only one argument was passed, return to.
	if (arguments.length === 1) {
		return to;
	}

	// 3. Let sources be the List of argument values starting with the second argument
	var sources = Array.prototype.slice.call(arguments, 1);

	// 4. For each element nextSource of sources, in ascending index order, do
	var index1;
	var index2;
	var keys;
	var from;
	for (index1 = 0; index1 < sources.length; index1++) {
		var nextSource = sources[index1];
		// a. If nextSource is undefined or null, let keys be a new empty List.
		if (nextSource === undefined || nextSource === null) {
			keys = [];
			// b. Else,
		} else {
			// Polyfill.io - In order to get strings in ES3 and old V8 working correctly we need to split them into an array ourselves.
			// i. Let from be ! ToObject(nextSource).
			from = Object.prototype.toString.call(nextSource) === '[object String]' ? String(nextSource).split('') : ToObject(nextSource);
			// ii. Let keys be ? from.[[OwnPropertyKeys]]().
			/*
				This step in our polyfill is not complying with the specification.
				[[OwnPropertyKeys]] is meant to return ALL keys, including non-enumerable and symbols.
				TODO: When we have Reflect.ownKeys, use that instead as it is the userland equivalent of [[OwnPropertyKeys]].
			*/
			keys = Object.keys(from);
		}

		// c. For each element nextKey of keys in List order, do
		for (index2 = 0; index2 < keys.length; index2++) {
			var nextKey = keys[index2];
			var enumerable;
			try {
				// i. Let desc be ? from.[[GetOwnProperty]](nextKey).
				var desc = Object.getOwnPropertyDescriptor(from, nextKey);
				// ii. If desc is not undefined and desc.[[Enumerable]] is true, then
				enumerable = desc !== undefined && desc.enumerable === true;
			} catch (e) {
				// Polyfill.io - We use Object.prototype.propertyIsEnumerable as a fallback
				// because `Object.getOwnPropertyDescriptor(window.location, 'hash')` causes Internet Explorer 11 to crash.
				enumerable = Object.prototype.propertyIsEnumerable.call(from, nextKey);
			}
			if (enumerable) {
				// 1. Let propValue be ? Get(from, nextKey).
				var propValue = Get(from, nextKey);
				// 2. Perform ? Set(to, nextKey, propValue, true).
				to[nextKey] = propValue;
			}
		}
	}
	// 5. Return to.
	return to;
});

}

if (!("defineProperties"in Object
)) {

// Object.defineProperties
/* global CreateMethodProperty, Get, ToObject, Type */
// 19.1.2.3. Object.defineProperties ( O, Properties )
CreateMethodProperty(Object, 'defineProperties', function defineProperties(O, Properties) {
	// 1. If Type(O) is not Object, throw a TypeError exception.
	if (Type(O) !== 'object') {
		throw new TypeError('Object.defineProperties called on non-object');
	}
	// 2. Let props be ? ToObject(Properties).
	var props = ToObject(Properties);
	// 3. Let keys be ? props.[[OwnPropertyKeys]]().
	/*
		Polyfill.io - This step in our polyfill is not complying with the specification.
		[[OwnPropertyKeys]] is meant to return ALL keys, including non-enumerable and symbols.
		TODO: When we have Reflect.ownKeys, use that instead as it is the userland equivalent of [[OwnPropertyKeys]].
	*/
	var keys = Object.keys(props);
	// 4. Let descriptors be a new empty List.
	var descriptors = [];
	// 5. For each element nextKey of keys in List order, do
	for (var i = 0; i < keys.length; i++) {
		var nextKey = keys[i];
		// a. Let propDesc be ? props.[[GetOwnProperty]](nextKey).
		var propDesc = Object.getOwnPropertyDescriptor(props, nextKey);
		// b. If propDesc is not undefined and propDesc.[[Enumerable]] is true, then
		if (propDesc !== undefined && propDesc.enumerable) {
			// i. Let descObj be ? Get(props, nextKey).
			var descObj = Get(props, nextKey);
			// ii. Let desc be ? ToPropertyDescriptor(descObj).
			// Polyfill.io - We skip this step because Object.defineProperty deals with it.
			// TODO: Implement this step?
			var desc = descObj;
			// iii. Append the pair (a two element List) consisting of nextKey and desc to the end of descriptors.
			descriptors.push([nextKey, desc]);
		}
	}
	// 6. For each pair from descriptors in list order, do
	for (var j = 0; j < descriptors.length; j++){
		// a. Let P be the first element of pair.
		var P = descriptors[j][0];
		// b. Let desc be the second element of pair.
		desc = descriptors[j][1];
		// c. Perform ? DefinePropertyOrThrow(O, P, desc).
		Object.defineProperty(O, P, desc);
	}
	// 7. Return O.
	return O;
});

}

if (!("create"in Object
)) {

// Object.create
/* global CreateMethodProperty, Type */
(function () {
	var supportsProto = !({ __proto__: null } instanceof Object);
	if (supportsProto) {
		var createEmpty = function () {
			return {
				__proto__: null
			};
		};
	} else {
		// Taken from https://github.com/es-shims/es5-shim/blob/a265a136d6220146cfbb09026c2de1fa42e220ec/es5-sham.js#L247
		// In old IE __proto__ can't be used to manually set `null`, nor does
		// any other method exist to make an object that inherits from nothing,
		// aside from Object.prototype itself. Instead, create a new global
		// object and *steal* its Object.prototype and strip it bare. This is
		// used as the prototype to create nullary objects.
		createEmpty = function () {
			// Determine which approach to use
			// see https://github.com/es-shims/es5-shim/issues/150
			var iframe = document.createElement('iframe');
			iframe.style.display = 'none';
			var parent = document.body || document.documentElement;
			parent.appendChild(iframe);
			iframe.src = 'javascript:';
			var empty = iframe.contentWindow.Object.prototype;
			parent.removeChild(iframe);
			iframe = null;
			delete empty.constructor;
			delete empty.hasOwnProperty;
			delete empty.propertyIsEnumerable;
			delete empty.isPrototypeOf;
			delete empty.toLocaleString;
			delete empty.toString;
			delete empty.valueOf;
			var Empty = function Empty() {};
			Empty.prototype = empty;
			// short-circuit future calls
			createEmpty = function () {
				return new Empty();
			};
			return new Empty();
		};
	}

	function T() {}

	CreateMethodProperty(Object, 'create', function create(O, properties) {
		// 1. If Type(O) is neither Object nor Null, throw a TypeError exception.
		if (Type(O) !== 'object' && Type(O) !== 'null') {
			throw new TypeError('Object prototype may only be an Object or null');
		}
		if (Type(O) === 'null') {
			var obj = createEmpty();
		} else {
			// 2. Let obj be ObjectCreate(O).
			T.prototype = O;
			obj = new T();
			obj.__proto__ = O;


			obj.constructor.prototype = O;
			obj.__proto__ = O;
		}

		// 3. If Properties is not undefined, then
		if (1 in arguments) {
			// a. Return ? ObjectDefineProperties(obj, Properties).
			return Object.defineProperties(obj, properties);
		}

		return obj;
	});
}());

}


// _ESAbstract.OrdinaryCreateFromConstructor
/* global GetPrototypeFromConstructor */
// 9.1.13. OrdinaryCreateFromConstructor ( constructor, intrinsicDefaultProto [ , internalSlotsList ] )
function OrdinaryCreateFromConstructor(constructor, intrinsicDefaultProto) { // eslint-disable-line no-unused-vars
	var internalSlotsList = arguments[2] || {};
	// 1. Assert: intrinsicDefaultProto is a String value that is this specification's name of an intrinsic object.
	// The corresponding object must be an intrinsic that is intended to be used as the[[Prototype]] value of an object.

	// 2. Let proto be ? GetPrototypeFromConstructor(constructor, intrinsicDefaultProto).
	var proto = GetPrototypeFromConstructor(constructor, intrinsicDefaultProto);

	// 3. Return ObjectCreate(proto, internalSlotsList).
	// Polyfill.io - We do not pass internalSlotsList to Object.create because Object.create does not use the default ordinary object definitions specified in 9.1.
	var obj = Object.create(proto);
	for (var name in internalSlotsList) {
		if (Object.prototype.hasOwnProperty.call(internalSlotsList, name)) {
			Object.defineProperty(obj, name, {
				configurable: true,
				enumerable: false,
				writable: true,
				value: internalSlotsList[name]
			});
		}
	}
	return obj;
}

// _ESAbstract.Construct
/* global IsConstructor, OrdinaryCreateFromConstructor, Call */
// 7.3.13. Construct ( F [ , argumentsList [ , newTarget ]] )
function Construct(F /* [ , argumentsList [ , newTarget ]] */) { // eslint-disable-line no-unused-vars
	// 1. If newTarget is not present, set newTarget to F.
	var newTarget = arguments.length > 2 ? arguments[2] : F;

	// 2. If argumentsList is not present, set argumentsList to a new empty List.
	var argumentsList = arguments.length > 1 ? arguments[1] : [];

	// 3. Assert: IsConstructor(F) is true.
	if (!IsConstructor(F)) {
		throw new TypeError('F must be a constructor.');
	}

	// 4. Assert: IsConstructor(newTarget) is true.
	if (!IsConstructor(newTarget)) {
		throw new TypeError('newTarget must be a constructor.');
	}

	// 5. Return ? F.[[Construct]](argumentsList, newTarget).
	// Polyfill.io - If newTarget is the same as F, it is equivalent to new F(...argumentsList).
	if (newTarget === F) {
		return new (Function.prototype.bind.apply(F, [null].concat(argumentsList)))();
	} else {
		// Polyfill.io - This is mimicking section 9.2.2 step 5.a.
		var obj = OrdinaryCreateFromConstructor(newTarget, Object.prototype);
		return Call(F, obj, argumentsList);
	}
}

// _ESAbstract.ArraySpeciesCreate
/* global IsArray, ArrayCreate, Get, Type, IsConstructor, Construct */
// 9.4.2.3. ArraySpeciesCreate ( originalArray, length )
function ArraySpeciesCreate(originalArray, length) { // eslint-disable-line no-unused-vars
	// 1. Assert: length is an integer Number ≥ 0.
	// 2. If length is -0, set length to +0.
	if (length === 0 && 1/length === -Infinity) {
		length = 0;
	}

	// 3. Let isArray be ? IsArray(originalArray).
	var isArray = IsArray(originalArray);

	// 4. If isArray is false, return ? ArrayCreate(length).
	if (isArray === false) {
		return ArrayCreate(length);
	}

	// 5. Let C be ? Get(originalArray, "constructor").
	var C = Get(originalArray, 'constructor');

	// Polyfill.io - We skip this section as not sure how to make a cross-realm normal Array, a same-realm Array.
	// 6. If IsConstructor(C) is true, then
	// if (IsConstructor(C)) {
		// a. Let thisRealm be the current Realm Record.
		// b. Let realmC be ? GetFunctionRealm(C).
		// c. If thisRealm and realmC are not the same Realm Record, then
			// i. If SameValue(C, realmC.[[Intrinsics]].[[%Array%]]) is true, set C to undefined.
	// }
	// 7. If Type(C) is Object, then
	if (Type(C) === 'object') {
		// a. Set C to ? Get(C, @@species).
		C = 'Symbol' in self && 'species' in self.Symbol ? Get(C, self.Symbol.species) : undefined;
		// b. If C is null, set C to undefined.
		if (C === null) {
			C = undefined;
		}
	}
	// 8. If C is undefined, return ? ArrayCreate(length).
	if (C === undefined) {
		return ArrayCreate(length);
	}
	// 9. If IsConstructor(C) is false, throw a TypeError exception.
	if (!IsConstructor(C)) {
		throw new TypeError('C must be a constructor');
	}
	// 10. Return ? Construct(C, « length »).
	return Construct(C, [length]);
}
if (!("filter"in Array.prototype
)) {

// Array.prototype.filter
/* global CreateMethodProperty, ToObject, ToLength, Get, IsCallable, ArraySpeciesCreate, ToString, HasProperty, ToBoolean, Call, CreateDataPropertyOrThrow */
// 22.1.3.7. Array.prototype.filter ( callbackfn [ , thisArg ] )
CreateMethodProperty(Array.prototype, 'filter', function filter(callbackfn /* [ , thisArg ] */) {
	// 1. Let O be ? ToObject(this value).
	var O = ToObject(this);
	// 2. Let len be ? ToLength(? Get(O, "length")).
	var len = ToLength(Get(O, "length"));
	// 3. If IsCallable(callbackfn) is false, throw a TypeError exception.
	if (IsCallable(callbackfn) === false) {
		throw new TypeError(callbackfn + ' is not a function');
	}
	// 4. If thisArg is present, let T be thisArg; else let T be undefined.
	var T = arguments.length > 1 ? arguments[1] : undefined;
	// 5. Let A be ? ArraySpeciesCreate(O, 0).
	var A = ArraySpeciesCreate(O, 0);
	// 6. Let k be 0.
	var k = 0;
	// 7. Let to be 0.
	var to = 0;
	// 8. Repeat, while k < len
	while (k < len) {
		// a. Let Pk be ! ToString(k).
		var Pk = ToString(k);
		// b. Let kPresent be ? HasProperty(O, Pk).
		var kPresent = HasProperty(O, Pk);
		// c. If kPresent is true, then
		if (kPresent) {
			// i. Let kValue be ? Get(O, Pk).
			var kValue = Get(O, Pk);
			// ii. Let selected be ToBoolean(? Call(callbackfn, T, « kValue, k, O »)).
			var selected = ToBoolean(Call(callbackfn, T, [kValue, k, O]));
			// iii. If selected is true, then
			if (selected) {
				// 1. Perform ? CreateDataPropertyOrThrow(A, ! ToString(to), kValue)
				CreateDataPropertyOrThrow(A, ToString(to), kValue);
				// 2. Increase to by 1.
				to = to + 1;
			}

		}
		// d. Increase k by 1.
		k = k + 1;
	}
	// 9. Return A.
	return A;
});

}

if (!("map"in Array.prototype
)) {

// Array.prototype.map
/* global ArraySpeciesCreate, Call, CreateDataPropertyOrThrow, CreateMethodProperty, Get, HasProperty, IsCallable, ToLength, ToObject, ToString */
// 22.1.3.16. Array.prototype.map ( callbackfn [ , thisArg ] )
CreateMethodProperty(Array.prototype, 'map', function map(callbackfn /* [ , thisArg ] */) {
	// 1. Let O be ? ToObject(this value).
	var O = ToObject(this);
	// 2. Let len be ? ToLength(? Get(O, "length")).
	var len = ToLength(Get(O, "length"));
	// 3. If IsCallable(callbackfn) is false, throw a TypeError exception.
	if (IsCallable(callbackfn) === false) {
		throw new TypeError(callbackfn + ' is not a function');
	}
	// 4. If thisArg is present, let T be thisArg; else let T be undefined.
	var T = arguments.length > 1 ? arguments[1] : undefined;
	// 5. Let A be ? ArraySpeciesCreate(O, len).
	var A = ArraySpeciesCreate(O, len);
	// 6. Let k be 0.
	var k = 0;
	// 7. Repeat, while k < len
	while (k < len) {
		// a. Let Pk be ! ToString(k).
		var Pk = ToString(k);
		// b. Let kPresent be ? HasProperty(O, Pk).
		var kPresent = HasProperty(O, Pk);
		// c. If kPresent is true, then
		if (kPresent) {
			// i. Let kValue be ? Get(O, Pk).
			var kValue = Get(O, Pk);
			// ii. Let mappedValue be ? Call(callbackfn, T, « kValue, k, O »).
			var mappedValue = Call(callbackfn, T, [kValue, k, O]);
			// iii. Perform ? CreateDataPropertyOrThrow(A, Pk, mappedValue).
			CreateDataPropertyOrThrow(A, Pk, mappedValue);
		}
		// d. Increase k by 1.
		k = k + 1;
	}
	// 8. Return A.
	return A;
});

}

if (!("sort"in Array.prototype&&function(){var r={length:3,0:2,1:1,2:3}
return Array.prototype.sort.call(r,function(r,t){return r-t})===r}()
)) {

// Array.prototype.sort
/* global CreateMethodProperty, IsCallable */
"use strict";

var origSort = Array.prototype.sort;

// 22.1.3.27 Array.prototype.sort ( comparefn )
// The elements of this array are sorted. The sort must be stable (that is,
// elements that compare equal must remain in their original order). If
// comparefn is not undefined, it should be a function that accepts two
// arguments x and y and returns a negative value
// if x < y, zero if x = y, or a positive value if x > y.

CreateMethodProperty(Array.prototype, "sort", function sort(compareFn) {
	// 1. If comparefn is not undefined and IsCallable(comparefn) is false, throw
	//    a TypeError exception.
	if (compareFn !== undefined && IsCallable(compareFn) === false) {
		throw new TypeError(
			"The comparison function must be either a function or undefined"
		);
	}

	// Polyfill.io - the steps below are handled by the native
	// Array.prototype.sort method that we call.
	// 2.Let obj be ? ToObject(this value).
	// 3.Let len be ? LengthOfArrayLike(obj).

	// if comprateFn does not exist, use the spec defined in-built SortCompare.
	if (compareFn === undefined) {
		origSort.call(this);
	} else {
		// if compareFn exists, sort the array, breaking sorting ties by using the
		// items' original index position.

		// Keep track of the items starting index position.
		var that = Array.prototype.map.call(this, function(item, index) {
			return { item: item, index: index };
		});
		origSort.call(that, function(a, b) {
			var compareResult = compareFn.call(undefined, a.item, b.item);
			return compareResult === 0 ? a.index - b.index : compareResult;
		});
		// update the original object (`this`) with the new position for the items
		// which were moved.
		for (var a in that) {
			if (Object.prototype.hasOwnProperty.call(that, a)) {
				if (that[a].item !== this[a]) {
					this[a] = that[a].item;
				}
			}
		}
	}

	return this;
});

}

if (!("of"in Array
)) {

// Array.of
/* global ArrayCreate, Construct, CreateDataPropertyOrThrow, CreateMethodProperty, IsConstructor, ToString */
// 22.1.2.3. Array.of ( ...items )
CreateMethodProperty(Array, 'of', function of() {
	// 1. Let len be the actual number of arguments passed to this function.
	var len = arguments.length;
	// 2. Let items be the List of arguments passed to this function.
	var items = arguments;
	// 3. Let C be the this value.
	var C = this;
	// 4. If IsConstructor(C) is true, then
	if (IsConstructor(C)) {
		// a. Let A be ? Construct(C, « len »).
		var A = Construct(C, [len]);
		// 5. Else,
	} else {
		// a. Let A be ? ArrayCreate(len).
		A = ArrayCreate(len);
	}
	// 6. Let k be 0.
	var k = 0;
	// 7. Repeat, while k < len
	while (k < len) {
		// a. Let kValue be items[k].
		var kValue = items[k];
		// b. Let Pk be ! ToString(k).
		var Pk = ToString(k);
		// c. Perform ? CreateDataPropertyOrThrow(A, Pk, kValue).
		CreateDataPropertyOrThrow(A, Pk, kValue);
		// d. Increase k by 1.
		k = k + 1;

	}
	// 8. Perform ? Set(A, "length", len, true)
	A.length = len;
	// 9. Return A.
	return A;
});

}

if (!("getOwnPropertyNames"in Object&&function(){try{return Object.getOwnPropertyNames(1),!0}catch(t){return!1}}()
)) {

// Object.getOwnPropertyNames
/* global CreateMethodProperty, ToObject */
(function() {
	var toString = {}.toString;
	var split = "".split;
	var concat = [].concat;
	var hasOwnProperty = Object.prototype.hasOwnProperty;
	var nativeGetOwnPropertyNames = Object.getOwnPropertyNames || Object.keys;
	var cachedWindowNames =
		typeof self === "object" ? nativeGetOwnPropertyNames(self) : [];

	// 19.1.2.10 Object.getOwnPropertyNames ( O )
	CreateMethodProperty(
		Object,
		"getOwnPropertyNames",
		function getOwnPropertyNames(O) {
			var object = ToObject(O);

			if (toString.call(object) === "[object Window]") {
				try {
					return nativeGetOwnPropertyNames(object);
				} catch (e) {
					// IE bug where layout engine calls userland Object.getOwnPropertyNames for cross-domain `window` objects
					return concat.call([], cachedWindowNames);
				}
			}

			// Polyfill.io fallback for non-array-like strings which exist in some ES3 user-agents (IE 8)
			object =
				toString.call(object) == "[object String]"
					? split.call(object, "")
					: Object(object);

			var result = nativeGetOwnPropertyNames(object);
			var extraNonEnumerableKeys = ["length", "prototype"];
			for (var i = 0; i < extraNonEnumerableKeys.length; i++) {
				var key = extraNonEnumerableKeys[i];
				if (hasOwnProperty.call(object, key) && !result.includes(key)) {
					result.push(key);
				}
			}

			if (result.includes("__proto__")) {
				var index = result.indexOf("__proto__");
				result.splice(index, 1);
			}

			return result;
		}
	);
})();

}

if (!("seal"in Object&&function(){try{return Object.seal("1"),!0}catch(t){return!1}}()
)) {

// Object.seal
/* global CreateMethodProperty, Type */
// 19.1.2.19 Object.seal ( O )
(function(originalObjectSeal) {
	CreateMethodProperty(Object, 'seal', function seal(O) {
		// 1. If Type(O) is not Object, return O.
		if (Type(O) === 'object') {
			return O;
		}
		// 2. Let status be ? SetIntegrityLevel(O, "sealed").
		// 3. If status is false, throw a TypeError exception.
		// 4. Return O.
		return originalObjectSeal ? originalObjectSeal(O) : O;
	});
}(Object.seal));

}

if (!("setPrototypeOf"in Object
)) {

// Object.setPrototypeOf
/* global CreateMethodProperty */
// ES6-shim 0.16.0 (c) 2013-2014 Paul Miller (http://paulmillr.com)
// ES6-shim may be freely distributed under the MIT license.
// For more details and documentation:
// https://github.com/paulmillr/es6-shim/

 // NOTE:  This versions needs object ownership
  //        because every promoted object needs to be reassigned
  //        otherwise uncompatible browsers cannot work as expected
  //
  // NOTE:  This might need es5-shim or polyfills upfront
  //        because it's based on ES5 API.
  //        (probably just an IE <= 8 problem)
  //
  // NOTE:  nodejs is fine in version 0.8, 0.10, and future versions.
(function () {
	if (Object.setPrototypeOf) { return; }

	/*jshint proto: true */
	// @author    Andrea Giammarchi - @WebReflection

	var getOwnPropertyNames = Object.getOwnPropertyNames;
	var getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
	var create = Object.create;
	var defineProperty = Object.defineProperty;
	var getPrototypeOf = Object.getPrototypeOf;
	var objProto = Object.prototype;

	var copyDescriptors = function (target, source) {
		// define into target descriptors from source
		getOwnPropertyNames(source).forEach(function (key) {
			defineProperty(
				target,
				key,
				getOwnPropertyDescriptor(source, key)
			);
		});
		return target;
	};
	// used as fallback when no promotion is possible
	var createAndCopy = function setPrototypeOf(origin, proto) {
		return copyDescriptors(create(proto), origin);
	};
	var set, sPOf;
	try {
		// this might fail for various reasons
		// ignore if Chrome cought it at runtime
		set = getOwnPropertyDescriptor(objProto, '__proto__').set;
		set.call({}, null);
		// setter not poisoned, it can promote
		// Firefox, Chrome
		sPOf = function setPrototypeOf(origin, proto) {
			set.call(origin, proto);
			return origin;
		};
	} catch (e) {
		// do one or more feature detections
		set = { __proto__: null };
		// if proto does not work, needs to fallback
		// some Opera, Rhino, ducktape
		if (set instanceof Object) {
			sPOf = createAndCopy;
		} else {
			// verify if null objects are buggy
			/* eslint-disable no-proto */
			set.__proto__ = objProto;
			/* eslint-enable no-proto */
			// if null objects are buggy
			// nodejs 0.8 to 0.10
			if (set instanceof Object) {
				sPOf = function setPrototypeOf(origin, proto) {
					// use such bug to promote
					/* eslint-disable no-proto */
					origin.__proto__ = proto;
					/* eslint-enable no-proto */
					return origin;
				};
			} else {
				// try to use proto or fallback
				// Safari, old Firefox, many others
				sPOf = function setPrototypeOf(origin, proto) {
					// if proto is not null
					if (getPrototypeOf(origin)) {
						// use __proto__ to promote
						/* eslint-disable no-proto */
						origin.__proto__ = proto;
						/* eslint-enable no-proto */
						return origin;
					} else {
						// otherwise unable to promote: fallback
						return createAndCopy(origin, proto);
					}
				};
			}
		}
	}
	CreateMethodProperty(Object, 'setPrototypeOf', sPOf);
}());

}

if (!("flags"in RegExp.prototype
)) {

// RegExp.prototype.flags
/* global Get, ToBoolean, Type */
Object.defineProperty(RegExp.prototype, 'flags', {
	configurable: true,
	enumerable: false,
	get: function () {
		// 21.2.5.3.1 Let R be the this value.
		var R = this;

		// 21.2.5.3.2 If Type(R) is not Object, throw a TypeError exception.
		if (Type(R) !== 'object') {
			throw new TypeError('Method called on incompatible type: must be an object.');
		}
		// 21.2.5.3.3 Let result be the empty String.
		var result = '';

		// 21.2.5.3.4 Let global be ToBoolean(? Get(R, "global")).
		var global = ToBoolean(Get(R, 'global'));

		// 21.2.5.3.5 If global is true, append the code unit 0x0067 (LATIN SMALL LETTER G) as the last code unit of result.
		if (global) {
			result += 'g';
		}

		// 21.2.5.3.6 Let ignoreCase be ToBoolean(? Get(R, "ignoreCase")).
		var ignoreCase = ToBoolean(Get(R, 'ignoreCase'));

		// 21.2.5.3.7 If ignoreCase is true, append the code unit 0x0069 (LATIN SMALL LETTER I) as the last code unit of result.
		if (ignoreCase) {
			result += 'i';
		}

		// 21.2.5.3.8 Let multiline be ToBoolean(? Get(R, "multiline")).
		var multiline = ToBoolean(Get(R, 'multiline'));

		// 21.2.5.3.9 If multiline is true, append the code unit 0x006D (LATIN SMALL LETTER M) as the last code unit of result.
		if (multiline) {
			result += 'm';
		}

		// 21.2.5.3.10 Let unicode be ToBoolean(? Get(R, "unicode")).
		var unicode = ToBoolean(Get(R, 'unicode'));

		// 21.2.5.3.11 If unicode is true, append the code unit 0x0075 (LATIN SMALL LETTER U) as the last code unit of result.
		if (unicode) {
			result += 'u';
		}

		// 21.2.5.3.12 Let sticky be ToBoolean(? Get(R, "sticky")).
		var sticky = ToBoolean(Get(R, 'sticky'));

		// 21.2.5.3.13 If sticky is true, append the code unit 0x0079 (LATIN SMALL LETTER Y) as the last code unit of result.
		if (sticky) {
			result += 'y';
		}

		// 21.2.5.3.14 Return result.
		return result;
	}
});

}

if (!("fromCodePoint"in String&&1===String.fromCodePoint.length
)) {

// String.fromCodePoint
/* global CreateMethodProperty, IsArray, SameValue, ToInteger, ToNumber, UTF16Encoding */

// 21.1.2.2. String.fromCodePoint ( ...codePoints )
CreateMethodProperty(String, 'fromCodePoint', function fromCodePoint(_) {
	// Polyfill.io - List to store the characters whilst iterating over the code points.
	var result = [];
	// 1. Let codePoints be a List containing the arguments passed to this function.
	var codePoints = arguments;
	// 2. Let length be the number of elements in codePoints.
	var length = arguments.length;
	// 3. Let elements be a new empty List.
	var elements = [];
	// 4. Let nextIndex be 0.
	var nextIndex = 0;
	// 5. Repeat, while nextIndex < length
	while (nextIndex < length) {
		// Polyfill.io - We reset the elements List as we store the partial results in the result List.
		elements = [];
		// a. Let next be codePoints[nextIndex].
		var next = codePoints[nextIndex];
		// b. Let nextCP be ? ToNumber(next).
		var nextCP = ToNumber(next);
		// c. If SameValue(nextCP, ToInteger(nextCP)) is false, throw a RangeError exception.
		if (SameValue(nextCP, ToInteger(nextCP)) === false) {
			throw new RangeError('Invalid code point ' + Object.prototype.toString.call(nextCP));
		}
		// d. If nextCP < 0 or nextCP > 0x10FFFF, throw a RangeError exception.
		if (nextCP < 0 || nextCP > 0x10FFFF) {
			throw new RangeError('Invalid code point ' + Object.prototype.toString.call(nextCP));
		}
		// e. Append the elements of the UTF16Encoding of nextCP to the end of elements.
		// Polyfill.io - UTF16Encoding can return a single codepoint or a list of multiple codepoints.
		var cp = UTF16Encoding(nextCP);
		if (IsArray(cp)) {
			elements = elements.concat(cp);
		} else {
			elements.push(cp);
		}
		// f. Let nextIndex be nextIndex + 1.
		nextIndex = nextIndex + 1;

		// Polyfill.io - Retrieving the characters whilst iterating enables the function to work in a memory efficient and performant way.
		result.push(String.fromCharCode.apply(null, elements));
	}
	// 6. Return the String value whose elements are, in order, the elements in the List elements. If length is 0, the empty string is returned.
	return length === 0 ? '' : result.join('');
});

}

if (!("codePointAt"in String.prototype
)) {

// String.prototype.codePointAt
/* global CreateMethodProperty, RequireObjectCoercible, ToInteger, ToString, UTF16Decode */
// 21.1.3.3. String.prototype.codePointAt ( pos )
CreateMethodProperty(String.prototype, 'codePointAt', function codePointAt(pos) {
	// 1. Let O be ? RequireObjectCoercible(this value).
	var O = RequireObjectCoercible(this);
	// 2. Let S be ? ToString(O).
	var S = ToString(O);
	// 3. Let position be ? ToInteger(pos).
	var position = ToInteger(pos);
	// 4. Let size be the length of S.
	var size = S.length;
	// 5. If position < 0 or position ≥ size, return undefined.
	if (position < 0 || position >= size) {
		return undefined;
	}
	// 6. Let first be the numeric value of the code unit at index position within the String S.
	var first = String.prototype.charCodeAt.call(S, position);
	// 7. If first < 0xD800 or first > 0xDBFF or position+1 = size, return first.
	if (first < 0xD800 || first > 0xDBFF || position + 1 === size) {
		return first;
	}
	// 8. Let second be the numeric value of the code unit at index position+1 within the String S.
	var second = String.prototype.charCodeAt.call(S, position + 1);
	// 9. If second < 0xDC00 or second > 0xDFFF, return first.
	if (second < 0xDC00 || second > 0xDFFF) {
		return first;
	}
	// 10. Return UTF16Decode(first, second).
	// 21.1.3.3.10 Return UTF16Decode(first, second).
	return UTF16Decode(first, second);
});

}

if (!("endsWith"in String.prototype
)) {

// String.prototype.endsWith
/* global CreateMethodProperty, IsRegExp, RequireObjectCoercible, ToInteger, ToString */
// 21.1.3.6. String.prototype.endsWith ( searchString [ , endPosition ] )
CreateMethodProperty(String.prototype, 'endsWith', function endsWith(searchString /* [ , endPosition ] */) {
	'use strict';
	var endPosition = arguments.length > 1 ? arguments[1] : undefined;
	// 1. Let O be ? RequireObjectCoercible(this value).
	var O = RequireObjectCoercible(this);
	// 2. Let S be ? ToString(O).
	var S = ToString(O);
	// 3. Let isRegExp be ? IsRegExp(searchString).
	var isRegExp = IsRegExp(searchString);
	// 4. If isRegExp is true, throw a TypeError exception.
	if (isRegExp) {
		throw new TypeError('First argument to String.prototype.endsWith must not be a regular expression');
	}
	// 5. Let searchStr be ? ToString(searchString).
	var searchStr = ToString(searchString);
	// 6. Let len be the length of S.
	var len = S.length;
	// 7. If endPosition is undefined, let pos be len, else let pos be ? ToInteger(endPosition).
	var pos = endPosition === undefined ? len : ToInteger(endPosition);
	// 8. Let end be min(max(pos, 0), len).
	var end = Math.min(Math.max(pos, 0), len);
	// 9. Let searchLength be the length of searchStr.
	var searchLength = searchStr.length;
	// 10. Let start be end - searchLength.
	var start = end - searchLength;
	// 11. If start is less than 0, return false.
	if (start < 0) {
		return false;
	}
	// 12. If the sequence of elements of S starting at start of length searchLength is the same as the full element sequence of searchStr, return true.
	if (S.substr(start, searchLength) === searchStr) {
		return true;
	}
	// 13. Otherwise, return false.
	return false;
});

}

if (!("includes"in String.prototype
)) {

// String.prototype.includes
/* global CreateMethodProperty, IsRegExp, RequireObjectCoercible, ToInteger, ToString */
// 21.1.3.7. String.prototype.includes ( searchString [ , position ] )
CreateMethodProperty(String.prototype, 'includes', function includes(searchString /* [ , position ] */) {
	'use strict';
	var position = arguments.length > 1 ? arguments[1] : undefined;
	// 1. Let O be ? RequireObjectCoercible(this value).
	var O = RequireObjectCoercible(this);
	// 2. Let S be ? ToString(O).
	var S = ToString(O);
	// 3. Let isRegExp be ? IsRegExp(searchString).
	var isRegExp = IsRegExp(searchString);
	// 4. If isRegExp is true, throw a TypeError exception.
	if (isRegExp) {
		throw new TypeError('First argument to String.prototype.includes must not be a regular expression');
	}
	// 5. Let searchStr be ? ToString(searchString).
	var searchStr = ToString(searchString);
	// 6. Let pos be ? ToInteger(position). (If position is undefined, this step produces the value 0.)
	var pos = ToInteger(position);
	// 7. Let len be the length of S.
	var len = S.length;
	// 8. Let start be min(max(pos, 0), len).
	var start = Math.min(Math.max(pos, 0), len);
	// 9. Let searchLen be the length of searchStr.
	// var searchLength = searchStr.length;
	// 10. If there exists any integer k not smaller than start such that k + searchLen is not greater than len, and for all nonnegative integers j less than searchLen, the code unit at index k+j within S is the same as the code unit at index j within searchStr, return true; but if there is no such integer k, return false.
	return String.prototype.indexOf.call(S, searchStr, start) !== -1;
});

}

if (!("repeat"in String.prototype
)) {

// String.prototype.repeat
/* global CreateMethodProperty, RequireObjectCoercible, ToInteger, ToString */
// 21.1.3.15String.prototype.repeat ( count )
CreateMethodProperty(String.prototype, 'repeat', function repeat(count) {
	'use strict';
	// 1. Let O be ? RequireObjectCoercible(this value).
	var O = RequireObjectCoercible(this);
	// 2. Let S be ? ToString(O).
	var S = ToString(O);
	// 3. Let n be ? ToInteger(count).
	var n = ToInteger(count);
	// 4. If n < 0, throw a RangeError exception.
	if (n < 0) {
		throw new RangeError('Invalid count value');
	}
	// 5. If n is +∞, throw a RangeError exception.
	if (n === Infinity) {
		throw new RangeError('Invalid count value');
	}
	// 6. Let T be the String value that is made from n copies of S appended together. If n is 0, T is the empty String.
	var T = n === 0 ? '' : new Array(n + 1).join(S);
	// 7. Return T.
	return T;
});

}

if (!("startsWith"in String.prototype
)) {

// String.prototype.startsWith
/* global CreateMethodProperty, IsRegExp, RequireObjectCoercible, ToInteger, ToString */
// 21.1.3.20. String.prototype.startsWith ( searchString [ , position ] )
CreateMethodProperty(String.prototype, 'startsWith', function startsWith(searchString /* [ , position ] */) {
	'use strict';
	var position = arguments.length > 1 ? arguments[1] : undefined;
	// 1. Let O be ? RequireObjectCoercible(this value).
	var O = RequireObjectCoercible(this);
	// 2. Let S be ? ToString(O).
	var S = ToString(O);
	// 3. Let isRegExp be ? IsRegExp(searchString).
	var isRegExp = IsRegExp(searchString);
	// 4. If isRegExp is true, throw a TypeError exception.
	if (isRegExp) {
		throw new TypeError('First argument to String.prototype.startsWith must not be a regular expression');
	}
	// 5. Let searchStr be ? ToString(searchString).
	var searchStr = ToString(searchString);
	// 6. Let pos be ? ToInteger(position). (If position is undefined, this step produces the value 0.)
	var pos = ToInteger(position);
	// 7. Let len be the length of S.
	var len = S.length;
	// 8. Let start be min(max(pos, 0), len).
	var start = Math.min(Math.max(pos, 0), len);
	// 9. Let searchLength be the length of searchStr.
	var searchLength = searchStr.length;
	// 10. If searchLength+start is greater than len, return false.
	if (searchLength + start > len) {
		return false;
	}
	// 11. If the sequence of elements of S starting at start of length searchLength is the same as the full element sequence of searchStr, return true.
	if (S.substr(start).indexOf(searchString) === 0) {
		return true;
	}
	// 12. Otherwise, return false.
	return false;
});

}

if (!("trim"in String.prototype&&function(){var r="​᠎"
return!"\t\n\x0B\f\r                　\u2028\u2029\ufeff".trim()&&r.trim()===r}()
)) {

// String.prototype.trim
/* global CreateMethodProperty, TrimString */
// 21.1.3.27. String.prototype.trim ( )
CreateMethodProperty(String.prototype, 'trim', function trim() {
	'use strict';
	// Let S be this value.
	var S = this;
	// Return ? TrimString(S, "start+end").
	return TrimString(S, "start+end");
});

}

if (!("parseFloat"in Number&&1/parseFloat("\t\n\x0B\f\r                　\u2028\u2029\ufeff-0")==-Infinity
)) {

// Number.parseFloat
/* global CreateMethodProperty */
(function (nativeparseFloat, global) {
	var parseFloat = function parseFloat(str) {
		var string = String(str).trim();
		var result = nativeparseFloat(string);
		return result === 0 && string.charAt(0) == '-' ? -0 : result;
	}
	try {
		CreateMethodProperty(global, 'parseFloat', parseFloat);
	} catch (e) {
		// IE8 throws an error here if we set enumerable to false.
		// More info on table 2: https://msdn.microsoft.com/en-us/library/dd229916(v=vs.85).aspx
		global.parseFloat = parseFloat;
	}
	// 20.1.2.12. Number.parseFloat ( string )
	// The value of the Number.parseFloat data property is the same built-in function object that is the value of the  parseFloat property of the global object defined in 18.2.4.
	CreateMethodProperty(Number, 'parseFloat', global.parseFloat);
}(parseFloat, this));

}

if (!("parseInt"in Number&&8===Number.parseInt("08")
)) {

// Number.parseInt
/* global CreateMethodProperty */
(function (nativeParseInt, global) {
	// Polyfill.io - IE 8's parseInt is incorrect
	var parseInt = function parseInt(str, radix) {
		var string = String(str).trim();
		return nativeParseInt(string, (radix >>> 0) || (/^[-+]?0[xX]/.test(string) ? 16 : 10));
	}
	try {
		CreateMethodProperty(global, 'parseInt', parseInt);
	} catch (e) {
		// IE8 throws an error here if we set enumerable to false.
		// More info on table 2: https://msdn.microsoft.com/en-us/library/dd229916(v=vs.85).aspx
		global.parseInt = parseInt;
	}
	// 20.1.2.13. Number.parseInt ( string, radix )
	// The value of the Number.parseInt data property is the same built-in function object that is the value of the  parseInt property of the global object defined in 18.2.5.
	CreateMethodProperty(Number, 'parseInt', global.parseInt);
}(parseInt, this));

}

if (!("Symbol"in self&&0===self.Symbol.length
)) {

// Symbol
// A modification of https://github.com/WebReflection/get-own-property-symbols
// (C) Andrea Giammarchi - MIT Licensed

/* global Type */
(function (Object,  GOPS, global) {
	'use strict'; //so that ({}).toString.call(null) returns the correct [object Null] rather than [object Window]

	var supportsGetters = (function () {
		// supports getters
		try {
			var a = {};
			Object.defineProperty(a, "t", {
				configurable: true,
				enumerable: false,
				get: function () {
					return true;
				},
				set: undefined
			});
			return !!a.t;
		} catch (e) {
			return false;
		}
	}());

	var	setDescriptor;
	var id = 0;
	var random = '' + Math.random();
	var prefix = '__\x01symbol:';
	var prefixLength = prefix.length;
	var internalSymbol = '__\x01symbol@@' + random;
	var emptySymbolLookup = {};
	var DP = 'defineProperty';
	var DPies = 'defineProperties';
	var GOPN = 'getOwnPropertyNames';
	var GOPD = 'getOwnPropertyDescriptor';
	var PIE = 'propertyIsEnumerable';
	var ObjectProto = Object.prototype;
	var hOP = ObjectProto.hasOwnProperty;
	var pIE = ObjectProto[PIE];
	var toString = ObjectProto.toString;
	var concat = Array.prototype.concat;
	var cachedWindowNames = Object.getOwnPropertyNames ? Object.getOwnPropertyNames(self) : [];
	var nGOPN = Object[GOPN];
	var gOPN = function getOwnPropertyNames (obj) {
		if (toString.call(obj) === '[object Window]') {
			try {
				return nGOPN(obj);
			} catch (e) {
				// IE bug where layout engine calls userland gOPN for cross-domain `window` objects
				return concat.call([], cachedWindowNames);
			}
		}
		return nGOPN(obj);
	};
	var gOPD = Object[GOPD];
	var objectCreate = Object.create;
	var objectKeys = Object.keys;
	var freeze = Object.freeze || Object;
	var objectDefineProperty = Object[DP];
	var $defineProperties = Object[DPies];
	var descriptor = gOPD(Object, GOPN);
	var addInternalIfNeeded = function (o, uid, enumerable) {
		if (!hOP.call(o, internalSymbol)) {
			try {
				objectDefineProperty(o, internalSymbol, {
					enumerable: false,
					configurable: false,
					writable: false,
					value: {}
				});
			} catch (e) {
				o[internalSymbol] = {};
			}
		}
		o[internalSymbol]['@@' + uid] = enumerable;
	};
	var createWithSymbols = function (proto, descriptors) {
		var self = objectCreate(proto);
		gOPN(descriptors).forEach(function (key) {
			if (propertyIsEnumerable.call(descriptors, key)) {
				$defineProperty(self, key, descriptors[key]);
			}
		});
		return self;
	};
	var copyAsNonEnumerable = function (descriptor) {
		var newDescriptor = objectCreate(descriptor);
		newDescriptor.enumerable = false;
		return newDescriptor;
	};
	var get = function get(){};
	var onlyNonSymbols = function (name) {
		return name != internalSymbol &&
			!hOP.call(source, name);
	};
	var onlySymbols = function (name) {
		return name != internalSymbol &&
			hOP.call(source, name);
	};
	var propertyIsEnumerable = function propertyIsEnumerable(key) {
		var uid = '' + key;
		return onlySymbols(uid) ? (
			hOP.call(this, uid) &&
			this[internalSymbol] && this[internalSymbol]['@@' + uid]
		) : pIE.call(this, key);
	};
	var setAndGetSymbol = function (uid) {
		var descriptor = {
			enumerable: false,
			configurable: true,
			get: get,
			set: function (value) {
			setDescriptor(this, uid, {
				enumerable: false,
				configurable: true,
				writable: true,
				value: value
			});
			addInternalIfNeeded(this, uid, true);
			}
		};
		try {
			objectDefineProperty(ObjectProto, uid, descriptor);
		} catch (e) {
			ObjectProto[uid] = descriptor.value;
		}
		source[uid] = objectDefineProperty(
			Object(uid),
			'constructor',
			sourceConstructor
		);
		var description = gOPD(Symbol.prototype, 'description');
		if (description) {
			objectDefineProperty(
				source[uid],
				'description',
				description
			);
		}
		return freeze(source[uid]);
	};

	var symbolDescription = function (s) {
		var sym = thisSymbolValue(s);

		// 3. Return sym.[[Description]].
		if (supportsInferredNames) {
			var name = getInferredName(sym);
			if (name !== "") {
				return name.slice(1, -1); // name.slice('['.length, -']'.length);
			}
		}

		if (emptySymbolLookup[sym] !== undefined) {
			return emptySymbolLookup[sym];
		}

		var string = sym.toString();
		var randomStartIndex = string.lastIndexOf("0.");
		string = string.slice(10, randomStartIndex);

		if (string === "") {
			return undefined;
		}
		return string;
	};

	var Symbol = function Symbol() {
		var description = arguments[0];
		if (this instanceof Symbol) {
			throw new TypeError('Symbol is not a constructor');
		}

		var uid = prefix.concat(description || '', random, ++id);

		if (description !== undefined && (description === null || isNaN(description) || String(description) === "")) {
			emptySymbolLookup[uid] = String(description);
		}

		var that = setAndGetSymbol(uid);

		if (!supportsGetters) {
			Object.defineProperty(that, "description", {
				configurable: true,
				enumerable: false,
				value: symbolDescription(that)
			});
		}

		return that;
	};

	var source = objectCreate(null);
	var sourceConstructor = {value: Symbol};
	var sourceMap = function (uid) {
		return source[uid];
		};
	var $defineProperty = function defineProperty(o, key, descriptor) {
		var uid = '' + key;
		if (onlySymbols(uid)) {
			setDescriptor(o, uid, descriptor.enumerable ?
				copyAsNonEnumerable(descriptor) : descriptor);
			addInternalIfNeeded(o, uid, !!descriptor.enumerable);
		} else {
			objectDefineProperty(o, key, descriptor);
		}
		return o;
	};

	var onlyInternalSymbols = function (obj) {
		return function (name) {
			return hOP.call(obj, internalSymbol) && hOP.call(obj[internalSymbol], '@@' + name);
		};
	};
	var $getOwnPropertySymbols = function getOwnPropertySymbols(o) {
		return gOPN(o).filter(o === ObjectProto ? onlyInternalSymbols(o) : onlySymbols).map(sourceMap);
		}
	;

	descriptor.value = $defineProperty;
	objectDefineProperty(Object, DP, descriptor);

	descriptor.value = $getOwnPropertySymbols;
	objectDefineProperty(Object, GOPS, descriptor);

	descriptor.value = function getOwnPropertyNames(o) {
		return gOPN(o).filter(onlyNonSymbols);
	};
	objectDefineProperty(Object, GOPN, descriptor);

	descriptor.value = function defineProperties(o, descriptors) {
		var symbols = $getOwnPropertySymbols(descriptors);
		if (symbols.length) {
		objectKeys(descriptors).concat(symbols).forEach(function (uid) {
			if (propertyIsEnumerable.call(descriptors, uid)) {
			$defineProperty(o, uid, descriptors[uid]);
			}
		});
		} else {
		$defineProperties(o, descriptors);
		}
		return o;
	};
	objectDefineProperty(Object, DPies, descriptor);

	descriptor.value = propertyIsEnumerable;
	objectDefineProperty(ObjectProto, PIE, descriptor);

	descriptor.value = Symbol;
	objectDefineProperty(global, 'Symbol', descriptor);

	// defining `Symbol.for(key)`
	descriptor.value = function (key) {
		var uid = prefix.concat(prefix, key, random);
		return uid in ObjectProto ? source[uid] : setAndGetSymbol(uid);
	};
	objectDefineProperty(Symbol, 'for', descriptor);

	// defining `Symbol.keyFor(symbol)`
	descriptor.value = function (symbol) {
		if (onlyNonSymbols(symbol))
		throw new TypeError(symbol + ' is not a symbol');
		return hOP.call(source, symbol) ?
		symbol.slice(prefixLength * 2, -random.length) :
		void 0
		;
	};
	objectDefineProperty(Symbol, 'keyFor', descriptor);

	descriptor.value = function getOwnPropertyDescriptor(o, key) {
		var descriptor = gOPD(o, key);
		if (descriptor && onlySymbols(key)) {
		descriptor.enumerable = propertyIsEnumerable.call(o, key);
		}
		return descriptor;
	};
	objectDefineProperty(Object, GOPD, descriptor);

	descriptor.value = function create(proto, descriptors) {
		return arguments.length === 1 || typeof descriptors === "undefined" ?
		objectCreate(proto) :
		createWithSymbols(proto, descriptors);
	};

	objectDefineProperty(Object, 'create', descriptor);

	var strictModeSupported = (function(){ 'use strict'; return this; }).call(null) === null;
	if (strictModeSupported) {
		descriptor.value = function () {
			var str = toString.call(this);
			return (str === '[object String]' && onlySymbols(this)) ? '[object Symbol]' : str;
		};
	} else {
		descriptor.value = function () {
			// https://github.com/Financial-Times/polyfill-library/issues/164#issuecomment-486965300
			// Polyfill.io this code is here for the situation where a browser does not
			// support strict mode and is executing `Object.prototype.toString.call(null)`.
			// This code ensures that we return the correct result in that situation however,
			// this code also introduces a bug where it will return the incorrect result for
			// `Object.prototype.toString.call(window)`. We can't have the correct result for
			// both `window` and `null`, so we have opted for `null` as we believe this is the more
			// common situation.
			if (this === window) {
				return '[object Null]';
			}

			var str = toString.call(this);
			return (str === '[object String]' && onlySymbols(this)) ? '[object Symbol]' : str;
		};
	}
	objectDefineProperty(ObjectProto, 'toString', descriptor);

	setDescriptor = function (o, key, descriptor) {
		var protoDescriptor = gOPD(ObjectProto, key);
		delete ObjectProto[key];
		objectDefineProperty(o, key, descriptor);
		if (o !== ObjectProto) {
			objectDefineProperty(ObjectProto, key, protoDescriptor);
		}
	};

	// The abstract operation thisSymbolValue(value) performs the following steps:
	function thisSymbolValue(value) {
		// 1. If Type(value) is Symbol, return value.
		if (Type(value) === "symbol") {
			return value;
		}
		// 2. If Type(value) is Object and value has a [[SymbolData]] internal slot, then
		// a. Let s be value.[[SymbolData]].
		// b. Assert: Type(s) is Symbol.
		// c. Return s.
		// 3. Throw a TypeError exception.
		throw TypeError(value + " is not a symbol");
	}

	// Symbol.prototype.description
	if (function () {
		// supports getters
		try {
			var a = {};
			Object.defineProperty(a, "t", {
				configurable: true,
				enumerable: false,
				get: function() {
					return true;
				},
				set: undefined
			});
			return !!a.t;
		} catch (e) {
			return false;
		}
	}()) {
		var getInferredName;
		try {
			// eslint-disable-next-line no-new-func
			getInferredName = Function("s", "var v = s.valueOf(); return { [v]() {} }[v].name;");
			// eslint-disable-next-line no-empty
		} catch (e) { }

		var inferred = function () { };
		var supportsInferredNames = getInferredName && inferred.name === "inferred" ? getInferredName : null;


		// 19.4.3.2 get Symbol.prototype.description
		Object.defineProperty(global.Symbol.prototype, "description", {
			configurable: true,
			enumerable: false,
			get: function () {
				// 1. Let s be the this value.
				var s = this;
				return symbolDescription(s);
			}
		});
	}

}(Object, 'getOwnPropertySymbols', self));

}

if (!("Symbol"in self&&"hasInstance"in self.Symbol
)) {

// Symbol.hasInstance
/* global Symbol */
Object.defineProperty(Symbol, 'hasInstance', { value: Symbol('hasInstance') });

}

if (!("Symbol"in self&&"isConcatSpreadable"in self.Symbol
)) {

// Symbol.isConcatSpreadable
/* global Symbol */
Object.defineProperty(Symbol, 'isConcatSpreadable', { value: Symbol('isConcatSpreadable') });

}

if (!("Symbol"in self&&"iterator"in self.Symbol
)) {

// Symbol.iterator
Object.defineProperty(self.Symbol, 'iterator', { value: self.Symbol('iterator') });

}


// _ESAbstract.GetIterator
/* global GetMethod, Symbol, Call, Type, GetV */
// 7.4.1. GetIterator ( obj [ , method ] )
// The abstract operation GetIterator with argument obj and optional argument method performs the following steps:
function GetIterator(obj /*, method */) { // eslint-disable-line no-unused-vars
	// 1. If method is not present, then
		// a. Set method to ? GetMethod(obj, @@iterator).
	var method = arguments.length > 1 ? arguments[1] : GetMethod(obj, Symbol.iterator);
	// 2. Let iterator be ? Call(method, obj).
	var iterator = Call(method, obj);
	// 3. If Type(iterator) is not Object, throw a TypeError exception.
	if (Type(iterator) !== 'object') {
		throw new TypeError('bad iterator');
	}
	// 4. Let nextMethod be ? GetV(iterator, "next").
	var nextMethod = GetV(iterator, "next");
	// 5. Let iteratorRecord be Record {[[Iterator]]: iterator, [[NextMethod]]: nextMethod, [[Done]]: false}.
	var iteratorRecord = Object.create(null);
	iteratorRecord['[[Iterator]]'] = iterator;
	iteratorRecord['[[NextMethod]]'] = nextMethod;
	iteratorRecord['[[Done]]'] = false;
	// 6. Return iteratorRecord.
	return iteratorRecord;
}
if (!("Symbol"in self&&"match"in self.Symbol
)) {

// Symbol.match
/* global Symbol */
Object.defineProperty(Symbol, 'match', { value: Symbol('match') });

}

if (!("Symbol"in self&&"replace"in self.Symbol
)) {

// Symbol.replace
/* global Symbol */
Object.defineProperty(Symbol, 'replace', { value: Symbol('replace') });

}

if (!("Symbol"in self&&"search"in self.Symbol
)) {

// Symbol.search
/* global Symbol */
Object.defineProperty(Symbol, 'search', { value: Symbol('search') });

}

if (!("Symbol"in self&&"species"in self.Symbol
)) {

// Symbol.species
/* global Symbol */
Object.defineProperty(Symbol, 'species', { value: Symbol('species') });

}

if (!("Map"in self&&function(t){try{var n=new t.Map([[1,1],[2,2]])
return 0===t.Map.length&&2===n.size&&"Symbol"in t&&"iterator"in t.Symbol&&"function"==typeof n[t.Symbol.iterator]}catch(e){return!1}}(self)
)) {

// Map
/* global CreateIterResultObject, CreateMethodProperty, GetIterator, IsCallable, IteratorClose, IteratorStep, IteratorValue, OrdinaryCreateFromConstructor, SameValueZero, Type, Symbol */
(function (global) {
	var supportsGetters = (function () {
		try {
			var a = {};
			Object.defineProperty(a, 't', {
				configurable: true,
				enumerable: false,
				get: function () {
					return true;
				},
				set: undefined
			});
			return !!a.t;
		} catch (e) {
			return false;
		}
	}());

	// Need an internal counter to assign unique IDs to a key map
	var _uniqueHashId = 0;
	// Create a unique key name for storing meta data on functions and objects to enable lookups in hash table
	var _metaKey = Symbol('meta_' + ((Math.random() * 100000000) + '').replace('.', ''));

	/**
	 * hashKey()
	 * Function that given a key of `any` type, returns a string key value to enable hash map optimization for accessing Map data structure
	 * @param {string|integer|function|object} recordKey - Record key to normalize to string accessor for hash map
	 * @returns {string|false} - Returns a hashed string value or false if non extensible object key
	 */
	var hashKey = function(recordKey) {
		// Check to see if we are dealing with object or function type.
		if (typeof recordKey === 'object' ? recordKey !== null : typeof recordKey === 'function') {
			// Check to see if we are dealing with a non extensible object
			if (!Object.isExtensible(recordKey)) {
				// Return `false`
				return false;
			}
			if (!Object.prototype.hasOwnProperty.call(recordKey, _metaKey)) {
				var uniqueHashKey = typeof(recordKey)+'-'+(++_uniqueHashId);
				Object.defineProperty(recordKey, _metaKey, {
					configurable: false,
					enumerable: false,
					writable: false,
					value: uniqueHashKey
				});
			}
			// Return previously defined hashed key
			return recordKey[_metaKey];
		}
		// If this is just a primitive, we can cast it to a string and return it
		return ''+recordKey;
	};

	/**
	 * getRecordIndex()
	 * Function that given a Map and a key of `any` type, returns an index number that coorelates with a record found in `this._keys[index]` and `this._values[index]`
	 * @param {Map} map - Map structure
	 * @param {string|number|function|object} recordKey - Record key to normalize to string accessor for hash map
	 * @returns {number|false} - Returns either a index to access map._keys and map._values, or false if not found
	 */
	var getRecordIndex = function(map, recordKey) {
		var hashedKey = hashKey(recordKey); // Casts key to unique string (unless already string or number)
		if (hashedKey === false) {
			// We have to iterate through our Map structure because `recordKey` is non-primitive and not extensible
			return getRecordIndexSlow(map, recordKey);
		}
		var recordIndex = map._table[hashedKey]; // O(1) access to record
		return recordIndex !== undefined ? recordIndex : false;
	};

	/**
	 * getRecordIndexSlow()
	 * Alternative (and slower) function to `getRecordIndex()`.  Necessary for looking up non-extensible object keys.
	 * @param {Map} map - Map structure
	 * @param {string|number|function|object} recordKey - Record key to normalize to string accessor for hash map
	 * @returns {number|false} - Returns either a index to access map._keys and map._values, or false if not found
	 */
	var getRecordIndexSlow = function(map, recordKey) {
		// We have to iterate through our Map structure because `recordKey` is non-primitive and not extensible
		for (var i = 0; i < map._keys.length; i++) {
			var _recordKey = map._keys[i];
			if (_recordKey !== undefMarker && SameValueZero(_recordKey, recordKey)) {
				return i;
			}
		}
		return false;
	};

	/**
	 * setHashIndex()
	 * Function that given a map, key of `any` type, and a value, creates a new entry in Map hash table
	 * @param {Map} map
	 * @param {string|number|function|object} recordKey - Key to translate into normalized key for hash map
	 * @param {number|bool} recordIndex - new record index for the hashedKey or `false` to delete the record index for the hashedKey
	 * @returns {bool} - indicates success of operation
	 */
	var setHashIndex = function(map, recordKey, recordIndex) {
		var hashedKey = hashKey(recordKey);
		if (hashedKey === false) {
			// If hashed key is false, the recordKey is an object which is not extensible.
			// That indicates we cannot use the hash map for it, so this operation becomes no-op.
			return false;
		}
		if (recordIndex === false) {
			delete map._table[hashedKey];
		} else {
			map._table[hashedKey] = recordIndex;
		}
		return true;
	};

	// Deleted map items mess with iterator pointers, so rather than removing them mark them as deleted. Can't use undefined or null since those both valid keys so use a private symbol.
	var undefMarker = Symbol('undef');
	// 23.1.1.1 Map ( [ iterable ] )
	var Map = function Map(/* iterable */) {
		// 1. If NewTarget is undefined, throw a TypeError exception.
		if (!(this instanceof Map)) {
			throw new TypeError('Constructor Map requires "new"');
		}
		// 2. Let map be ? OrdinaryCreateFromConstructor(NewTarget, "%MapPrototype%", « [[MapData]] »).
		var map = OrdinaryCreateFromConstructor(this, Map.prototype, {
			_table: {}, // O(1) access table for retrieving records
			_keys: [],
			_values: [],
			_size: 0,
			_es6Map: true
		});

		// 3. Set map.[[MapData]] to a new empty List.
		// Polyfill.io - This step was done as part of step two.

		// Some old engines do not support ES5 getters/setters.  Since Map only requires these for the size property, we can fall back to setting the size property statically each time the size of the map changes.
		if (!supportsGetters) {
			Object.defineProperty(map, 'size', {
				configurable: true,
				enumerable: false,
				writable: true,
				value: 0
			});
		}

		// 4. If iterable is not present, let iterable be undefined.
		var iterable = arguments.length > 0 ? arguments[0] : undefined;

		// 5. If iterable is either undefined or null, return map.
		if (iterable === null || iterable === undefined) {
			return map;
		}

		// 6. Let adder be ? Get(map, "set").
		var adder = map.set;

		// 7. If IsCallable(adder) is false, throw a TypeError exception.
		if (!IsCallable(adder)) {
			throw new TypeError("Map.prototype.set is not a function");
		}

		// 8. Let iteratorRecord be ? GetIterator(iterable).
		try {
			var iteratorRecord = GetIterator(iterable);
			// 9. Repeat,
			// eslint-disable-next-line no-constant-condition
			while (true) {
				// a. Let next be ? IteratorStep(iteratorRecord).
				var next = IteratorStep(iteratorRecord);
				// b. If next is false, return map.
				if (next === false) {
					return map;
				}
				// c. Let nextItem be ? IteratorValue(next).
				var nextItem = IteratorValue(next);
				// d. If Type(nextItem) is not Object, then
				if (Type(nextItem) !== 'object') {
					// i. Let error be Completion{[[Type]]: throw, [[Value]]: a newly created TypeError object, [[Target]]: empty}.
					try {
						throw new TypeError('Iterator value ' + nextItem + ' is not an entry object');
					} catch (error) {
						// ii. Return ? IteratorClose(iteratorRecord, error).
						return IteratorClose(iteratorRecord, error);
					}
				}
				try {
					// Polyfill.io - The try catch accounts for steps: f, h, and j.

					// e. Let k be Get(nextItem, "0").
					var k = nextItem[0];
					// f. If k is an abrupt completion, return ? IteratorClose(iteratorRecord, k).
					// g. Let v be Get(nextItem, "1").
					var v = nextItem[1];
					// h. If v is an abrupt completion, return ? IteratorClose(iteratorRecord, v).
					// i. Let status be Call(adder, map, « k.[[Value]], v.[[Value]] »).
					adder.call(map, k, v);
				} catch (e) {
					// j. If status is an abrupt completion, return ? IteratorClose(iteratorRecord, status).
					return IteratorClose(iteratorRecord, e);
				}
			}
		} catch (e) {
			// Polyfill.io - For user agents which do not have iteration methods on argument objects or arrays, we can special case those.
			if (Array.isArray(iterable) ||
				Object.prototype.toString.call(iterable) === '[object Arguments]' ||
				// IE 7 & IE 8 return '[object Object]' for the arguments object, we can detect by checking for the existence of the callee property
				(!!iterable.callee)) {
				var index;
				var length = iterable.length;
				for (index = 0; index < length; index++) {
					adder.call(map, iterable[index][0], iterable[index][1]);
				}
			}
		}
		return map;
	};

	// 23.1.2.1. Map.prototype
	// The initial value of Map.prototype is the intrinsic object %MapPrototype%.
	// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: false }.
	Object.defineProperty(Map, 'prototype', {
		configurable: false,
		enumerable: false,
		writable: false,
		value: {}
	});

	// 23.1.2.2 get Map [ @@species ]
	if (supportsGetters) {
		Object.defineProperty(Map, Symbol.species, {
			configurable: true,
			enumerable: false,
			get: function () {
				// 1. Return the this value.
				return this;
			},
			set: undefined
		});
	} else {
		CreateMethodProperty(Map, Symbol.species, Map);
	}

	// 23.1.3.1 Map.prototype.clear ( )
	CreateMethodProperty(Map.prototype, 'clear', function clear() {
			// 1. Let M be the this value.
			var M = this;
			// 2. If Type(M) is not Object, throw a TypeError exception.
			if (Type(M) !== 'object') {
				throw new TypeError('Method Map.prototype.clear called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 3. If M does not have a [[MapData]] internal slot, throw a TypeError exception.
			if (M._es6Map !== true) {
				throw new TypeError('Method Map.prototype.clear called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 4. Let entries be the List that is M.[[MapData]].
			var entries = M._keys;
			// 5. For each Record {[[Key]], [[Value]]} p that is an element of entries, do
			for (var i = 0; i < entries.length; i++) {
				// 5.a. Set p.[[Key]] to empty.
				M._keys[i] = undefMarker;
				// 5.b. Set p.[[Value]] to empty.
				M._values[i] = undefMarker;
			}
			this._size = 0;
			if (!supportsGetters) {
				this.size = this._size;
			}
			// 5a. Clear lookup table
			this._table = {};
			// 6. Return undefined.
			return undefined;
		}
	);

	// 23.1.3.2. Map.prototype.constructor
	CreateMethodProperty(Map.prototype, 'constructor', Map);

	// 23.1.3.3. Map.prototype.delete ( key )
	CreateMethodProperty(Map.prototype, 'delete', function (key) {
			// 1. Let M be the this value.
			var M = this;
			// 2. If Type(M) is not Object, throw a TypeError exception.
			if (Type(M) !== 'object') {
				throw new TypeError('Method Map.prototype.clear called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 3. If M does not have a [[MapData]] internal slot, throw a TypeError exception.
			if (M._es6Map !== true) {
				throw new TypeError('Method Map.prototype.clear called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 4. Let entries be the List that is M.[[MapData]].
			// 5. For each Record {[[Key]], [[Value]]} p that is an element of entries, do
				// 5a. If p.[[Key]] is not empty and SameValueZero(p.[[Key]], key) is true, then
					// i. Set p.[[Key]] to empty.
					// ii. Set p.[[Value]] to empty.
					// ii-a. Remove key from lookup table
					// iii. Return true.
			// 6. Return false.

			// Implement steps 4-6 with a more optimal algo

			// Steps 4-5: Access record
			var recordIndex = getRecordIndex(M, key); // O(1) access to record index

			if (recordIndex !== false) {
				// Get record's `key` (could be `any` type);
				var recordKey = M._keys[recordIndex];
				// 5a. If p.[[Key]] is not empty and SameValueZero(p.[[Key]], key) is true, then
				if (recordKey !== undefMarker && SameValueZero(recordKey, key)) {
					// i. Set p.[[Key]] to empty.
					this._keys[recordIndex] = undefMarker;
					// ii. Set p.[[Value]] to empty.
					this._values[recordIndex] = undefMarker;
					this._size = --this._size;
					if (!supportsGetters) {
						this.size = this._size;
					}
					// iia. Remove key from lookup table
					setHashIndex(this, key, false);
					// iii. Return true.
					return true;
				}
			}

			// 6. Return false.
			return false;
		}
	);

	// 23.1.3.4. Map.prototype.entries ( )
	CreateMethodProperty(Map.prototype, 'entries', function entries () {
			// 1. Let M be the this value.
			var M = this;
			// 2. Return ? CreateMapIterator(M, "key+value").
			return CreateMapIterator(M, 'key+value');
		}
	);

	// 23.1.3.5. Map.prototype.forEach ( callbackfn [ , thisArg ] )
	CreateMethodProperty(Map.prototype, 'forEach', function (callbackFn) {
			// 1. Let M be the this value.
			var M = this;
			// 2. If Type(M) is not Object, throw a TypeError exception.
			if (Type(M) !== 'object') {
				throw new TypeError('Method Map.prototype.forEach called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 3. If M does not have a [[MapData]] internal slot, throw a TypeError exception.
			if (M._es6Map !== true) {
				throw new TypeError('Method Map.prototype.forEach called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 4. If IsCallable(callbackfn) is false, throw a TypeError exception.
			if (!IsCallable(callbackFn)) {
				throw new TypeError(Object.prototype.toString.call(callbackFn) + ' is not a function.');
			}
			// 5. If thisArg is present, let T be thisArg; else let T be undefined.
			if (arguments[1]) {
				var T = arguments[1];
			}
			// 6. Let entries be the List that is M.[[MapData]].
			var entries = M._keys;
			// 7. For each Record {[[Key]], [[Value]]} e that is an element of entries, in original key insertion order, do
			for (var i = 0; i < entries.length; i++) {
				// a. If e.[[Key]] is not empty, then
				if (M._keys[i] !== undefMarker && M._values[i] !== undefMarker ) {
					// i. Perform ? Call(callbackfn, T, « e.[[Value]], e.[[Key]], M »).
					callbackFn.call(T, M._values[i], M._keys[i], M);
				}
			}
			// 8. Return undefined.
			return undefined;
		}
	);

	// 23.1.3.6. Map.prototype.get ( key )
	CreateMethodProperty(Map.prototype, 'get', function get(key) {
			// 1. Let M be the this value.
			var M = this;
			// 2. If Type(M) is not Object, throw a TypeError exception.
			if (Type(M) !== 'object') {
				throw new TypeError('Method Map.prototype.get called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 3. If M does not have a [[MapData]] internal slot, throw a TypeError exception.
			if (M._es6Map !== true) {
				throw new TypeError('Method Map.prototype.get called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 4. Let entries be the List that is M.[[MapData]].
			// 5. For each Record {[[Key]], [[Value]]} p that is an element of entries, do
				// a. If p.[[Key]] is not empty and SameValueZero(p.[[Key]], key) is true, return p.[[Value]].
			// 6. Return undefined.

			// Implement steps 4-6 with a more optimal algo
			var recordIndex = getRecordIndex(M, key); // O(1) access to record index
			if (recordIndex !== false) {
				var recordKey = M._keys[recordIndex];
				if (recordKey !== undefMarker && SameValueZero(recordKey, key)) {
					return M._values[recordIndex];
				}
			}

			return undefined;
		});

	// 23.1.3.7. Map.prototype.has ( key )
	CreateMethodProperty(Map.prototype, 'has', function has (key) {
			// 1. Let M be the this value.
			var M = this;
			// 2. If Type(M) is not Object, throw a TypeError exception.
			if (typeof M !== 'object') {
				throw new TypeError('Method Map.prototype.has called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 3. If M does not have a [[MapData]] internal slot, throw a TypeError exception.
			if (M._es6Map !== true) {
				throw new TypeError('Method Map.prototype.has called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 4. Let entries be the List that is M.[[MapData]].
			// 5. For each Record {[[Key]], [[Value]]} p that is an element of entries, do
				// a. If p.[[Key]] is not empty and SameValueZero(p.[[Key]], key) is true, return true.
			// 6. Return false.

			// Implement steps 4-6 with a more optimal algo
			var recordIndex = getRecordIndex(M, key); // O(1) access to record index
			if (recordIndex !== false) {
				var recordKey = M._keys[recordIndex];
				if (recordKey !== undefMarker && SameValueZero(recordKey, key)) {
					return true;
				}
			}

			return false;
		});

	// 23.1.3.8. Map.prototype.keys ( )
	CreateMethodProperty(Map.prototype, 'keys', function keys () {
			// 1. Let M be the this value.
			var M = this;
			// 2. Return ? CreateMapIterator(M, "key").
			return CreateMapIterator(M, "key");
		});

	// 23.1.3.9. Map.prototype.set ( key, value )
	CreateMethodProperty(Map.prototype, 'set', function set(key, value) {
			// 1. Let M be the this value.
			var M = this;
			// 2. If Type(M) is not Object, throw a TypeError exception.
			if (Type(M) !== 'object') {
				throw new TypeError('Method Map.prototype.set called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 3. If M does not have a [[MapData]] internal slot, throw a TypeError exception.
			if (M._es6Map !== true) {
				throw new TypeError('Method Map.prototype.set called on incompatible receiver ' + Object.prototype.toString.call(M));
			}
			// 4. Let entries be the List that is M.[[MapData]].
			// 5. For each Record {[[Key]], [[Value]]} p that is an element of entries, do
			// 6. If key is -0, let key be +0.
			// 7. Let p be the Record {[[Key]]: key, [[Value]]: value}.
			// 8. Append p as the last element of entries.
			// 9. Return M.

			// Strictly following the above steps 4-9 will lead to an inefficient algorithm.
			// Step 8 also doesn't seem to be required if an entry already exists
			var recordIndex = getRecordIndex(M, key); // O(1) access to record index
			if (recordIndex !== false) {
				// update path
				M._values[recordIndex] = value;
			} else {
				// eslint-disable-next-line no-compare-neg-zero
				if (key === -0) {
					key = 0;
				}
				var p = {
					'[[Key]]': key,
					'[[Value]]': value
				};
				M._keys.push(p['[[Key]]']);
				M._values.push(p['[[Value]]']);
				setHashIndex(M, key, M._keys.length - 1); // update lookup table
				++M._size;
				if (!supportsGetters) {
					M.size = M._size;
				}
			}
			return M;
		});

	// 23.1.3.10. get Map.prototype.size
	if (supportsGetters) {
		Object.defineProperty(Map.prototype, 'size', {
			configurable: true,
			enumerable: false,
			get: function () {
				// 1. Let M be the this value.
				var M = this;
				// 2. If Type(M) is not Object, throw a TypeError exception.
				if (Type(M) !== 'object') {
					throw new TypeError('Method Map.prototype.size called on incompatible receiver ' + Object.prototype.toString.call(M));
				}
				// 3. If M does not have a [[MapData]] internal slot, throw a TypeError exception.
				if (M._es6Map !== true) {
					throw new TypeError('Method Map.prototype.size called on incompatible receiver ' + Object.prototype.toString.call(M));
				}
				// 4. Let entries be the List that is M.[[MapData]].
				// 5. Let count be 0.
				// 6. For each Record {[[Key]], [[Value]]} p that is an element of entries, do
					// 6a. If p.[[Key]] is not empty, set count to count+1.
				// 7. Return count.

				// Implement 4-7 more efficently by returning pre-computed property
				return this._size;
			},
			set: undefined
		});
	}

	// 23.1.3.11. Map.prototype.values ( )
	CreateMethodProperty(Map.prototype, 'values', function values () {
			// 1. Let M be the this value.
			var M = this;
			// 2. Return ? CreateMapIterator(M, "value").
			return CreateMapIterator(M, 'value');
		}
	);

	// 23.1.3.12. Map.prototype [ @@iterator ] ( )
	// The initial value of the @@iterator property is the same function object as the initial value of the entries property.
	CreateMethodProperty(Map.prototype, Symbol.iterator, Map.prototype.entries);

	// 23.1.3.13. Map.prototype [ @@toStringTag ]
	// The initial value of the @@toStringTag property is the String value "Map".
	// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: true }.

	// Polyfill.io - Safari 8 implements Map.name but as a non-configurable property, which means it would throw an error if we try and configure it here.
	if (!('name' in Map)) {
		// 19.2.4.2 name
		Object.defineProperty(Map, 'name', {
			configurable: true,
			enumerable: false,
			writable: false,
			value: 'Map'
		});
	}

	// 23.1.5.1. CreateMapIterator ( map, kind )
	function CreateMapIterator(map, kind) {
		// 1. If Type(map) is not Object, throw a TypeError exception.
		if (Type(map) !== 'object') {
			throw new TypeError('createMapIterator called on incompatible receiver ' + Object.prototype.toString.call(map));
		}
		// 2. If map does not have a [[MapData]] internal slot, throw a TypeError exception.
		if (map._es6Map !== true) {
			throw new TypeError('createMapIterator called on incompatible receiver ' + Object.prototype.toString.call(map));
		}
		// 3. Let iterator be ObjectCreate(%MapIteratorPrototype%, « [[Map]], [[MapNextIndex]], [[MapIterationKind]] »).
		var iterator = Object.create(MapIteratorPrototype);
		// 4. Set iterator.[[Map]] to map.
		Object.defineProperty(iterator, '[[Map]]', {
			configurable: true,
			enumerable: false,
			writable: true,
			value: map
		});
		// 5. Set iterator.[[MapNextIndex]] to 0.
		Object.defineProperty(iterator, '[[MapNextIndex]]', {
			configurable: true,
			enumerable: false,
			writable: true,
			value: 0
		});
		// 6. Set iterator.[[MapIterationKind]] to kind.
		Object.defineProperty(iterator, '[[MapIterationKind]]', {
			configurable: true,
			enumerable: false,
			writable: true,
			value: kind
		});
		// 7. Return iterator.
		return iterator;
	}

	// 23.1.5.2. The %MapIteratorPrototype% Object
	var MapIteratorPrototype = {};
	// Polyfill.io - We use this as a quick way to check if an object is a Map Iterator instance.
	Object.defineProperty(MapIteratorPrototype, 'isMapIterator', {
		configurable: false,
		enumerable: false,
		writable: false,
		value: true
	});

	// 23.1.5.2.1. %MapIteratorPrototype%.next ( )
	CreateMethodProperty(MapIteratorPrototype, 'next', function next() {
			// 1. Let O be the this value.
			var O = this;
			// 2. If Type(O) is not Object, throw a TypeError exception.
			if (Type(O) !== 'object') {
				throw new TypeError('Method %MapIteratorPrototype%.next called on incompatible receiver ' + Object.prototype.toString.call(O));
			}
			// 3. If O does not have all of the internal slots of a Map Iterator Instance (23.1.5.3), throw a TypeError exception.
			if (!O.isMapIterator) {
				throw new TypeError('Method %MapIteratorPrototype%.next called on incompatible receiver ' + Object.prototype.toString.call(O));
			}
			// 4. Let m be O.[[Map]].
			var m = O['[[Map]]'];
			// 5. Let index be O.[[MapNextIndex]].
			var index = O['[[MapNextIndex]]'];
			// 6. Let itemKind be O.[[MapIterationKind]].
			var itemKind = O['[[MapIterationKind]]'];
			// 7. If m is undefined, return CreateIterResultObject(undefined, true).
			if (m === undefined) {
				return CreateIterResultObject(undefined, true);
			}
			// 8. Assert: m has a [[MapData]] internal slot.
			if (!m._es6Map) {
				throw new Error(Object.prototype.toString.call(m) + ' has a [[MapData]] internal slot.');
			}
			// 9. Let entries be the List that is m.[[MapData]].
			var entries = m._keys;
			// 10. Let numEntries be the number of elements of entries.
			var numEntries = entries.length;
			// 11. NOTE: numEntries must be redetermined each time this method is evaluated.
			// 12. Repeat, while index is less than numEntries,
			while (index < numEntries) {
				// a. Let e be the Record {[[Key]], [[Value]]} that is the value of entries[index].
				var e = Object.create(null);
				e['[[Key]]'] = m._keys[index];
				e['[[Value]]'] = m._values[index];
				// b. Set index to index+1.
				index = index + 1;
				// c. Set O.[[MapNextIndex]] to index.
				O['[[MapNextIndex]]'] = index;
				// d. If e.[[Key]] is not empty, then
				if (e['[[Key]]'] !== undefMarker) {
					// i. If itemKind is "key", let result be e.[[Key]].
					if (itemKind === 'key') {
						var result = e['[[Key]]'];
						// ii. Else if itemKind is "value", let result be e.[[Value]].
					} else if (itemKind === 'value') {
						result = e['[[Value]]'];
						// iii. Else,
					} else {
						// 1. Assert: itemKind is "key+value".
						if (itemKind !== 'key+value') {
							throw new Error();
						}
						// 2. Let result be CreateArrayFromList(« e.[[Key]], e.[[Value]] »).
						result = [
							e['[[Key]]'],
							e['[[Value]]']
						];
					}
					// iv. Return CreateIterResultObject(result, false).
					return CreateIterResultObject(result, false);
				}
			}
			// 13. Set O.[[Map]] to undefined.
			O['[[Map]]'] = undefined;
			// 14. Return CreateIterResultObject(undefined, true).
			return CreateIterResultObject(undefined, true);
		}
	);

	// 23.1.5.2.2 %MapIteratorPrototype% [ @@toStringTag ]
	// The initial value of the @@toStringTag property is the String value "Map Iterator".
	// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: true }.

	CreateMethodProperty(MapIteratorPrototype, Symbol.iterator, function iterator() {
			return this;
		}
	);

	// Export the object
	try {
		CreateMethodProperty(global, 'Map', Map);
	} catch (e) {
		// IE8 throws an error here if we set enumerable to false.
		// More info on table 2: https://msdn.microsoft.com/en-us/library/dd229916(v=vs.85).aspx
		global.Map = Map;
	}
}(self));

}

if (!("Set"in self&&function(){try{var e=new self.Set([1,2])
return 0===self.Set.length&&2===e.size&&"Symbol"in self&&"iterator"in self.Symbol&&"function"==typeof e[self.Symbol.iterator]}catch(t){return!1}}()
)) {

// Set
/* global CreateIterResultObject, CreateMethodProperty, GetIterator, IsCallable, IteratorClose, IteratorStep, IteratorValue, OrdinaryCreateFromConstructor, SameValueZero, Symbol */
(function (global) {
	var supportsGetters = (function () {
		try {
			var a = {};
			Object.defineProperty(a, 't', {
				configurable: true,
				enumerable: false,
				get: function () {
					return true;
				},
				set: undefined
			});
			return !!a.t;
		} catch (e) {
			return false;
		}
	}());

	// Deleted set items mess with iterator pointers, so rather than removing them mark them as deleted. Can't use undefined or null since those both valid keys so use a private symbol.
	var undefMarker = Symbol('undef');
	// 23.2.1.1. Set ( [ iterable ] )
	var Set = function Set(/* iterable */) {
		// 1. If NewTarget is undefined, throw a TypeError exception.
		if (!(this instanceof Set)) {
			throw new TypeError('Constructor Set requires "new"');
		}
		// 2. Let set be ? OrdinaryCreateFromConstructor(NewTarget, "%SetPrototype%", « [[SetData]] »).
		var set = OrdinaryCreateFromConstructor(this, Set.prototype, {
			_values: [],
			_size: 0,
			_es6Set: true
		});

		// 3. Set set.[[SetData]] to a new empty List.
		// Polyfill.io - This step was done as part of step two.

		// Some old engines do not support ES5 getters/setters.  Since Set only requires these for the size property, we can fall back to setting the size property statically each time the size of the set changes.
		if (!supportsGetters) {
			Object.defineProperty(set, 'size', {
				configurable: true,
				enumerable: false,
				writable: true,
				value: 0
			});
		}

		// 4. If iterable is not present, let iterable be undefined.
		var iterable = arguments.length > 0 ? arguments[0] : undefined;

		// 5. If iterable is either undefined or null, return set.
		if (iterable === null || iterable === undefined) {
			return set;
		}

		// 6. Let adder be ? Get(set, "add").
		var adder = set.add;
		// 7. If IsCallable(adder) is false, throw a TypeError exception.
		if (!IsCallable(adder)) {
			throw new TypeError("Set.prototype.add is not a function");
		}

		try {
			// 8. Let iteratorRecord be ? GetIterator(iterable).
			var iteratorRecord = GetIterator(iterable);
			// 9. Repeat,
			// eslint-disable-next-line no-constant-condition
			while (true) {
				// a. Let next be ? IteratorStep(iteratorRecord).
				var next = IteratorStep(iteratorRecord);
				// b. If next is false, return set.
				if (next === false) {
					return set;
				}
				// c. Let nextValue be ? IteratorValue(next).
				var nextValue = IteratorValue(next);
				// d. Let status be Call(adder, set, « nextValue.[[Value]] »).
				try {
					adder.call(set, nextValue);
				} catch (e) {
					// e. If status is an abrupt completion, return ? IteratorClose(iteratorRecord, status).
					return IteratorClose(iteratorRecord, e);
				}
			}
		} catch (e) {
			// Polyfill.io - For user agents which do not have iteration methods on argument objects or arrays, we can special case those.
			if (Array.isArray(iterable) ||
				Object.prototype.toString.call(iterable) === '[object Arguments]' ||
				// IE 7 & IE 8 return '[object Object]' for the arguments object, we can detect by checking for the existence of the callee property
				(!!iterable.callee)) {
				var index;
				var length = iterable.length;
				for (index = 0; index < length; index++) {
					adder.call(set, iterable[index]);
				}
			} else {
				throw (e);
			}
		}
		return set;
	};

	// 23.2.2.1. Set.prototype
	// The initial value of Set.prototype is the intrinsic %SetPrototype% object.
	// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: false }.
	Object.defineProperty(Set, 'prototype', {
		configurable: false,
		enumerable: false,
		writable: false,
		value: {}
	});

	// 23.2.2.2 get Set [ @@species ]
	if (supportsGetters) {
		Object.defineProperty(Set, Symbol.species, {
			configurable: true,
			enumerable: false,
			get: function () {
				// 1. Return the this value.
				return this;
			},
			set: undefined
		});
	} else {
		CreateMethodProperty(Set, Symbol.species, Set);
	}

	// 23.2.3.1. Set.prototype.add ( value )
	CreateMethodProperty(Set.prototype, 'add', function add(value) {
			// 1. Let S be the this value.
			var S = this;
			// 2. If Type(S) is not Object, throw a TypeError exception.
			if (typeof S !== 'object') {
				throw new TypeError('Method Set.prototype.add called on incompatible receiver ' + Object.prototype.toString.call(S));
			}
			// 3. If S does not have a [[SetData]] internal slot, throw a TypeError exception.
			if (S._es6Set !== true) {
				throw new TypeError('Method Set.prototype.add called on incompatible receiver ' + Object.prototype.toString.call(S));
			}
			// 4. Let entries be the List that is S.[[SetData]].
			var entries = S._values;
			// 5. For each e that is an element of entries, do
			for (var i = 0; i < entries.length; i++) {
				var e = entries[i];
				// a. If e is not empty and SameValueZero(e, value) is true, then
				if (e !== undefMarker && SameValueZero(e, value)) {
					// i. Return S.
					return S;
				}
			}
			// 6. If value is -0, let value be +0.
			if (value === 0 && 1/value === -Infinity) {
				value = 0;
			}
			// 7. Append value as the last element of entries.
			S._values.push(value);

			this._size = ++this._size;
			if (!supportsGetters) {
				this.size = this._size;
			}
			// 8. Return S.
			return S;
		});

	// 23.2.3.2. Set.prototype.clear ( )
	CreateMethodProperty(Set.prototype, 'clear', function clear() {
			// 1. Let S be the this value.
			var S = this;
			// 2. If Type(S) is not Object, throw a TypeError exception.
			if (typeof S !== 'object') {
				throw new TypeError('Method Set.prototype.clear called on incompatible receiver ' + Object.prototype.toString.call(S));
			}
			// 3. If S does not have a [[SetData]] internal slot, throw a TypeError exception.
			if (S._es6Set !== true) {
				throw new TypeError('Method Set.prototype.clear called on incompatible receiver ' + Object.prototype.toString.call(S));
			}
			// 4. Let entries be the List that is S.[[SetData]].
			var entries = S._values;
			// 5. For each e that is an element of entries, do
			for (var i = 0; i < entries.length; i++) {
				// a. Replace the element of entries whose value is e with an element whose value is empty.
				entries[i] = undefMarker;
			}
			this._size = 0;
			if (!supportsGetters) {
				this.size = this._size;
			}
			// 6. Return undefined.
			return undefined;
		});

	// 23.2.3.3. Set.prototype.constructor
	CreateMethodProperty(Set.prototype, 'constructor', Set);

	// 23.2.3.4. Set.prototype.delete ( value )
	CreateMethodProperty(Set.prototype, 'delete', function (value) {
			// 1. Let S be the this value.
			var S = this;
			// 2. If Type(S) is not Object, throw a TypeError exception.
			if (typeof S !== 'object') {
				throw new TypeError('Method Set.prototype.delete called on incompatible receiver ' + Object.prototype.toString.call(S));
			}
			// 3. If S does not have a [[SetData]] internal slot, throw a TypeError exception.
			if (S._es6Set !== true) {
				throw new TypeError('Method Set.prototype.delete called on incompatible receiver ' + Object.prototype.toString.call(S));
			}
			// 4. Let entries be the List that is S.[[SetData]].
			var entries = S._values;
			// 5. For each e that is an element of entries, do
			for (var i = 0; i < entries.length; i++) {
				var e = entries[i];
				// a. If e is not empty and SameValueZero(e, value) is true, then
				if (e !== undefMarker && SameValueZero(e, value)) {
					// i. Replace the element of entries whose value is e with an element whose value is empty.
					entries[i] = undefMarker;

					this._size = --this._size;
					if (!supportsGetters) {
						this.size = this._size;
					}
					// ii. Return true.
					return true;
				}
			}
			// 6. Return false.
			return false;
		}
	);

	// 23.2.3.5. Set.prototype.entries ( )
	CreateMethodProperty(Set.prototype, 'entries', function entries() {
			// 1. Let S be the this value.
			var S = this;
			// 2. Return ? CreateSetIterator(S, "key+value").
			return CreateSetIterator(S, 'key+value');
		}
	);

	// 23.2.3.6. Set.prototype.forEach ( callbackfn [ , thisArg ] )
	CreateMethodProperty(Set.prototype, 'forEach', function forEach(callbackFn /*[ , thisArg ]*/) {
			// 1. Let S be the this value.
			var S = this;
			// 2. If Type(S) is not Object, throw a TypeError exception.
			if (typeof S !== 'object') {
				throw new TypeError('Method Set.prototype.forEach called on incompatible receiver ' + Object.prototype.toString.call(S));
			}
			// 3. If S does not have a [[SetData]] internal slot, throw a TypeError exception.
			if (S._es6Set !== true) {
				throw new TypeError('Method Set.prototype.forEach called on incompatible receiver ' + Object.prototype.toString.call(S));
			}
			// 4. If IsCallable(callbackfn) is false, throw a TypeError exception.
			if (!IsCallable(callbackFn)) {
				throw new TypeError(Object.prototype.toString.call(callbackFn) + ' is not a function.');
			}
			// 5. If thisArg is present, let T be thisArg; else let T be undefined.
			if (arguments[1]) {
				var T = arguments[1];
			}
			// 6. Let entries be the List that is S.[[SetData]].
			var entries = S._values;
			// 7. For each e that is an element of entries, in original insertion order, do
			for (var i = 0; i < entries.length; i++) {
				var e = entries[i];
				// a. If e is not empty, then
				if (e !== undefMarker) {
					// i. Perform ? Call(callbackfn, T, « e, e, S »).
					callbackFn.call(T, e, e, S);
				}
			}
			// 8. Return undefined.
			return undefined;
		}
	);

	// 23.2.3.7. Set.prototype.has ( value )
	CreateMethodProperty(Set.prototype, 'has', function has(value) {
			// 1. Let S be the this value.
			var S = this;
			// 2. If Type(S) is not Object, throw a TypeError exception.
			if (typeof S !== 'object') {
				throw new TypeError('Method Set.prototype.forEach called on incompatible receiver ' + Object.prototype.toString.call(S));
			}
			// 3. If S does not have a [[SetData]] internal slot, throw a TypeError exception.
			if (S._es6Set !== true) {
				throw new TypeError('Method Set.prototype.forEach called on incompatible receiver ' + Object.prototype.toString.call(S));
			}
			// 4. Let entries be the List that is S.[[SetData]].
			var entries = S._values;
			// 5. For each e that is an element of entries, do
			for (var i = 0; i < entries.length; i++) {
				var e = entries[i];
				// a. If e is not empty and SameValueZero(e, value) is true, return true.
				if (e !== undefMarker && SameValueZero(e, value)) {
					return true;
				}
			}
			// 6. Return false.
			return false;
		}
	);

	// Polyfill.io - We need to define Set.prototype.values before Set.prototype.keys because keys is a reference to values.
	// 23.2.3.10. Set.prototype.values()
	var values = function values() {
		// 1. Let S be the this value.
		var S = this;
		// 2. Return ? CreateSetIterator(S, "value").
		return CreateSetIterator(S, "value");
	};
	CreateMethodProperty(Set.prototype, 'values', values);

	// 23.2.3.8 Set.prototype.keys ( )
	// The initial value of the keys property is the same function object as the initial value of the values property.
	CreateMethodProperty(Set.prototype, 'keys', values);

	// 23.2.3.9. get Set.prototype.size
	if (supportsGetters) {
		Object.defineProperty(Set.prototype, 'size', {
			configurable: true,
			enumerable: false,
			get: function () {
				// 1. Let S be the this value.
				var S = this;
				// 2. If Type(S) is not Object, throw a TypeError exception.
				if (typeof S !== 'object') {
					throw new TypeError('Method Set.prototype.size called on incompatible receiver ' + Object.prototype.toString.call(S));
				}
				// 3. If S does not have a [[SetData]] internal slot, throw a TypeError exception.
				if (S._es6Set !== true) {
					throw new TypeError('Method Set.prototype.size called on incompatible receiver ' + Object.prototype.toString.call(S));
				}
				// 4. Let entries be the List that is S.[[SetData]].
				var entries = S._values;
				// 5. Let count be 0.
				var count = 0;
				// 6. For each e that is an element of entries, do
				for (var i = 0; i < entries.length; i++) {
					var e = entries[i];
					// a. If e is not empty, set count to count+1.
					if (e !== undefMarker) {
						count = count + 1;
					}
				}
				// 7. Return count.
				return count;
			},
			set: undefined
		});
	}

	// 23.2.3.11. Set.prototype [ @@iterator ] ( )
	// The initial value of the @@iterator property is the same function object as the initial value of the values property.
	CreateMethodProperty(Set.prototype, Symbol.iterator, values);

	// 23.2.3.12. Set.prototype [ @@toStringTag ]
	// The initial value of the @@toStringTag property is the String value "Set".
	// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: true }.

	// Polyfill.io - Safari 8 implements Set.name but as a non-configurable property, which means it would throw an error if we try and configure it here.
	if (!('name' in Set)) {
		// 19.2.4.2 name
		Object.defineProperty(Set, 'name', {
			configurable: true,
			enumerable: false,
			writable: false,
			value: 'Set'
		});
	}

	// 23.2.5.1. CreateSetIterator ( set, kind )
	function CreateSetIterator(set, kind) {
		// 1. If Type(set) is not Object, throw a TypeError exception.
		if (typeof set !== 'object') {
			throw new TypeError('createSetIterator called on incompatible receiver ' + Object.prototype.toString.call(set));
		}
		// 2. If set does not have a [[SetData]] internal slot, throw a TypeError exception.
		if (set._es6Set !== true) {
			throw new TypeError('createSetIterator called on incompatible receiver ' + Object.prototype.toString.call(set));
		}
		// 3. Let iterator be ObjectCreate(%SetIteratorPrototype%, « [[IteratedSet]], [[SetNextIndex]], [[SetIterationKind]] »).
		var iterator = Object.create(SetIteratorPrototype);
		// 4. Set iterator.[[IteratedSet]] to set.
		Object.defineProperty(iterator, '[[IteratedSet]]', {
			configurable: true,
			enumerable: false,
			writable: true,
			value: set
		});
		// 5. Set iterator.[[SetNextIndex]] to 0.
		Object.defineProperty(iterator, '[[SetNextIndex]]', {
			configurable: true,
			enumerable: false,
			writable: true,
			value: 0
		});
		// 6. Set iterator.[[SetIterationKind]] to kind.
		Object.defineProperty(iterator, '[[SetIterationKind]]', {
			configurable: true,
			enumerable: false,
			writable: true,
			value: kind
		});
		// 7. Return iterator.
		return iterator;
	}

	// 23.2.5.2. The %SetIteratorPrototype% Object
	var SetIteratorPrototype = {};
	//Polyfill.io - We add this property to help us identify what is a set iterator.
	Object.defineProperty(SetIteratorPrototype, 'isSetIterator', {
		configurable: false,
		enumerable: false,
		writable: false,
		value: true
	});

	// 23.2.5.2.1. %SetIteratorPrototype%.next ( )
	CreateMethodProperty(SetIteratorPrototype, 'next', function next() {
		// 1. Let O be the this value.
		var O = this;
		// 2. If Type(O) is not Object, throw a TypeError exception.
		if (typeof O !== 'object') {
			throw new TypeError('Method %SetIteratorPrototype%.next called on incompatible receiver ' + Object.prototype.toString.call(O));
		}
		// 3. If O does not have all of the internal slots of a Set Iterator Instance (23.2.5.3), throw a TypeError exception.
		if (!O.isSetIterator) {
			throw new TypeError('Method %SetIteratorPrototype%.next called on incompatible receiver ' + Object.prototype.toString.call(O));
		}
		// 4. Let s be O.[[IteratedSet]].
		var s = O['[[IteratedSet]]'];
		// 5. Let index be O.[[SetNextIndex]].
		var index = O['[[SetNextIndex]]'];
		// 6. Let itemKind be O.[[SetIterationKind]].
		var itemKind = O['[[SetIterationKind]]'];
		// 7. If s is undefined, return CreateIterResultObject(undefined, true).
		if (s === undefined) {
			return CreateIterResultObject(undefined, true);
		}
		// 8. Assert: s has a [[SetData]] internal slot.
		if (!s._es6Set) {
			throw new Error(Object.prototype.toString.call(s) + ' does not have [[SetData]] internal slot.');
		}
		// 9. Let entries be the List that is s.[[SetData]].
		var entries = s._values;
		// 10. Let numEntries be the number of elements of entries.
		var numEntries = entries.length;
		// 11. NOTE: numEntries must be redetermined each time this method is evaluated.
		// 12. Repeat, while index is less than numEntries,
		while (index < numEntries) {
			// a. Let e be entries[index].
			var e = entries[index];
			// b. Set index to index+1.
			index = index + 1;
			// c. Set O.[[SetNextIndex]] to index.
			O['[[SetNextIndex]]'] = index;
			// d. If e is not empty, then
			if (e !== undefMarker) {
				// i. If itemKind is "key+value", then
				if (itemKind === 'key+value') {
					// 1. Return CreateIterResultObject(CreateArrayFromList(« e, e »), false).
					return CreateIterResultObject([e, e], false);
				}
				// ii. Return CreateIterResultObject(e, false).
				return CreateIterResultObject(e, false);
			}
		}
		// 13. Set O.[[IteratedSet]] to undefined.
		O['[[IteratedSet]]'] = undefined;
		// 14. Return CreateIterResultObject(undefined, true).
		return CreateIterResultObject(undefined, true);
	});

	// 23.2.5.2.2. %SetIteratorPrototype% [ @@toStringTag ]
	// The initial value of the @@toStringTag property is the String value "Set Iterator".
	// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: true }.

	CreateMethodProperty(SetIteratorPrototype, Symbol.iterator, function iterator() {
			return this;
		}
	);

	// Export the object
	try {
		CreateMethodProperty(global, 'Set', Set);
	} catch (e) {
		// IE8 throws an error here if we set enumerable to false.
		// More info on table 2: https://msdn.microsoft.com/en-us/library/dd229916(v=vs.85).aspx
		global.Set = Set;
	}

}(self));

}

if (!("from"in Array&&function(){try{return Array.from({length:-Infinity}),"a"===Array.from(new self.Set(["a"]))[0]&&"a"===Array.from(new self.Map([["a","one"]]))[0][0]}catch(r){return!1}}()
)) {

// Array.from
/* globals
	IsCallable, GetMethod, Symbol, IsConstructor, Construct, ArrayCreate, GetIterator, IteratorClose,
	ToString, IteratorStep, IteratorValue, Call, CreateDataPropertyOrThrow, ToObject, ToLength, Get, CreateMethodProperty
*/
(function () {
	var toString = Object.prototype.toString;
	var stringMatch = String.prototype.match;
	// A cross-realm friendly way to detect if a value is a String object or literal.
	function isString(value) {
		if (typeof value === 'string') { return true; }
		if (typeof value !== 'object') { return false; }
		return toString.call(value) === '[object String]';
	}

	// 22.1.2.1. Array.from ( items [ , mapfn [ , thisArg ] ] )
	CreateMethodProperty(Array, 'from', function from(items /* [ , mapfn [ , thisArg ] ] */) { // eslint-disable-line no-undef
		// 1. Let C be the this value.
		var C = this;
		// 2. If mapfn is undefined, let mapping be false.
		var mapfn = arguments.length > 1 ? arguments[1] : undefined;
		if (mapfn === undefined) {
			var mapping = false;
			// 3. Else,
		} else {
			// a. If IsCallable(mapfn) is false, throw a TypeError exception.
			if (IsCallable(mapfn) === false) {
				throw new TypeError(Object.prototype.toString.call(mapfn) + ' is not a function.');
			}
			// b. If thisArg is present, let T be thisArg; else let T be undefined.
			var thisArg = arguments.length > 2 ? arguments[2] : undefined;
			if (thisArg !== undefined) {
				var T = thisArg;
			} else {
				T = undefined;
			}
			// c. Let mapping be true.
			mapping = true;

		}
		// 4. Let usingIterator be ? GetMethod(items, @@iterator).
		var usingIterator = GetMethod(items, Symbol.iterator);
		// 5. If usingIterator is not undefined, then
		if (usingIterator !== undefined) {
			// a. If IsConstructor(C) is true, then
			if (IsConstructor(C)) {
				// i. Let A be ? Construct(C).
				var A = Construct(C);
				// b. Else,
			} else {
				// i. Let A be ! ArrayCreate(0).
				A = ArrayCreate(0);
			}
			// c. Let iteratorRecord be ? GetIterator(items, usingIterator).
			var iteratorRecord = GetIterator(items, usingIterator);
			// d. Let k be 0.
			var k = 0;
			// e. Repeat,
			// eslint-disable-next-line no-constant-condition
			while (true) {
				// i. If k ≥ 2^53-1, then
				if (k >= (Math.pow(2, 53) - 1)) {
					// 1. Let error be Completion{[[Type]]: throw, [[Value]]: a newly created TypeError object, [[Target]]: empty}.
					var error = new TypeError('Iteration count can not be greater than or equal 9007199254740991.');
					// 2. Return ? IteratorClose(iteratorRecord, error).
					return IteratorClose(iteratorRecord, error);
				}
				// ii. Let Pk be ! ToString(k).
				var Pk = ToString(k);
				// iii. Let next be ? IteratorStep(iteratorRecord).
				var next = IteratorStep(iteratorRecord);
				// iv. If next is false, then
				if (next === false) {
					// 1. Perform ? Set(A, "length", k, true).
					A.length = k;
					// 2. Return A.
					return A;
				}
				// v. Let nextValue be ? IteratorValue(next).
				var nextValue = IteratorValue(next);
				// vi. If mapping is true, then
				if (mapping) {
					try {
						// Polyfill.io - The try catch accounts for step 2.
						// 1. Let mappedValue be Call(mapfn, T, « nextValue, k »).
						var mappedValue = Call(mapfn, T, [nextValue, k]);
						// 2. If mappedValue is an abrupt completion, return ? IteratorClose(iteratorRecord, mappedValue).
						// 3. Let mappedValue be mappedValue.[[Value]].
					} catch (e) {
						return IteratorClose(iteratorRecord, e);
					}

					// vii. Else, let mappedValue be nextValue.
				} else {
					mappedValue = nextValue;
				}
				try {
					// Polyfill.io - The try catch accounts for step ix.
					// viii. Let defineStatus be CreateDataPropertyOrThrow(A, Pk, mappedValue).
					CreateDataPropertyOrThrow(A, Pk, mappedValue);
					// ix. If defineStatus is an abrupt completion, return ? IteratorClose(iteratorRecord, defineStatus).
				} catch (e) {
					return IteratorClose(iteratorRecord, e);
				}
				// x. Increase k by 1.
				k = k + 1;
			}
		}
		// 6. NOTE: items is not an Iterable so assume it is an array-like object.
		// 7. Let arrayLike be ! ToObject(items).
		// Polyfill.io - For Strings we need to split astral symbols into surrogate pairs.
		if (isString(items)) {
			var arrayLike = stringMatch.call(items, /[\uD800-\uDBFF][\uDC00-\uDFFF]?|[^\uD800-\uDFFF]|./g) || [];
		} else {
			arrayLike = ToObject(items);
		}
		// 8. Let len be ? ToLength(? Get(arrayLike, "length")).
		var len = ToLength(Get(arrayLike, "length"));
		// 9. If IsConstructor(C) is true, then
		if (IsConstructor(C)) {
			// a. Let A be ? Construct(C, « len »).
			A = Construct(C, [len]);
			// 10. Else,
		} else {
			// a. Let A be ? ArrayCreate(len).
			A = ArrayCreate(len);
		}
		// 11. Let k be 0.
		k = 0;
		// 12. Repeat, while k < len
		while (k < len) {
			// a. Let Pk be ! ToString(k).
			Pk = ToString(k);
			// b. Let kValue be ? Get(arrayLike, Pk).
			var kValue = Get(arrayLike, Pk);
			// c. If mapping is true, then
			if (mapping === true) {
				// i. Let mappedValue be ? Call(mapfn, T, « kValue, k »).
				mappedValue = Call(mapfn, T, [kValue, k]);
				// d. Else, let mappedValue be kValue.
			} else {
				mappedValue = kValue;
			}
			// e. Perform ? CreateDataPropertyOrThrow(A, Pk, mappedValue).
			CreateDataPropertyOrThrow(A, Pk, mappedValue);
			// f. Increase k by 1.
			k = k + 1;
		}
		// 13. Perform ? Set(A, "length", len, true).
		A.length = len;
		// 14. Return A.
		return A;
	});
}());

}

if (!("Symbol"in self&&"split"in self.Symbol
)) {

// Symbol.split
/* global Symbol */
Object.defineProperty(Symbol, 'split', { value: Symbol('split') });

}

if (!("Symbol"in self&&"toPrimitive"in self.Symbol
)) {

// Symbol.toPrimitive
/* global Symbol */
Object.defineProperty(Symbol, 'toPrimitive', { value: Symbol('toPrimitive') });

}

if (!("Symbol"in self&&"toStringTag"in self.Symbol
)) {

// Symbol.toStringTag
/* global Symbol */
Object.defineProperty(Symbol, 'toStringTag', {
	value: Symbol('toStringTag')
});

}


// _Iterator
/* global Symbol */
// A modification of https://github.com/medikoo/es6-iterator
// Copyright (C) 2013-2015 Mariusz Nowak (www.medikoo.com)

var Iterator = (function () { // eslint-disable-line no-unused-vars
	var clear = function () {
		this.length = 0;
		return this;
	};
	var callable = function (fn) {
		if (typeof fn !== 'function') throw new TypeError(fn + " is not a function");
		return fn;
	};

	var Iterator = function (list, context) {
		if (!(this instanceof Iterator)) {
			return new Iterator(list, context);
		}
		Object.defineProperties(this, {
			__list__: {
				writable: true,
				value: list
			},
			__context__: {
				writable: true,
				value: context
			},
			__nextIndex__: {
				writable: true,
				value: 0
			}
		});
		if (!context) return;
		callable(context.on);
		context.on('_add', this._onAdd.bind(this));
		context.on('_delete', this._onDelete.bind(this));
		context.on('_clear', this._onClear.bind(this));
	};

	Object.defineProperties(Iterator.prototype, Object.assign({
		constructor: {
			value: Iterator,
			configurable: true,
			enumerable: false,
			writable: true
		},
		_next: {
			value: function () {
				var i;
				if (!this.__list__) return;
				if (this.__redo__) {
					i = this.__redo__.shift();
					if (i !== undefined) return i;
				}
				if (this.__nextIndex__ < this.__list__.length) return this.__nextIndex__++;
				this._unBind();
			},
			configurable: true,
			enumerable: false,
			writable: true
		},
		next: {
			value: function () {
				return this._createResult(this._next());
			},
			configurable: true,
			enumerable: false,
			writable: true
		},
		_createResult: {
			value: function (i) {
				if (i === undefined) return {
					done: true,
					value: undefined
				};
				return {
					done: false,
					value: this._resolve(i)
				};
			},
			configurable: true,
			enumerable: false,
			writable: true
		},
		_resolve: {
			value: function (i) {
				return this.__list__[i];
			},
			configurable: true,
			enumerable: false,
			writable: true
		},
		_unBind: {
			value: function () {
				this.__list__ = null;
				delete this.__redo__;
				if (!this.__context__) return;
				this.__context__.off('_add', this._onAdd.bind(this));
				this.__context__.off('_delete', this._onDelete.bind(this));
				this.__context__.off('_clear', this._onClear.bind(this));
				this.__context__ = null;
			},
			configurable: true,
			enumerable: false,
			writable: true
		},
		toString: {
			value: function () {
				return '[object Iterator]';
			},
			configurable: true,
			enumerable: false,
			writable: true
		}
	}, {
		_onAdd: {
			value: function (index) {
				if (index >= this.__nextIndex__) return;
				++this.__nextIndex__;
				if (!this.__redo__) {
					Object.defineProperty(this, '__redo__', {
						value: [index],
						configurable: true,
						enumerable: false,
						writable: false
					});
					return;
				}
				this.__redo__.forEach(function (redo, i) {
					if (redo >= index) this.__redo__[i] = ++redo;
				}, this);
				this.__redo__.push(index);
			},
			configurable: true,
			enumerable: false,
			writable: true
		},
		_onDelete: {
			value: function (index) {
				var i;
				if (index >= this.__nextIndex__) return;
				--this.__nextIndex__;
				if (!this.__redo__) return;
				i = this.__redo__.indexOf(index);
				if (i !== -1) this.__redo__.splice(i, 1);
				this.__redo__.forEach(function (redo, i) {
					if (redo > index) this.__redo__[i] = --redo;
				}, this);
			},
			configurable: true,
			enumerable: false,
			writable: true
		},
		_onClear: {
			value: function () {
				if (this.__redo__) clear.call(this.__redo__);
				this.__nextIndex__ = 0;
			},
			configurable: true,
			enumerable: false,
			writable: true
		}
	}));

	Object.defineProperty(Iterator.prototype, Symbol.iterator, {
		value: function () {
			return this;
		},
		configurable: true,
		enumerable: false,
		writable: true
	});
	Object.defineProperty(Iterator.prototype, Symbol.toStringTag, {
		value: 'Iterator',
		configurable: false,
		enumerable: false,
		writable: true
	});

	return Iterator;
}());

// _ArrayIterator
/* global Iterator */
// A modification of https://github.com/medikoo/es6-iterator
// Copyright (C) 2013-2015 Mariusz Nowak (www.medikoo.com)

var ArrayIterator = (function() { // eslint-disable-line no-unused-vars

	var ArrayIterator = function(arr, kind) {
		if (!(this instanceof ArrayIterator)) return new ArrayIterator(arr, kind);
		Iterator.call(this, arr);
		if (!kind) kind = 'value';
		else if (String.prototype.includes.call(kind, 'key+value')) kind = 'key+value';
		else if (String.prototype.includes.call(kind, 'key')) kind = 'key';
		else kind = 'value';
		Object.defineProperty(this, '__kind__', {
			value: kind,
			configurable: false,
			enumerable: false,
			writable: false
		});
	};
	if (Object.setPrototypeOf) Object.setPrototypeOf(ArrayIterator, Iterator.prototype);

	ArrayIterator.prototype = Object.create(Iterator.prototype, {
		constructor: {
			value: ArrayIterator,
			configurable: true,
			enumerable: false,
			writable: true
		},
		_resolve: {
			value: function(i) {
				if (this.__kind__ === 'value') return this.__list__[i];
				if (this.__kind__ === 'key+value') return [i, this.__list__[i]];
				return i;
			},
			configurable: true,
			enumerable: false,
			writable: true
		},
		toString: {
			value: function() {
				return '[object Array Iterator]';
			},
			configurable: true,
			enumerable: false,
			writable: true
		}
	});

	return ArrayIterator;
}());
if (!("Symbol"in self&&"iterator"in self.Symbol&&!!Array.prototype.entries
)) {

// Array.prototype.entries
/* global CreateMethodProperty, ToObject, ArrayIterator */
// 22.1.3.4. Array.prototype.entries ( )
CreateMethodProperty(Array.prototype, 'entries', function entries() {
	// 1. Let O be ? ToObject(this value).
	var O = ToObject(this);
	// 2. Return CreateArrayIterator(O, "key+value").
	// TODO: Add CreateArrayIterator
	return new ArrayIterator(O, 'key+value');
});

}

if (!("Symbol"in self&&"iterator"in self.Symbol&&!!Array.prototype.keys
)) {

// Array.prototype.keys
/* global CreateMethodProperty, ToObject, ArrayIterator */
// 22.1.3.14. Array.prototype.keys ( )
CreateMethodProperty(Array.prototype, 'keys', function keys() {
	// 1. Let O be ? ToObject(this value).
	var O = ToObject(this);
	// 2. Return CreateArrayIterator(O, "key").
	// TODO: Add CreateArrayIterator.
	return new ArrayIterator(O, 'key');
});

}

if (!("values"in Array.prototype
)) {

// Array.prototype.values
/* global CreateMethodProperty, Symbol, ToObject, ArrayIterator */
// 22.1.3.30/ Array.prototype.values ( )
// Polyfill.io - Firefox, Chrome and Opera have Array.prototype[Symbol.iterator], which is the exact same function as Array.prototype.values.
if ('Symbol' in self && 'iterator' in Symbol && typeof Array.prototype[Symbol.iterator] === 'function') {
	CreateMethodProperty(Array.prototype, 'values', Array.prototype[Symbol.iterator]);
} else {
	CreateMethodProperty(Array.prototype, 'values', function values () {
		// 1. Let O be ? ToObject(this value).
		var O = ToObject(this);
		// 2. Return CreateArrayIterator(O, "value").
		// TODO: Add CreateArrayIterator
		return new ArrayIterator(O, 'value');
	});
}

}

if (!("Symbol"in self&&"iterator"in self.Symbol&&!!Array.prototype[self.Symbol.iterator]
)) {

// Array.prototype.@@iterator
/* global Symbol, CreateMethodProperty */
// 22.1.3.31. Array.prototype [ @@iterator ] ( )
// The initial value of the @@iterator property is the same function object as the initial value of the  Array.prototype.values property.
CreateMethodProperty(Array.prototype, Symbol.iterator, Array.prototype.values);

}


// _StringIterator
// A modification of https://github.com/medikoo/es6-iterator
// Copyright (C) 2013-2015 Mariusz Nowak (www.medikoo.com)

/* global Iterator */

var StringIterator = (function() { // eslint-disable-line no-unused-vars

	var StringIterator = function (str) {
		if (!(this instanceof StringIterator)) return new StringIterator(str);
		str = String(str);
		Iterator.call(this, str);
		Object.defineProperty(this, '__length__', {
			value: str.length,
			configurable: false,
			enumerable: false,
			writable: false
		});
	};
	if (Object.setPrototypeOf) Object.setPrototypeOf(StringIterator, Iterator);

	StringIterator.prototype = Object.create(Iterator.prototype, {
		constructor: {
			value: StringIterator,
			configurable: true,
			enumerable: false,
			writable: true
		},
		_next: {
			value: function() {
				if (!this.__list__) return;
				if (this.__nextIndex__ < this.__length__) return this.__nextIndex__++;
				this._unBind();
			},
			configurable: true,
			enumerable: false,
			writable: true
		},
		_resolve: {
			value: function (i) {
				var char = this.__list__[i], code;
				if (this.__nextIndex__ === this.__length__) return char;
				code = char.charCodeAt(0);
				if ((code >= 0xD800) && (code <= 0xDBFF)) return char + this.__list__[this.__nextIndex__++];
				return char;
			},
			configurable: true,
			enumerable: false,
			writable: true
		},
		toString: {
			value: function() {
				return '[object String Iterator]';
			},
			configurable: true,
			enumerable: false,
			writable: true
		}
	});

	return StringIterator;
}());
if (!("Symbol"in self&&"iterator"in self.Symbol&&!!String.prototype[self.Symbol.iterator]
)) {

// String.prototype.@@iterator
/* global CreateMethodProperty, RequireObjectCoercible, ToString, StringIterator, Symbol */
// 21.1.3.29. String.prototype [ @@iterator ] ( )
CreateMethodProperty(String.prototype, Symbol.iterator, function () {
	// 1. Let O be ? RequireObjectCoercible(this value).
	var O = RequireObjectCoercible(this);
	// 2. Let S be ? ToString(O).
	var S = ToString(O);
	// 3. Return CreateStringIterator(S).
	// TODO: Add CreateStringIterator.
	return new StringIterator(S);
});

}

if (!("Promise"in self
)) {

// Promise
/*
	Yaku v0.19.3
	(c) 2015 Yad Smood. http://ysmood.org
	License MIT
*/
/*
	Yaku v0.17.9
	(c) 2015 Yad Smood. http://ysmood.org
	License MIT
*/
(function () {
	'use strict';

	var $undefined
	, $null = null
	, isBrowser = typeof self === 'object'
	, root = self
	, nativePromise = root.Promise
	, process = root.process
	, console = root.console
	, isLongStackTrace = true
	, Arr = Array
	, Err = Error

	, $rejected = 1
	, $resolved = 2
	, $pending = 3

	, $Symbol = 'Symbol'
	, $iterator = 'iterator'
	, $species = 'species'
	, $speciesKey = $Symbol + '(' + $species + ')'
	, $return = 'return'

	, $unhandled = '_uh'
	, $promiseTrace = '_pt'
	, $settlerTrace = '_st'

	, $invalidThis = 'Invalid this'
	, $invalidArgument = 'Invalid argument'
	, $fromPrevious = '\nFrom previous '
	, $promiseCircularChain = 'Chaining cycle detected for promise'
	, $unhandledRejectionMsg = 'Uncaught (in promise)'
	, $rejectionHandled = 'rejectionHandled'
	, $unhandledRejection = 'unhandledRejection'

	, $tryCatchFn
	, $tryCatchThis
	, $tryErr = { e: $null }
	, $noop = function () {}
	, $cleanStackReg = /^.+\/node_modules\/yaku\/.+\n?/mg
	;

	/**
	* This class follows the [Promises/A+](https://promisesaplus.com) and
	* [ES6](http://people.mozilla.org/~jorendorff/es6-draft.html#sec-promise-objects) spec
	* with some extra helpers.
	* @param  {Function} executor Function object with two arguments resolve, reject.
	* The first argument fulfills the promise, the second argument rejects it.
	* We can call these functions, once our operation is completed.
	*/
	var Yaku = function (executor) {
	var self = this,
		err;

	// "this._s" is the internao state of: pending, resolved or rejected
	// "this._v" is the internal value

	if (!isObject(self) || self._s !== $undefined)
		throw genTypeError($invalidThis);

	self._s = $pending;

	if (isLongStackTrace) self[$promiseTrace] = genTraceInfo();

	if (executor !== $noop) {
		if (!isFunction(executor))
			throw genTypeError($invalidArgument);

		err = genTryCatcher(executor)(
			genSettler(self, $resolved),
			genSettler(self, $rejected)
		);

		if (err === $tryErr)
			settlePromise(self, $rejected, err.e);
	}
	};

	Yaku['default'] = Yaku;

	extend(Yaku.prototype, {
	/**
		* Appends fulfillment and rejection handlers to the promise,
		* and returns a new promise resolving to the return value of the called handler.
		* @param  {Function} onFulfilled Optional. Called when the Promise is resolved.
		* @param  {Function} onRejected  Optional. Called when the Promise is rejected.
		* @return {Yaku} It will return a new Yaku which will resolve or reject after
		* @example
		* the current Promise.
		* ```js
		* var Promise = require('yaku');
		* var p = Promise.resolve(10);
		*
		* p.then((v) => {
		*     console.log(v);
		* });
		* ```
		*/
	then: function (onFulfilled, onRejected) {
		if (this._s === undefined) throw genTypeError();

		return addHandler(
			this,
			newCapablePromise(Yaku.speciesConstructor(this, Yaku)),
			onFulfilled,
			onRejected
		);
	},

	/**
		* The `catch()` method returns a Promise and deals with rejected cases only.
		* It behaves the same as calling `Promise.prototype.then(undefined, onRejected)`.
		* @param  {Function} onRejected A Function called when the Promise is rejected.
		* This function has one argument, the rejection reason.
		* @return {Yaku} A Promise that deals with rejected cases only.
		* @example
		* ```js
		* var Promise = require('yaku');
		* var p = Promise.reject(new Error("ERR"));
		*
		* p['catch']((v) => {
		*     console.log(v);
		* });
		* ```
		*/
	'catch': function (onRejected) {
		return this.then($undefined, onRejected);
	},

	/**
		* Register a callback to be invoked when a promise is settled (either fulfilled or rejected).
		* Similar with the try-catch-finally, it's often used for cleanup.
		* @param  {Function} onFinally A Function called when the Promise is settled.
		* It will not receive any argument.
		* @return {Yaku} A Promise that will reject if onFinally throws an error or returns a rejected promise.
		* Else it will resolve previous promise's final state (either fulfilled or rejected).
		* @example
		* ```js
		* var Promise = require('yaku');
		* var p = Math.random() > 0.5 ? Promise.resolve() : Promise.reject();
		* p.finally(() => {
		*     console.log('finally');
		* });
		* ```
		*/
	'finally': function (onFinally) {
		return this.then(function (val) {
			return Yaku.resolve(onFinally()).then(function () {
				return val;
			});
		}, function (err) {
			return Yaku.resolve(onFinally()).then(function () {
				throw err;
			});
		});
	},

	// The number of current promises that attach to this Yaku instance.
	_c: 0,

	// The parent Yaku.
	_p: $null
	});

	/**
	* The `Promise.resolve(value)` method returns a Promise object that is resolved with the given value.
	* If the value is a thenable (i.e. has a then method), the returned promise will "follow" that thenable,
	* adopting its eventual state; otherwise the returned promise will be fulfilled with the value.
	* @param  {Any} value Argument to be resolved by this Promise.
	* Can also be a Promise or a thenable to resolve.
	* @return {Yaku}
	* @example
	* ```js
	* var Promise = require('yaku');
	* var p = Promise.resolve(10);
	* ```
	*/
	Yaku.resolve = function (val) {
	return isYaku(val) ? val : settleWithX(newCapablePromise(this), val);
	};

	/**
	* The `Promise.reject(reason)` method returns a Promise object that is rejected with the given reason.
	* @param  {Any} reason Reason why this Promise rejected.
	* @return {Yaku}
	* @example
	* ```js
	* var Promise = require('yaku');
	* var p = Promise.reject(new Error("ERR"));
	* ```
	*/
	Yaku.reject = function (reason) {
	return settlePromise(newCapablePromise(this), $rejected, reason);
	};

	/**
	* The `Promise.race(iterable)` method returns a promise that resolves or rejects
	* as soon as one of the promises in the iterable resolves or rejects,
	* with the value or reason from that promise.
	* @param  {iterable} iterable An iterable object, such as an Array.
	* @return {Yaku} The race function returns a Promise that is settled
	* the same way as the first passed promise to settle.
	* It resolves or rejects, whichever happens first.
	* @example
	* ```js
	* var Promise = require('yaku');
	* Promise.race([
	*     123,
	*     Promise.resolve(0)
	* ])
	* .then((value) => {
	*     console.log(value); // => 123
	* });
	* ```
	*/
	Yaku.race = function (iterable) {
	var self = this
		, p = newCapablePromise(self)

		, resolve = function (val) {
			settlePromise(p, $resolved, val);
		}

		, reject = function (val) {
			settlePromise(p, $rejected, val);
		}

		, ret = genTryCatcher(each)(iterable, function (v) {
			self.resolve(v).then(resolve, reject);
		});

	if (ret === $tryErr) return self.reject(ret.e);

	return p;
	};

	/**
	* The `Promise.all(iterable)` method returns a promise that resolves when
	* all of the promises in the iterable argument have resolved.
	*
	* The result is passed as an array of values from all the promises.
	* If something passed in the iterable array is not a promise,
	* it's converted to one by Promise.resolve. If any of the passed in promises rejects,
	* the all Promise immediately rejects with the value of the promise that rejected,
	* discarding all the other promises whether or not they have resolved.
	* @param  {iterable} iterable An iterable object, such as an Array.
	* @return {Yaku}
	* @example
	* ```js
	* var Promise = require('yaku');
	* Promise.all([
	*     123,
	*     Promise.resolve(0)
	* ])
	* .then((values) => {
	*     console.log(values); // => [123, 0]
	* });
	* ```
	* @example
	* Use with iterable.
	* ```js
	* var Promise = require('yaku');
	* Promise.all((function * () {
	*     yield 10;
	*     yield new Promise(function (r) { setTimeout(r, 1000, "OK") });
	* })())
	* .then((values) => {
	*     console.log(values); // => [123, 0]
	* });
	* ```
	*/
	Yaku.all = function (iterable) {
	var self = this
		, p1 = newCapablePromise(self)
		, res = []
		, ret
	;

	function reject (reason) {
		settlePromise(p1, $rejected, reason);
	}

	ret = genTryCatcher(each)(iterable, function (item, i) {
		self.resolve(item).then(function (value) {
			res[i] = value;
			if (!--ret) settlePromise(p1, $resolved, res);
		}, reject);
	});

	if (ret === $tryErr) return self.reject(ret.e);

	if (!ret) settlePromise(p1, $resolved, []);

	return p1;
	};

	/**
	* The ES6 Symbol object that Yaku should use, by default it will use the
	* global one.
	* @type {Object}
	* @example
	* ```js
	* var core = require("core-js/library");
	* var Promise = require("yaku");
	* Promise.Symbol = core.Symbol;
	* ```
	*/
	Yaku.Symbol = root[$Symbol] || {};

	// To support browsers that don't support `Object.defineProperty`.
	genTryCatcher(function () {
	Object.defineProperty(Yaku, getSpecies(), {
		get: function () { return this; }
	});
	})();

	/**
	* Use this api to custom the species behavior.
	* https://tc39.github.io/ecma262/#sec-speciesconstructor
	* @param {Any} O The current this object.
	* @param {Function} defaultConstructor
	*/
	Yaku.speciesConstructor = function (O, D) {
	var C = O.constructor;

	return C ? (C[getSpecies()] || D) : D;
	};

	/**
	* Catch all possibly unhandled rejections. If you want to use specific
	* format to display the error stack, overwrite it.
	* If it is set, auto `console.error` unhandled rejection will be disabled.
	* @param {Any} reason The rejection reason.
	* @param {Yaku} p The promise that was rejected.
	* @example
	* ```js
	* var Promise = require('yaku');
	* Promise.unhandledRejection = (reason) => {
	*     console.error(reason);
	* };
	*
	* // The console will log an unhandled rejection error message.
	* Promise.reject('my reason');
	*
	* // The below won't log the unhandled rejection error message.
	* Promise.reject('v')["catch"](() => {});
	* ```
	*/
	Yaku.unhandledRejection = function (reason, p) {
	console && console.error(
		$unhandledRejectionMsg,
		isLongStackTrace ? p.longStack : genStackInfo(reason, p)
	);
	};

	/**
	* Emitted whenever a Promise was rejected and an error handler was
	* attached to it (for example with `["catch"]()`) later than after an event loop turn.
	* @param {Any} reason The rejection reason.
	* @param {Yaku} p The promise that was rejected.
	*/
	Yaku.rejectionHandled = $noop;

	/**
	* It is used to enable the long stack trace.
	* Once it is enabled, it can't be reverted.
	* While it is very helpful in development and testing environments,
	* it is not recommended to use it in production. It will slow down
	* application and eat up memory.
	* It will add an extra property `longStack` to the Error object.
	* @example
	* ```js
	* var Promise = require('yaku');
	* Promise.enableLongStackTrace();
	* Promise.reject(new Error("err"))["catch"]((err) => {
	*     console.log(err.longStack);
	* });
	* ```
	*/
	Yaku.enableLongStackTrace = function () {
	isLongStackTrace = true;
	};

	/**
	* Only Node has `process.nextTick` function. For browser there are
	* so many ways to polyfill it. Yaku won't do it for you, instead you
	* can choose what you prefer. For example, this project
	* [next-tick](https://github.com/medikoo/next-tick).
	* By default, Yaku will use `process.nextTick` on Node, `setTimeout` on browser.
	* @type {Function}
	* @example
	* ```js
	* var Promise = require('yaku');
	* Promise.nextTick = require('next-tick');
	* ```
	* @example
	* You can even use sync resolution if you really know what you are doing.
	* ```js
	* var Promise = require('yaku');
	* Promise.nextTick = fn => fn();
	* ```
	*/
	Yaku.nextTick = isBrowser ?
	function (fn) {
		nativePromise ?
			new nativePromise(function (resolve) { resolve(); }).then(fn) :
			setTimeout(fn);
	} :
	process.nextTick;

	// ********************** Private **********************

	Yaku._s = 1;

	/**
	* All static variable name will begin with `$`. Such as `$rejected`.
	* @private
	*/

	// ******************************* Utils ********************************

	function getSpecies () {
	return Yaku[$Symbol][$species] || $speciesKey;
	}

	function extend (src, target) {
	for (var k in target) {
		src[k] = target[k];
	}
	}

	function isObject (obj) {
	return obj && typeof obj === 'object';
	}

	function isFunction (obj) {
	return typeof obj === 'function';
	}

	function isInstanceOf (a, b) {
	return a instanceof b;
	}

	function isError (obj) {
	return isInstanceOf(obj, Err);
	}

	function ensureType (obj, fn, msg) {
	if (!fn(obj)) throw genTypeError(msg);
	}

	/**
	* Wrap a function into a try-catch.
	* @private
	* @return {Any | $tryErr}
	*/
	function tryCatcher () {
	try {
		return $tryCatchFn.apply($tryCatchThis, arguments);
	} catch (e) {
		$tryErr.e = e;
		return $tryErr;
	}
	}

	/**
	* Generate a try-catch wrapped function.
	* @private
	* @param  {Function} fn
	* @return {Function}
	*/
	function genTryCatcher (fn, self) {
	$tryCatchFn = fn;
	$tryCatchThis = self;
	return tryCatcher;
	}

	/**
	* Generate a scheduler.
	* @private
	* @param  {Integer}  initQueueSize
	* @param  {Function} fn `(Yaku, Value) ->` The schedule handler.
	* @return {Function} `(Yaku, Value) ->` The scheduler.
	*/
	function genScheduler (initQueueSize, fn) {
	/**
		* All async promise will be scheduled in
		* here, so that they can be execute on the next tick.
		* @private
		*/
	var fnQueue = Arr(initQueueSize)
		, fnQueueLen = 0;

	/**
		* Run all queued functions.
		* @private
		*/
	function flush () {
		var i = 0;
		while (i < fnQueueLen) {
			fn(fnQueue[i], fnQueue[i + 1]);
			fnQueue[i++] = $undefined;
			fnQueue[i++] = $undefined;
		}

		fnQueueLen = 0;
		if (fnQueue.length > initQueueSize) fnQueue.length = initQueueSize;
	}

	return function (v, arg) {
		fnQueue[fnQueueLen++] = v;
		fnQueue[fnQueueLen++] = arg;

		if (fnQueueLen === 2) Yaku.nextTick(flush);
	};
	}

	/**
	* Generate a iterator
	* @param  {Any} obj
	* @private
	* @return {Object || TypeError}
	*/
	function each (iterable, fn) {
	var len
		, i = 0
		, iter
		, item
		, ret
	;

	if (!iterable) throw genTypeError($invalidArgument);

	var gen = iterable[Yaku[$Symbol][$iterator]];
	if (isFunction(gen))
		iter = gen.call(iterable);
	else if (isFunction(iterable.next)) {
		iter = iterable;
	}
	else if (isInstanceOf(iterable, Arr)) {
		len = iterable.length;
		while (i < len) {
			fn(iterable[i], i++);
		}
		return i;
	} else
		throw genTypeError($invalidArgument);

	while (!(item = iter.next()).done) {
		ret = genTryCatcher(fn)(item.value, i++);
		if (ret === $tryErr) {
			isFunction(iter[$return]) && iter[$return]();
			throw ret.e;
		}
	}

	return i;
	}

	/**
	* Generate type error object.
	* @private
	* @param  {String} msg
	* @return {TypeError}
	*/
	function genTypeError (msg) {
	return new TypeError(msg);
	}

	function genTraceInfo (noTitle) {
	return (noTitle ? '' : $fromPrevious) + new Err().stack;
	}


	// *************************** Promise Helpers ****************************

	/**
	* Resolve the value returned by onFulfilled or onRejected.
	* @private
	* @param {Yaku} p1
	* @param {Yaku} p2
	*/
	var scheduleHandler = genScheduler(999, function (p1, p2) {
	var x, handler;

	// 2.2.2
	// 2.2.3
	handler = p1._s !== $rejected ? p2._onFulfilled : p2._onRejected;

	// 2.2.7.3
	// 2.2.7.4
	if (handler === $undefined) {
		settlePromise(p2, p1._s, p1._v);
		return;
	}

	// 2.2.7.1
	x = genTryCatcher(callHanler)(handler, p1._v);
	if (x === $tryErr) {
		// 2.2.7.2
		settlePromise(p2, $rejected, x.e);
		return;
	}

	settleWithX(p2, x);
	});

	var scheduleUnhandledRejection = genScheduler(9, function (p) {
	if (!hashOnRejected(p)) {
		p[$unhandled] = 1;
		emitEvent($unhandledRejection, p);
	}
	});

	function emitEvent (name, p) {
	var browserEventName = 'on' + name.toLowerCase()
		, browserHandler = root[browserEventName];

	if (process && process.listeners(name).length)
		name === $unhandledRejection ?
			process.emit(name, p._v, p) : process.emit(name, p);
	else if (browserHandler)
		browserHandler({ reason: p._v, promise: p });
	else
		Yaku[name](p._v, p);
	}

	function isYaku (val) { return val && val._s; }

	function newCapablePromise (Constructor) {
	if (isYaku(Constructor)) return new Constructor($noop);

	var p, r, j;
	p = new Constructor(function (resolve, reject) {
		if (p) throw genTypeError();

		r = resolve;
		j = reject;
	});

	ensureType(r, isFunction);
	ensureType(j, isFunction);

	return p;
	}

	/**
	* It will produce a settlePromise function to user.
	* Such as the resolve and reject in this `new Yaku (resolve, reject) ->`.
	* @private
	* @param  {Yaku} self
	* @param  {Integer} state The value is one of `$pending`, `$resolved` or `$rejected`.
	* @return {Function} `(value) -> undefined` A resolve or reject function.
	*/
	function genSettler (self, state) {
	var isCalled = false;
	return function (value) {
		if (isCalled) return;
		isCalled = true;

		if (isLongStackTrace)
			self[$settlerTrace] = genTraceInfo(true);

		if (state === $resolved)
			settleWithX(self, value);
		else
			settlePromise(self, state, value);
	};
	}

	/**
	* Link the promise1 to the promise2.
	* @private
	* @param {Yaku} p1
	* @param {Yaku} p2
	* @param {Function} onFulfilled
	* @param {Function} onRejected
	*/
	function addHandler (p1, p2, onFulfilled, onRejected) {
	// 2.2.1
	if (isFunction(onFulfilled))
		p2._onFulfilled = onFulfilled;
	if (isFunction(onRejected)) {
		if (p1[$unhandled]) emitEvent($rejectionHandled, p1);

		p2._onRejected = onRejected;
	}

	if (isLongStackTrace) p2._p = p1;
	p1[p1._c++] = p2;

	// 2.2.6
	if (p1._s !== $pending)
		scheduleHandler(p1, p2);

	// 2.2.7
	return p2;
	}

	// iterate tree
	function hashOnRejected (node) {
	// A node shouldn't be checked twice.
	if (node._umark)
		return true;
	else
		node._umark = true;

	var i = 0
		, len = node._c
		, child;

	while (i < len) {
		child = node[i++];
		if (child._onRejected || hashOnRejected(child)) return true;
	}
	}

	function genStackInfo (reason, p) {
	var stackInfo = [];

	function push (trace) {
		return stackInfo.push(trace.replace(/^\s+|\s+$/g, ''));
	}

	if (isLongStackTrace) {
		if (p[$settlerTrace])
			push(p[$settlerTrace]);

		// Hope you guys could understand how the back trace works.
		// We only have to iterate through the tree from the bottom to root.
		(function iter (node) {
			if (node && $promiseTrace in node) {
				iter(node._next);
				push(node[$promiseTrace] + '');
				iter(node._p);
			}
		})(p);
	}

	return (reason && reason.stack ? reason.stack : reason) +
		('\n' + stackInfo.join('\n')).replace($cleanStackReg, '');
	}

	function callHanler (handler, value) {
	// 2.2.5
	return handler(value);
	}

	/**
	* Resolve or reject a promise.
	* @private
	* @param  {Yaku} p
	* @param  {Integer} state
	* @param  {Any} value
	*/
	function settlePromise (p, state, value) {
	var i = 0
		, len = p._c;

	// 2.1.2
	// 2.1.3
	if (p._s === $pending) {
		// 2.1.1.1
		p._s = state;
		p._v = value;

		if (state === $rejected) {
			if (isLongStackTrace && isError(value)) {
				value.longStack = genStackInfo(value, p);
			}

			scheduleUnhandledRejection(p);
		}

		// 2.2.4
		while (i < len) {
			scheduleHandler(p, p[i++]);
		}
	}

	return p;
	}

	/**
	* Resolve or reject promise with value x. The x can also be a thenable.
	* @private
	* @param {Yaku} p
	* @param {Any | Thenable} x A normal value or a thenable.
	*/
	function settleWithX (p, x) {
	// 2.3.1
	if (x === p && x) {
		settlePromise(p, $rejected, genTypeError($promiseCircularChain));
		return p;
	}

	// 2.3.2
	// 2.3.3
	if (x !== $null && (isFunction(x) || isObject(x))) {
		// 2.3.2.1
		var xthen = genTryCatcher(getThen)(x);

		if (xthen === $tryErr) {
			// 2.3.3.2
			settlePromise(p, $rejected, xthen.e);
			return p;
		}

		if (isFunction(xthen)) {
			if (isLongStackTrace && isYaku(x))
				p._next = x;

			// Fix https://bugs.chromium.org/p/v8/issues/detail?id=4162
			if (isYaku(x))
				settleXthen(p, x, xthen);
			else
				Yaku.nextTick(function () {
					settleXthen(p, x, xthen);
				});
		} else
			// 2.3.3.4
			settlePromise(p, $resolved, x);
	} else
		// 2.3.4
		settlePromise(p, $resolved, x);

	return p;
	}

	/**
	* Try to get a promise's then method.
	* @private
	* @param  {Thenable} x
	* @return {Function}
	*/
	function getThen (x) { return x.then; }

	/**
	* Resolve then with its promise.
	* @private
	* @param  {Yaku} p
	* @param  {Thenable} x
	* @param  {Function} xthen
	*/
	function settleXthen (p, x, xthen) {
	// 2.3.3.3
	var err = genTryCatcher(xthen, x)(function (y) {
		// 2.3.3.3.3
		// 2.3.3.3.1
		x && (x = $null, settleWithX(p, y));
	}, function (r) {
		// 2.3.3.3.3
		// 2.3.3.3.2
		x && (x = $null, settlePromise(p, $rejected, r));
	});

	// 2.3.3.3.4.1
	if (err === $tryErr && x) {
		// 2.3.3.3.4.2
		settlePromise(p, $rejected, err.e);
		x = $null;
	}
	}

	root.Promise = Yaku;
})();

}

if (!("Symbol"in self&&"unscopables"in self.Symbol
)) {

// Symbol.unscopables
/* global Symbol */
Object.defineProperty(Symbol, 'unscopables', { value: Symbol('unscopables') });

}

if (!((function(){try{if("WeakMap"in self&&0===self.WeakMap.length){var e={},t=new self.WeakMap([[e,"test"]])
return"test"===t.get(e)&&!1===t["delete"](0)}return!1}catch(a){return!1}})()
)) {

// WeakMap
/* globals Symbol, OrdinaryCreateFromConstructor, IsCallable, GetIterator, IteratorStep, IteratorValue, IteratorClose, Get, Call, CreateMethodProperty, Type, SameValue */
(function (global) {
	// Deleted map items mess with iterator pointers, so rather than removing them mark them as deleted. Can't use undefined or null since those both valid keys so use a private symbol.
	var undefMarker = Symbol('undef');
	// 23.3.1.1 WeakMap ( [ iterable ] )
	var WeakMap = function WeakMap(/* iterable */) {
		// 1. If NewTarget is undefined, throw a TypeError exception.
		if (!(this instanceof WeakMap)) {
			throw new TypeError('Constructor WeakMap requires "new"');
		}
		// 2. Let map be ? OrdinaryCreateFromConstructor(NewTarget, "%WeakMapPrototype%", « [[WeakMapData]] »).
		var map = OrdinaryCreateFromConstructor(this, WeakMap.prototype, {
			_keys: [],
			_values: [],
			_es6WeakMap: true
		});

		// 3. Set map.[[WeakMapData]] to a new empty List.
		// Polyfill.io - This step was done as part of step two.

		// 4. If iterable is not present, let iterable be undefined.
		var iterable = arguments.length > 0 ? arguments[0] : undefined;

		// 5. If iterable is either undefined or null, return map.
		if (iterable === null || iterable === undefined) {
			return map;
		}

		// 6. Let adder be ? Get(map, "set").
		var adder = Get(map, "set");

		// 7. If IsCallable(adder) is false, throw a TypeError exception.
		if (!IsCallable(adder)) {
			throw new TypeError("WeakMap.prototype.set is not a function");
		}

		// 8. Let iteratorRecord be ? GetIterator(iterable).
		try {
			var iteratorRecord = GetIterator(iterable);
			// 9. Repeat,
			// eslint-disable-next-line no-constant-condition
			while (true) {
				// a. Let next be ? IteratorStep(iteratorRecord).
				var next = IteratorStep(iteratorRecord);
				// b. If next is false, return map.
				if (next === false) {
					return map;
				}
				// c. Let nextItem be ? IteratorValue(next).
				var nextItem = IteratorValue(next);
				// d. If Type(nextItem) is not Object, then
				if (Type(nextItem) !== 'object') {
					// i. Let error be Completion{[[Type]]: throw, [[Value]]: a newly created TypeError object, [[Target]]: empty}.
					try {
						throw new TypeError('Iterator value ' + nextItem + ' is not an entry object');
					} catch (error) {
						// ii. Return ? IteratorClose(iteratorRecord, error).
						return IteratorClose(iteratorRecord, error);
					}
				}
				try {
					// Polyfill.io - The try catch accounts for steps: f, h, and j.

					// e. Let k be Get(nextItem, "0").
					var k = Get(nextItem, "0");
					// f. If k is an abrupt completion, return ? IteratorClose(iteratorRecord, k).
					// g. Let v be Get(nextItem, "1").
					var v = Get(nextItem, "1");
					// h. If v is an abrupt completion, return ? IteratorClose(iteratorRecord, v).
					// i. Let status be Call(adder, map, « k.[[Value]], v.[[Value]] »).
					Call(adder, map, [k, v]);
				} catch (e) {
					// j. If status is an abrupt completion, return ? IteratorClose(iteratorRecord, status).
					return IteratorClose(iteratorRecord, e);
				}
			}
		} catch (e) {
			// Polyfill.io - For user agents which do not have iteration methods on argument objects or arrays, we can special case those.
			if (Array.isArray(iterable) ||
				Object.prototype.toString.call(iterable) === '[object Arguments]' ||
				// IE 7 & IE 8 return '[object Object]' for the arguments object, we can detect by checking for the existence of the callee property
				(!!iterable.callee)) {
				var index;
				var length = iterable.length;
				for (index = 0; index < length; index++) {
					k = iterable[index][0];
					v = iterable[index][1];
					Call(adder, map, [k, v]);
				}
			}
		}
		return map;
	};

	// 23.3.2.1 WeakMap.prototype
	// The initial value of WeakMap.prototype is the intrinsic object %WeakMapPrototype%.
	// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: false }.
	Object.defineProperty(WeakMap, 'prototype', {
		configurable: false,
		enumerable: false,
		writable: false,
		value: {}
	});

	// 23.3.3.1 WeakMap.prototype.constructor
	CreateMethodProperty(WeakMap.prototype, 'constructor', WeakMap);

	// 23.3.3.2 WeakMap.prototype.delete ( key )
	CreateMethodProperty(WeakMap.prototype, 'delete', function (key) {
		// 1. Let M be the this value.
		var M = this;
		// 2. If Type(M) is not Object, throw a TypeError exception.
		if (Type(M) !== 'object') {
			throw new TypeError('Method WeakMap.prototype.clear called on incompatible receiver ' + Object.prototype.toString.call(M));
		}
		// 3. If M does not have a [[WeakMapData]] internal slot, throw a TypeError exception.
		if (M._es6WeakMap !== true) {
			throw new TypeError('Method WeakMap.prototype.clear called on incompatible receiver ' + Object.prototype.toString.call(M));
		}
		// 4. Let entries be the List that is M.[[WeakMapData]].
		var entries = M._keys;
		// 5. If Type(key) is not Object, return false.
		if (Type(key) !== 'object') {
			return false;
		}
		// 6. For each Record {[[Key]], [[Value]]} p that is an element of entries, do
		for (var i = 0; i < entries.length; i++) {
			// a. If p.[[Key]] is not empty and SameValue(p.[[Key]], key) is true, then
			if (M._keys[i] !== undefMarker && SameValue(M._keys[i], key)) {
				// i. Set p.[[Key]] to empty.
				this._keys[i] = undefMarker;
				// ii. Set p.[[Value]] to empty.
				this._values[i] = undefMarker;
				this._size = --this._size;
				// iii. Return true.
				return true;
			}
		}
		// 7. Return false.
		return false;
	});

	// 23.3.3.3 WeakMap.prototype.get ( key )
	CreateMethodProperty(WeakMap.prototype, 'get', function get(key) {
		// 1. Let M be the this value.
		var M = this;
		// 2. If Type(M) is not Object, throw a TypeError exception.
		if (Type(M) !== 'object') {
			throw new TypeError('Method WeakMap.prototype.get called on incompatible receiver ' + Object.prototype.toString.call(M));
		}
		// 3. If M does not have a [[WeakMapData]] internal slot, throw a TypeError exception.
		if (M._es6WeakMap !== true) {
			throw new TypeError('Method WeakMap.prototype.get called on incompatible receiver ' + Object.prototype.toString.call(M));
		}
		// 4. Let entries be the List that is M.[[WeakMapData]].
		var entries = M._keys;
		// 5. If Type(key) is not Object, return undefined.
		if (Type(key) !== 'object') {
			return undefined;
		}
		// 6. For each Record {[[Key]], [[Value]]} p that is an element of entries, do
		for (var i = 0; i < entries.length; i++) {
			// a. If p.[[Key]] is not empty and SameValue(p.[[Key]], key) is true, return p.[[Value]].
			if (M._keys[i] !== undefMarker && SameValue(M._keys[i], key)) {
				return M._values[i];
			}
		}
		// 7. Return undefined.
		return undefined;
	});

	// 23.3.3.4 WeakMap.prototype.has ( key )
	CreateMethodProperty(WeakMap.prototype, 'has', function has(key) {
		// 1. Let M be the this value.
		var M = this;
		// 2. If Type(M) is not Object, throw a TypeError exception.
		if (typeof M !== 'object') {
			throw new TypeError('Method WeakMap.prototype.has called on incompatible receiver ' + Object.prototype.toString.call(M));
		}
		// 3. If M does not have a [[WeakMapData]] internal slot, throw a TypeError exception.
		if (M._es6WeakMap !== true) {
			throw new TypeError('Method WeakMap.prototype.has called on incompatible receiver ' + Object.prototype.toString.call(M));
		}
		// 4. Let entries be the List that is M.[[WeakMapData]].
		var entries = M._keys;
		// 5. If Type(key) is not Object, return false.
		if (Type(key) !== 'object') {
			return false;
		}
		// 6. For each Record {[[Key]], [[Value]]} p that is an element of entries, do
		for (var i = 0; i < entries.length; i++) {
			// a. If p.[[Key]] is not empty and SameValue(p.[[Key]], key) is true, return true.
			if (M._keys[i] !== undefMarker && SameValue(M._keys[i], key)) {
				return true;
			}
		}
		// 7. Return false.
		return false;
	});

	// 23.3.3.5 WeakMap.prototype.set ( key, value )
	CreateMethodProperty(WeakMap.prototype, 'set', function set(key, value) {
		// 1. Let M be the this value.
		var M = this;
		// 2. If Type(M) is not Object, throw a TypeError exception.
		if (Type(M) !== 'object') {
			throw new TypeError('Method WeakMap.prototype.set called on incompatible receiver ' + Object.prototype.toString.call(M));
		}
		// 3. If M does not have a [[WeakMapData]] internal slot, throw a TypeError exception.
		if (M._es6WeakMap !== true) {
			throw new TypeError('Method WeakMap.prototype.set called on incompatible receiver ' + Object.prototype.toString.call(M));
		}
		// 4. Let entries be the List that is M.[[WeakMapData]].
		var entries = M._keys;
		// 5. If Type(key) is not Object, throw a TypeError exception.
		if (Type(key) !== 'object') {
			throw new TypeError("Invalid value used as weak map key");
		}
		// 6. For each Record {[[Key]], [[Value]]} p that is an element of entries, do
		for (var i = 0; i < entries.length; i++) {
			// a. If p.[[Key]] is not empty and SameValue(p.[[Key]], key) is true, then
			if (M._keys[i] !== undefMarker && SameValue(M._keys[i], key)) {
				// i. Set p.[[Value]] to value.
				M._values[i] = value;
				// ii. Return M.
				return M;
			}
		}
		// 7. Let p be the Record {[[Key]]: key, [[Value]]: value}.
		var p = {
			'[[Key]]': key,
			'[[Value]]': value
		};
		// 8. Append p as the last element of entries.
		M._keys.push(p['[[Key]]']);
		M._values.push(p['[[Value]]']);
		// 9. Return M.
		return M;
	});

	// 23.3.3.6 WeakMap.prototype [ @@toStringTag ]
	// The initial value of the @@toStringTag property is the String value "WeakMap".
	// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: true }.
	Object.defineProperty(WeakMap.prototype, Symbol.toStringTag, {
		configurable: true,
		enumerable: false,
		writable: false,
		value: 'WeakMap'
	});

	// Polyfill.io - Safari 8 implements WeakMap.name but as a non-writable property, which means it would throw an error if we try and write to it here.
	if (!('name' in WeakMap)) {
		// 19.2.4.2 name
		Object.defineProperty(WeakMap, 'name', {
			configurable: true,
			enumerable: false,
			writable: false,
			value: 'WeakMap'
		});
	}

	// Export the object
	try {
		CreateMethodProperty(global, 'WeakMap', WeakMap);
	} catch (e) {
		// IE8 throws an error here if we set enumerable to false.
		// More info on table 2: https://msdn.microsoft.com/en-us/library/dd229916(v=vs.85).aspx
		global.WeakMap = WeakMap;
	}
}(self));

}

if (!((function(e){try{if(Object.prototype.hasOwnProperty.call(e,"WeakSet")&&0===e.WeakSet.length){var t={},r=new e.WeakSet([t])
return r.has(t)&&!1===r["delete"](0)}return!1}catch(a){return!1}})(self)
)) {

// WeakSet
/* global Call, CreateMethodProperty, Get, GetIterator, IsArray, IsCallable, IteratorClose, IteratorStep, IteratorValue, OrdinaryCreateFromConstructor, SameValueZero, Type, Symbol */
(function (global) {
	// Deleted set items mess with iterator pointers, so rather than removing them mark them as deleted. Can't use undefined or null since those both valid keys so use a private symbol.
	var undefMarker = Symbol('undef');
	// 23.4.1.1. WeakSet ( [ iterable ] )
	var WeakSet = function WeakSet() {
		// 1. If NewTarget is undefined, throw a TypeError exception.
		if (!(this instanceof WeakSet)) {
			throw new TypeError('Constructor WeakSet requires "new"');
		}
		// 2. Let set be ? OrdinaryCreateFromConstructor(NewTarget, "%WeakSetPrototype%", « [[WeakSetData]] »).
		var set = OrdinaryCreateFromConstructor(this, WeakSet.prototype, {
			_values: [],
			_size: 0,
			_es6WeakSet: true
		});

		// 3. Set set.[[WeakSetData]] to a new empty List.
		// Polyfill.io - This step was done as part of step two.

		// 4. If iterable is not present, let iterable be undefined.
		var iterable = arguments.length > 0 ? arguments[0] : undefined;
		// 5. If iterable is either undefined or null, return set.
		if (iterable === null || iterable === undefined) {
			return set;
		}
		// 6. Let adder be ? Get(set, "add").
		var adder = Get(set, 'add');
		// 7. If IsCallable(adder) is false, throw a TypeError exception.
		if (!IsCallable(adder)) {
			throw new TypeError("WeakSet.prototype.add is not a function");
		}
		try {
			// 8. Let iteratorRecord be ? GetIterator(iterable).
			var iteratorRecord = GetIterator(iterable);
			// 9. Repeat,
			// eslint-disable-next-line no-constant-condition
			while (true) {
				// a. Let next be ? IteratorStep(iteratorRecord).
				var next = IteratorStep(iteratorRecord);
				// b. If next is false, return set.
				if (next === false) {
					return set;
				}
				// c. Let nextValue be ? IteratorValue(next).
				var nextValue = IteratorValue(next);
				// d. Let status be Call(adder, set, « nextValue »).
				try {
					Call(adder, set, [nextValue]);
				} catch (e) {
					// e. If status is an abrupt completion, return ? IteratorClose(iteratorRecord, status).
					return IteratorClose(iteratorRecord, e);
				}
			}
		} catch (e) {
			// Polyfill.io - For user agents which do not have iteration methods on argument objects or arrays, we can special case those.
			if (IsArray(iterable) ||
				Object.prototype.toString.call(iterable) === '[object Arguments]' ||
				// IE 7 & IE 8 return '[object Object]' for the arguments object, we can detect by checking for the existence of the callee property
				(!!iterable.callee)) {
				var index;
				var length = iterable.length;
				for (index = 0; index < length; index++) {
					Call(adder, set, [iterable[index]]);
				}
			}
		}
		return set;
	};

	// 23.4.2.1. WeakSet.prototype
	// The initial value of WeakSet.prototype is the intrinsic %WeakSetPrototype% object.
	// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: false }.
	Object.defineProperty(WeakSet, 'prototype', {
		configurable: false,
		enumerable: false,
		writable: false,
		value: {}
	});

	// 23.4.3.1. WeakSet.prototype.add ( value )
	CreateMethodProperty(WeakSet.prototype, 'add', function add(value) {
		// 1. Let S be the this value.
		var S = this;
		// 2. If Type(S) is not Object, throw a TypeError exception.
		if (Type(S) !== 'object') {
			throw new TypeError('Method WeakSet.prototype.add called on incompatible receiver ' + Object.prototype.toString.call(S));
		}
		// 3. If S does not have a [[WeakSetData]] internal slot, throw a TypeError exception.
		if (S._es6WeakSet !== true) {
			throw new TypeError('Method WeakSet.prototype.add called on incompatible receiver ' + Object.prototype.toString.call(S));
		}
		// 4. If Type(value) is not Object, throw a TypeError exception.
		if (Type(value) !== 'object') {
			throw new TypeError('Invalid value used in weak set');
		}
		// 5. Let entries be the List that is S.[[WeakSetData]].
		var entries = S._values;
		// 6. For each e that is an element of entries, do
		for (var i = 0; i < entries.length; i++) {
			var e = entries[i];
			// a. If e is not empty and SameValue(e, value) is true, then
			if (e !== undefMarker && SameValueZero(e, value)) {
				// i. Return S.
				return S;
			}
		}
		// 7. Append value as the last element of entries.
		S._values.push(value);
		// 8. Return S.
		return S;
	});

	// 23.4.3.2. WeakSet.prototype.constructor
	CreateMethodProperty(WeakSet.prototype, 'constructor', WeakSet);

	// 23.4.3.3. WeakSet.prototype.delete ( value )
	CreateMethodProperty(WeakSet.prototype, 'delete', function (value) {
		// 1. Let S be the this value.
		var S = this;
		// 2. If Type(S) is not Object, throw a TypeError exception.
		if (Type(S) !== 'object') {
			throw new TypeError('Method WeakSet.prototype.delete called on incompatible receiver ' + Object.prototype.toString.call(S));
		}
		// 3. If S does not have a [[WeakSetData]] internal slot, throw a TypeError exception.
		if (S._es6WeakSet !== true) {
			throw new TypeError('Method WeakSet.prototype.delete called on incompatible receiver ' + Object.prototype.toString.call(S));
		}
		// 4. If Type(value) is not Object, return false.
		if (Type(value) !== 'object') {
			return false;
		}
		// 5. Let entries be the List that is S.[[WeakSetData]].
		var entries = S._values;
		// 6. For each e that is an element of entries, do
		for (var i = 0; i < entries.length; i++) {
			var e = entries[i];
			// a. If e is not empty and SameValue(e, value) is true, then
			if (e !== undefMarker && SameValueZero(e, value)) {
				// i. Replace the element of entries whose value is e with an element whose value is empty.
				entries[i] = undefMarker;
				// ii. Return true.
				return true;
			}
		}
		// 7. Return false.
		return false;
	});

	// 23.4.3.4. WeakSet.prototype.has ( value )
	CreateMethodProperty(WeakSet.prototype, 'has', function has(value) {
		// 1. Let S be the this value.
		var S = this;
		// 2. If Type(S) is not Object, throw a TypeError exception.
		if (Type(S) !== 'object') {
			throw new TypeError('Method WeakSet.prototype.has called on incompatible receiver ' + Object.prototype.toString.call(S));
		}
		// 3. If S does not have a [[WeakSetData]] internal slot, throw a TypeError exception.
		if (S._es6WeakSet !== true) {
			throw new TypeError('Method WeakSet.prototype.has called on incompatible receiver ' + Object.prototype.toString.call(S));
		}
		// 4. Let entries be the List that is S.[[WeakSetData]].
		var entries = S._values;
		// 5. If Type(value) is not Object, return false.
		if (Type(value) !== 'object') {
			return false;
		}
		// 6. For each e that is an element of entries, do
		for (var i = 0; i < entries.length; i++) {
			var e = entries[i];
			// a. If e is not empty and SameValue(e, value) is true, return true.
			if (e !== undefMarker && SameValueZero(e, value)) {
				return true;
			}
		}
		// 7. Return false.
		return false;
	});

	// 23.4.3.5. WeakSet.prototype [ @@toStringTag ]
	// The initial value of the @@toStringTag property is the String value "WeakSet".
	// This property has the attributes { [[Writable]]: false, [[Enumerable]]: false, [[Configurable]]: true }.

	// Polyfill.io - Safari 8 implements Set.name but as a non-configurable property, which means it would throw an error if we try and configure it here.
	if (!('name' in WeakSet)) {
		// 19.2.4.2 name
		Object.defineProperty(WeakSet, 'name', {
			configurable: true,
			enumerable: false,
			writable: false,
			value: 'WeakSet'
		});
	}

	// Export the object
	try {
		CreateMethodProperty(global, 'WeakSet', WeakSet);
	} catch (e) {
		// IE8 throws an error here if we set enumerable to false.
		// More info on table 2: https://msdn.microsoft.com/en-us/library/dd229916(v=vs.85).aspx
		global.WeakSet = WeakSet;
	}

}(self));

}

})
('object' === typeof window && window || 'object' === typeof self && self || 'object' === typeof global && global || {});
