---
title: |
    Singleton с помощью dispatch_once
date: 2012-01-28
authors: [mrdekk]
tags: [objective-c, dispatch_once, singleton, реализация]
categories: [ObjectiveC]
permalink: /blog/obj_c/586.html
blogcat: ObjectiveC
excerpt_separator: <!--cut-->
---


![](http://itw66.ru/uploads/images/00/00/01/2012/01/28/bf8228.png)


Вы можете любить его, можете ненавидеть, но иногда он очень нужен вам в вашем приложении. Фактически, любое приложение для iOS и Mac OS X имеют как минимум один - **UIApplication** или **NSApplication**.

<!--cut-->

Итак, что же такое Singleton. [Википедия](http://ru.wikipedia.org/wiki/%D0%9E%D0%B4%D0%B8%D0%BD%D0%BE%D1%87%D0%BA%D0%B0_(%D1%88%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD_%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)) формулирует так:

>Гарантирует, что у класса есть только один экземпляр, и предоставляет к нему глобальную точку доступа.

Или короче

>Singleton - это класс, который имеет единственный экземпляр


Несмотря на определение паттерна, оно не всегда имеет место в мире библиотеки Foundation. Например, **NSFileManager** или **NSNotificationCenter** дают доступ к своим методом через методы класса **defaultManager** и **defaultCenter**. Однако, фактически они не являются Singleton'ами в полной мере. Такого же подхода будем придерживаться по ходу статьи. 

Существует много споров по поводу того, как правильно реализовывать паттерн на языке Objective-C, и даже разработчики Apple пару раз меняли свою точку зрения. Тогда, когда Apple представила технологию [Grand Central Dispatch (GCD)](http://developer.apple.com/library/mac/#documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html) (в Mac OS X 10.6 и iOS 4.0), была введена функция, которая прекрасно подходит для реализации паттерна Singleton:

Эта функция - **dispatch_once**:


```objc
void dispatch_once( dispatch_once_t* predicate, dispatch_block_t block );
```


Эта функция принимает предикат (который фактически имеет тип long, но действует как **BOOL**), затем функция dispatch_once использует его для того, чтобы проверить, что блок уже выполнялся. Кроме того, вторым параметром она принимает блок кода, который должен выполнится только один раз в течении работы приложения. Для нас - это нужный нам экземпляр.

Кроме того, что функция dispatch_once гарантирует нам то, что блок кода будет выполнен только один раз, она еще гарантирует нам потокобезопасность. Поэтому больше не надо колдовать над @synchronized.

Это подтверждается [документацией](http://developer.apple.com/library/mac/#documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html) Apple по GCD:


>If called simultaneously from multiple threads, this function waits  synchronously until the block has completed.


>Если функция вызывается одновременно из нескольких потоков, то функция ожидает синхронно, пока блок будет выполнен.

Итак, как же использовать подход на практике

Представим, что у вас есть класс AccountManager, и вы хотите сделать его Singleton'ом. Вы можете реализовать это следующим образом:

```objc
+( AccountManager* ) sharedManager
{
  static AccountManager* sharedAccountManagerInstance = nil;
  static dispatch_once_t predicate;
  dispatch_once( &predicate, ^{
    sharedAccountManagerInstance = [ [ self alloc ] init ];
  } );
  return sharedAccountManagerInstance;
}
```


И после этого, вы сможете получать доступ к экземпляру следующим способом:


```objc
AccountManager* accountManager = [ AccountManager sharedManager ];
```


И это все. У вас есть единственный экземпляр, к которому вы можете получать доступ из любой части приложения, и создан он будет всего один раз.

Этот подход имеет несколько плюсов:

- Потокобезопасность
- Статический анализатор будет счастлив
- Совместим с автоматическим подсчетом ссылок (ARC)
- Требуется всего чуть-чуть дополнительного кода


Единственный минус подхода состоит в том, что вы можете создать еще один экземпляр самостоятельно:


```objc
AccountManager* accountManager = [ [ AccountManager alloc ] init ];
```


Иногда, вам даже нужно такое поведение, хотя чаще всего вам нужен именно строго один экземпляр.

### Комментарии

>**FiloXSee, 28 февр. 2012, 13:12**
>
>Можешь прокомментировать отличия данного метода от метода, [описанного в статье](http://itw66.ru/blog/obj_c/586.html)?

>>**mrdekk, 28 февр. 2012, 15:08**
>>
>>не понял вопроса — ты ссылаешься на эту же статью

>>>**FiloXSee, 29 февр. 2012, 11:25**
>>>
>>>Ой, задумался. Долго решал в какой из статей спросить в комментарии о другой. [Вот ссылка](http://itw66.ru/blog/obj_c/540.html)

>>>>**mrdekk, 29 февр. 2012, 15:06**
>>>>
>>>>Разница в том, что ты используешь мьютекс и блокируешь поток — я нет. Кроме того, разница еще в том, что используется технология Grand Central Dispatch, которая появилась начиная с оси 4.0. Однако ее использование рекомендуется эпплом.
