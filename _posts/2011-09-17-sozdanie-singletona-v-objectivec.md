---
title: |
    Создание синглетона в ObjectiveC
date: 2011-09-17
authors: [FiloXSee]
tags: [objectivec, singleton]
categories: [ObjectiveC]
permalink: /blog/obj_c/540.html
blogcat: ObjectiveC
excerpt_separator: <!--cut-->
---

Часто при разработки некой функциональности, удобно ее оформить в виде синглетона. Это класс, который может иметь только один созданный объект. Реализовать синглетон в ObjectiveC можно следующим образом:

Объявление класса:

```objc
@interface FileSystem : NSObject
{    // переменные класса
}

+ (FileSystem*) getInst;    // метод, которые предоставляет доступ к объекту класса
- (void)        someMethod; // некий метод
@end
```


<!--cut-->


Определение класса:

```csharp
#import "FileSystem.h"

@implementation FileSystem

static FileSystem* g_sharedFileSystem = nil;
+ (AwardCenter *)getInst
{
    @synchronized( [
    {
        if( !g_sharedFileSystem )
            g_sharedFileSystem = [ [ self alloc ] init ];
        return g_sharedFileSystem;
    }
    return nil;  // чтобы не было ошибок компиляции
}

- (id)init
{
    if ( (self = [super init]) )
    {
        // ваша инициализация
    }
    return self;
}

- (void) someMethod
{
    // ...
}   


// Дополнительные методы, которые нужно реализовать, если вы делаете библиотеку.
// Обычно это излишне
- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  // показывает, что объект не может быть удален
}

- (void)release
{
    // нечего не делаем
}

- (id)autorelease
{
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

@end
```



Теперь можно вызвать метод этого объекта следующим образом:

```objc
[ [ FileSystem getInst ] someMethod ];
```

