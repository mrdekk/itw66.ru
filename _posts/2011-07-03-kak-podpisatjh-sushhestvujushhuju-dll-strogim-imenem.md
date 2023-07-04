---
title: |
    Как подписать существующую dll строгим именем
date: 2011-07-03
authors: [FiloXSee]
tags: [c#, managed c++, assembly]
categories: [C#]
permalink: /blog/c_sharp/502.html
blogcat: C#
excerpt_separator: <!--cut-->
---

Иногда приходится использовать сторонние библиотеки в своем приложении. Если вы хотите подписать свои библиотеки строгим именем при помощи *.snk / *.pfx ключей, то Visual Studio потребует чтобы все используемые библиотеки были подписаны. В случае если вы используете стороннюю библиотеку которая не подписана и к коду которой у вас нет доступа, то вам придется самим подписать ее. Это можно сделать следующим образом.

<!--cut-->


1. Запустите VS.NET command prompt:

![](http://itw66.ru/uploads/images/00/00/02/2011/07/03/1dc202.jpg)


2. Создайте файл ключа, которым вы будете подписывать сборку:

```
sn -k keyPair.snk
```


3. Получите MSIL из оригинальной сборки:

```
ildasm SomeAssembly.dll /out:SomeAssembly.il
```


3. переименуйте оригинальную сборку, чтобы осталась:

```
ren SomeAssembly.dll SomeAssembly.dll.orig
```


4. Создайте новую сборку используя полученный MSIL и подпишите ее вашим ключом:

```
ilasm SomeAssembly.il /dll /key=keyPair.snk
```


Вот и все, теперь можете использовать подписанную сборку в вашем приложение. Если вам нужны сами утилиты, которыми вы выполняли данные действия, то обычно их можно найти тут:

```
C:\WINDOWS\Microsoft.NET\Framework\v2.0.50727\ilasm.exe
C:\Program Files\Microsoft Visual Studio 8\SDK\v2.0\Bin\ildasm.exe
C:\Program Files\Microsoft Visual Studio 8\SDK\v2.0\Bin\sn.exe
```


**Другие статьи по теме:**
[Как подписать C# сборку строгим именем. Использование sn.exe](http://itw66.ru/blog/c_sharp/504.html)
[Как подписать C++/CLI сборку строгим именем](http://itw66.ru/blog/c_sharp/500.html)
