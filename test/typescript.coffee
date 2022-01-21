## Basic type annotation and assignment

for type in [
  'null', 'undefined', 'number',
  'number[]', 'number | string', 'number & string',
  'T'
]
  do (type) ->
    test "#{type} type annotation", ->
      eqJS "x ~ #{type}", """
        var x: #{type};

        x;
      """
    test "#{type} type annotation with assignment", ->
      eqJS "x ~ #{type} = 7", """
        var x: #{type};

        x = 7;
      """

## Function types

test 'argumentless function type annotation', ->
  eqJS 'zero ~ -> number', '''
    var zero: () => number;

    zero;
  '''
test 'argumentless function type annotation with assignment', ->
  eqJS 'zero ~ -> number = -> 0', '''
    var zero: () => number;

    zero = function() {
      return 0;
    };
  '''
test 'argumentless function annotation', ->
  eqJS 'zero = () ~ number -> 0', '''
    var zero;

    zero = function(): number {
      return 0;
    };
  '''
test '1-argument function type annotation', ->
  eqJS 'add1 ~ (i ~ number) -> number', '''
    var add1: (i: number) => number;

    add1;
  '''
test '1-argument function annotation', ->
  eqJS 'add1 = (i ~ number) ~ number -> i+1', '''
    var add1;

    add1 = function(i: number): number {
      return i + 1;
    };
  '''
test '1-argument function annotation without return value', ->
  eqJS 'add1 = (i ~ number) -> i+1', '''
    var add1;

    add1 = function(i: number) {
      return i + 1;
    };
  '''
test 'optional-argument function type annotation', ->
  eqJS 'add1 ~ (i? ~ number) -> number', '''
    var add1: (i?: number) => number;

    add1;
  '''
test 'optional-argument function annotation', ->
  eqJS 'add1 = (i? ~ number) ~ number = (i ? 0) + 1', '''
    var add1;

    add1 = function(i?: number): number {
      return (i != null ? i : 0) + 1;
    };
  '''
test 'default-argument function annotation', ->
  eqJS 'add1 = (i ~ number = 0) ~ number -> (i ? 0) + 1', '''
    var add1;

    add1 = function(i: number = 0): number {
      return (i != null ? i : 0) + 1;
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
  ''', '''
    var o: {key: string, value?: any};

    o;
  '''
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
    var f, i: number;

    i;

    f = function() {
      var i: number;
      i;
      return i;
    };
  '''
forOut = '''
  var f;

  f = function() {
    var i: number, j, results;
    results = [];
    for (i = j = 1; j <= 10; i = ++j) {
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
