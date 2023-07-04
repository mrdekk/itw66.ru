---
title: |
    Разбиение строки на токены в ObjectiveC
date: 2011-09-17
authors: [FiloXSee]
tags: [objectivec, strings, tokens]
categories: [ObjectiveC]
permalink: /blog/obj_c/539.html
blogcat: ObjectiveC
excerpt_separator: <!--cut-->
---

При работе со строками в ObjectiveC часто требуется разбить строку на токены, по какому-либо символу. Рассмотрим наиболее часто необходимые примеры использования.

Разбиение строки на слова:

```
NSString* sourceString = @"Some string";
NSArray* words = [ sourceString componentsSeparatedByString: @" " ];
// теперь words содержит: [ @"Some", @"string" ]
```



Разбиение строки по нескольким символам:

```
NSString* sourceString = @"Game-info/title";
NSArray* words = [ sourceString componentsSeparatedByCharactersInSet:
                      [ NSCharacterSet characterSetWithCharactersInString: @"-/" ]
                    ];
// теперь words содержит: [ @"Game", @"info", @"title" ]
```



Если вам нужно разбить строку на символы, то это можно сделать пробежав в цикле по символам строки и создав по строке на каждый символ:

```
int length = [sourceString length];
NSMutableArray* chars = [[NSMutableArray alloc] initWithCapacity: length ];
for( int i = 0; i < length; ++i )
{
    NSString* ch  = [ NSString stringWithFormat: @"%c", [ sourceString characterAtIndex: i ] ];
    [ chars addObject: ch ];
}
// теперь массив chars содержит строки с символами из начальной строки
```

