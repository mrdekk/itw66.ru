---
title: |
    Выполнение блока кода в определенном потоке
date: 2012-02-05
authors: [mrdekk]
tags: [objective-c, nsthread, blocks, потоки]
categories: [ObjectiveC]
permalink: /blog/obj_c/590.html
blogcat: ObjectiveC
excerpt_separator: <!--cut-->
---

Когды Вы начинаете работать с блоками, то сразу возникает вопрос: "Есть блок кода, могу ли я просто выполнить его на определенном потоке?". Слава богу - ответ "Да", но Apple почему-то не дала простого способа сделать этого, что на Mac OS X, что на iOS. Однако ситуацию можно легко исправить. Как? Прошу под кат...


<!--cut-->



```

@implementation NSThread ( BlockOnThread )
 
+( void ) BOT_performBlockOnMainThread: ( void ( ^ )( ) )block
{
  [ [ NSThread mainThread ] BOT_performBlock: block ];
}
 
+( void ) BOT_performBlockInBackground: ( void ( ^ )( ) )block
{
  [ NSThread performSelectorInBackground: @selector( BOT_runBlock: )
                              withObject: [ [ block copy ] autorelease ] ];
}
 
+( void ) BOT_runBlock: ( void ( ^ )( ) )block
{
  block( );
}
 
-( void ) BOT_performBlock: ( void ( ^ )( ) )block
{
  if ( [ [ NSThread currentThread ] isEqual: self ] )
    block( );
  else
    [ self BOT_performBlock: block waitUntilDone: NO ];
}

-( void ) BOT_performBlock: ( void ( ^ )( ) )block waitUntilDone: ( BOOL )wait
{
  [ NSThread performSelector: @selector( BOT_runBlock: )
                    onThread: self
                  withObject: [ [ block copy ] autorelease ]
               waitUntilDone: wait ];
}
 
-( void ) BOT_performBlock: ( void ( ^ )( ) )block afterDelay: ( NSTimeInterval )delay
{
  [ self performSelector: @selector( BOT_performBlock: ) 
              withObject: [ [ block copy ] autorelease ] 
              afterDelay: delay ];
}
 
@end
```


Эта категория просто добавляет несколько методов к интерфейсу класса NSThread, которые позволят вам выполнить любой блок кода на любом потоке, к которому вы имеете доступ. Увы, к названиям методов пришлось добавить префиксы, так как Objective-C не поддерживает пространства имен (а-ля, namespace в C++). 

Для более глубокого понимания того, как работают блоки кода, можете обратится к документации Apple ["Apple Blocks Programming Topics"](http://developer.apple.com/library/ios/#documentation/cocoa/Conceptual/Blocks/Articles/00_Introduction.html).

Кроме блоков, в Mac OS 10.6 Apple ввела также технологию [Grand Central Dispatch](http://developer.apple.com/technologies/mac/snowleopard/gcd.html) (GCD). Предполагается, что в том случае, если необходимо выполнить ресурсоемкие вычисления на главном потоке, то необходимо использовать технологию GCD. Однако, существуют ситуации (например, при использовании устаревших API и библиотек), когда до сих пор требуется выполнение кода на выделенном потоке.

Возьмем следующий пример. Пусть у вас есть сетевой поток (networkThread) на котором открыт сокет для поддержания постоянного соединения с сервером, кроме того есть парсер для данных, поступающих по этому сокету. Тут налицо частая ошибка, когда сетевые программисты выносят операции ввода-вывода в другой поток, однако парсят данные на главном, тем самым интерфейс "заикается" в момент приема данных. 

Вообще, данные, которые вы хотите послать через сеть, появляются когда что-то происходит в интерфейсе приложения (например, кто-то нажал кнопку), следовательно в главном потоке. Затем необходимо эти данные передать в сетевой поток, чтобы они могли быть отправлены по назначению.

Например, необходимо послать имя (firstName) и фамилию (lastName) человека и название компании (companyName) через сетевое соединение.

В идеале, неплохо бы иметь метод, вида:


```
-( void ) sendFirstName: ( NSString* )firstName
               lastName: ( NSString* )lastName
            companyName: ( NSString* )companyName;
```


Этот метод производил бы преобразование данных в формат, в котором они будут отсылаться через сеть (например, XML, JSON, ...) и ставил бы в очередь сокета для отправки.

Проблема состоит в том, что если два потока попытаются использовать один и тот же сокет в один и тот же момент времени - приложение упадет. Поэтому этот метод может быть вызван только из сетевого потока (networkThread). Это, кстати, важно и для других API, которые не обеспечивают потокобезопасность.

Поэтому создадим еще один метод вида:


```
-( void ) onNetworkThreadSendFirstName: ( NSString* )firstName
                              lastName: ( NSString* )lastName
                           companyName: ( NSString* )companyName;
```


и сохраним исходный для использования на главном потоке. Итак, как же вызвать метод на другом потоке? Это нельзя сделать напрямую, вместо этого нам надлежит использовать:


```
-( void ) performSelector: ( SEL )selector
                 onThread: ( NSThread* )thread
               withObject: ( id )object
            waitUntilDone: ( BOOL )wait;
```


Единственная проблема в том, что мы в данном методе может передать только один параметр (withObject), хотя в примере нам необходимо передать три.

Все что нам необходимо сделать, это поместить все три аргумента в один объект. Это можно попытаться сделать с помощью массива, с помощью специального объекта (из пушки по воробьям, так как этот объект будет использоваться только для передачи аргументов в метод) или с помощью словаря, чем мы и воспользуемся.


```
-( void ) onNetworkThreadSendArguments: ( NSDictionary* )arguments;
```


Если следовать всему вышесказанному, то код будет выглядеть примерно следующим образом:


```
-( void ) sendFirstName: ( NSString* )firstName 
               lastName: ( NSString* )lastName 
            companyName: ( NSString* )companyName
{
  NSDictionary* arguments = [ NSDictionary dictionaryWithObjectsAndKeys:
    firstName, @"firstName",
    lastName, @"lastName",
    companyName, @"companyName",
    nil ];
 
  [ self performSelector: @selector( onNetworkThreadSendArguments: ) 
                onThread: networkThread 
              withObject: arguments 
           waitUntilDone: NO ];
}
 
-( void ) onNetworkThreadSendArguments: ( NSDictionary* )arguments
{
  NSString* firstName = [ arguments objectForKey: @"firstName" ];
  NSString* lastName = [ arguments objectForKey: @"lastName" ];
  NSString* companyName = [ arguments objectForKey: @"companyName" ];
 
  [ self onNetworkThreadSendFirstName: firstName
                             lastName: lastName
                          companyName: companyName ];
}
 
-( void ) onNetworkThreadSendFirstName: ( NSString* )firstName 
                              lastName: ( NSString* )lastName 
                           companyName: ( NSString* )companyName
{
  //format and send data
}
```


До Mac OS X 10.6 это было обычной практикой, но она требует много дополнительных методов, упаковку и распаковку аргументов для кросс-поточных вызовов. Но благодаря нашей категории, мы может решить задачу гораздо проще:


```
-( void ) sendFirstName: ( NSString* )firstName
               lastName: ( NSString* )lastName
            companyName: ( NSString* )companyName
{
  [ networkThread BOT_performBlock: ^{
    // format and send data
  } ];
}
```


Так как блок кода всегда будет выполнен только на сетевом потоке, метод можно вызывать из любого потока. Видно, что блоки представляют собой крайне удобное средство, даже без использования Grand Central Dispatch.
