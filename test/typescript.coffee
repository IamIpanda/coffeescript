## Basic type annotation and assignment

test "Unary ~ is not type annotation", ->
  eqJS "x ~number", "x(~number);"

for type in [
  'false', 'true', '7', '"hello"', "''", 'null', 'undefined',
  'void', 'any', 'unknown', 'number', 'string', 'T',
  'number[]', 'number | string', 'number & string',
  'keyof T', 'keyof {a: T, b: T}', 'readonly string[]', 'unique symbol',
  'typeof x', 'typeof Infinity', 'typeof NaN',
  'T["key"]', 'T["k"]["l"]', 'aNamespace.T', 'x.y.z',
  'T<number>', 'Partial<T>', 'Record<string, number>',
]
  do (type) ->
    test "#{type} type annotation", ->
      eqJS "x ~ #{type}", "var x: #{type};"
    test "#{type} type annotation with assignment", ->
      eqJS "x ~ #{type} = 7", """
        var x: #{type};

        x = 7;
      """

test 'raw TypeScript passthrough', ->
  eqJS 'x ~ `T[] extends A<B>`',
    'var x: T[] extends A<B>;'

test '::', ->
  eqJS 'x ~ typeof Object::toString',
    'var x: typeof Object.prototype.toString;'

test 'Type specification after assignment', ->
  eqJS '''
    x = 5
    x ~ number
  ''', '''
    var x: number;

    var x = 5;
  '''

## Function types

test 'argumentless function type annotation', ->
  eqJS 'zero ~ -> number',
    'var zero: () => number;'
test 'argumentless function type annotation with assignment', ->
  eqJS 'zero ~ -> number = -> 0', '''
    var zero: () => number;

    zero = function() {
      return 0;
    };
  '''
test 'argumentless function annotation', ->
  eqJS 'zero = () ~ number -> 0', '''
    var zero = function(): number {
      return 0;
    };
  '''
test '1-argument function type annotation', ->
  eqJS 'add1 ~ (i ~ number) -> number',
    'var add1: (i: number) => number;'
test '1-argument function annotation', ->
  eqJS 'add1 = (i ~ number) ~ number -> i+1', '''
    var add1 = function(i: number): number {
      return i + 1;
    };
  '''
test '1-argument function annotation without return value', ->
  eqJS 'add1 = (i ~ number) -> i+1', '''
    var add1 = function(i: number) {
      return i + 1;
    };
  '''
test 'optional-argument function type annotation', ->
  eqJS 'add1 ~ (i? ~ number) -> number',
    'var add1: (i?: number) => number;'
test 'optional-argument function annotation', ->
  eqJS 'add1 = (i? ~ number) ~ number -> (i ? 0) + 1', '''
    var add1 = function(i?: number): number {
      return (i != null ? i : 0) + 1;
    };
  '''
test 'default-argument function annotation', ->
  eqJS 'add1 = (i ~ number = 0) ~ number -> (i ? 0) + 1', '''
    var add1 = function(i: number = 0): number {
      return (i != null ? i : 0) + 1;
    };
  '''
test 'union of function types', ->
  eqJS 'identity ~ ((i ~ number) -> number) | ((i ~ string) -> string)',
    'var identity: ((i: number) => number) | ((i: string) => string);'
test 'argumentless constructor type', ->
  eqJS 'c ~ new -> T',
    'var c: new () => T;'
test '1-argument constructor type', ->
  eqJS 'c ~ new (x ~ number) -> T',
    'var c: new (x: number) => T;'
test 'argumentless generic function', ->
  eqJS 'none = <T> -> null', '''
    var none = function<T>() {
      return null;
    };
  '''
test 'simple generic function', ->
  eqJS 'identity = <T>(x ~ T) ~ T -> x', '''
    var identity = function<T>(x: T): T {
      return x;
    };
  '''
test 'complex generic function', ->
  eqJS 'f = <T, S = T, Q = any>(x ~ T, y ~ S, z ~ Q) ~ T|S|Q -> x or y or z', '''
    var f = function<T, S = T, Q = any>(x: T, y: S, z: Q): T | S | Q {
      return x || y || z;
    };
  '''
test 'generic function with brace in arguments', ->
  eqJS 'f = <T>(options ~ {x: T}) ~ T -> options.x', '''
    var f = function<T>(options: {x: T}): T {
      return options.x;
    };
  '''
test 'JSX that looks like a generic function', ->
  eqJS 'dom = <Component>(hello) {-> signal()}</Component>', '''
    var dom = <Component>(hello) {function() {
      return signal();
    }}</Component>;
  '''

## Classes

test 'parameterized class', ->
  eqJS '''
    class C<T>
      constructor: (@x ~ T) ->
  ''', '''
    var C = class C<T> {
      constructor(x: T) {
        this.x = x;
      }

    };
  '''

## Object types

test '1-line object type annotation with assignment', ->
  eqJS '''o ~ {key: string, value?: any} = {key: 'foo'}''', '''
    var o: {key: string, value?: any};

    o = {
      key: 'foo'
    };
  '''
test 'indented object type annotation', ->
  eqJS '''
    o ~
      key: string
      value?: any
  ''', 'var o: {key: string, value?: any};'
test 'indented object type annotation with assignment', ->
  eqJS '''
    o ~
      key: string
      value?: any
    =
      key: 'hi'
      value: 9
  ''', '''
    var o: {key: string, value?: any};

    o = {
      key: 'hi',
      value: 9
    };
  '''

## Scoping

test 'inner annotation shadows outer', ->
  eqJS '''
    i ~ number
    f = ->
      i ~ number
      i
  ''', '''
    var i: number;

    var f = function() {
      var i: number;
      return i;
    };
  '''
forOut = '''
  var f = function() {
    var i: number;
    var results = [];
    for (var j = 1, i = j; j <= 10; i = ++j) {
      results.push(i ** 2);
    }
    return results;
  };
'''
test '1-line for loop annotation', ->
  eqJS '''
    f = ->
      i ** 2 for i ~ number in [1..10]
  ''', forOut
test 'multi-line for loop annotation', ->
  eqJS '''
    f = ->
      for i ~ number in [1..10]
        i ** 2
  ''', forOut

# Double declarations

test 'duplicating type fails', ->
  throws -> CoffeeScript.compile '''
    x ~ number
    x ~ number
  '''
test 'multiple types fail', ->
  throws -> CoffeeScript.compile '''
    x ~ number
    x ~ string
  '''
test 'typing parameter in body fails', ->
  throws -> CoffeeScript.compile 'f = (x) -> x ~ number'
