---
title: |
    Как подписать C++/CLI сборку строгим именем
date: 2011-07-03
authors: [FiloXSee]
tags: [c++, managed c++, c++/cli, assembly]
categories: [C++/CLI]
permalink: /blog/cpp_cli/500.html
blogcat: C++/CLI
excerpt_separator: <!--cut-->
---

Если у вас в составе проекта есть сборка Managed C++ и вы захотите подписать остальные сборки строгим именем, то вам придется подписать и данную сборку. Visual Studio потребует, чтобы все сборки были подписаны.

Чтобы это сделать вам придется указать ключ, которым вы собираетесь ее подписать в свойствах проекта: Project-> Properties-> Configuration Properties-> Linker-> Advanced-> Key File. 

<!--cut-->


![](http://itw66.ru/uploads/images/00/00/02/2011/07/03/503303.jpg)


При этом удобно использовать макрос $(ProjectDir), который укажет путь до проекта.

Не пытайтесь использовать .pfx файл. Это не сработает, можно использовать только .snk файл (Strong Name Key). Вы можете его создать при помощи sn.exe утилиты.

```
sn.exe –k [directory]\[filename].snk
```


Она поставляется вместе с .Net SDK и обычно находится по пути _c:\program files\microsoft .net\sdk\bin_, но правильнее использовать _Command Prompt_. Откроется консоль в которой вы можете вводить необходимую команду.


![](http://itw66.ru/uploads/images/00/00/02/2011/07/03/1dc202.jpg)


**Другие статьи по теме:**
[Как подписать C# сборку строгим именем. Использование sn.exe](http://itw66.ru/blog/c_sharp/504.html)
[Как подписать существующую dll строгим именем](http://itw66.ru/blog/c_sharp/502.html)
