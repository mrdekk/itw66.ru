---
title: |
    Получение стека функций с использованием StackTrace
date: 2011-05-18
authors: [FiloXSee]
tags: [c#, отладка, стек]
categories: [C#]
permalink: /blog/c_sharp/474.html
blogcat: C#
excerpt_separator: <!--cut-->
---

Для целей отладки часто нужно узнать коллстек вызова функций, например чтобы понять место возникновения исключения. В .Net можно получить информацию о стеке вызова функций при помощи класса StackTrace.

<!--cut-->


Для удобства создадим класс, который будет хранить информацию об одном уровне в иерархии стека функций.

```
public class StackItem
{
    public String    Module;        // модуль, в котором находится данная функция
    public String    ClassName;    // имя класса, в котором находится данная функция
    public String    MethodName;    // имя данной функции, из которой будет вызвана следующая функция
    public String    Params;        // сюда положим текстовый список параметров данной функции
    
    public String    FileName;    // файл, в котором находится данная функция
    public Int32    Line;        // строка, в которой вызвана следующая функция


    public override string ToString()
    {
        return String.Format( "{0}.{1}({2}) {3}", ClassName, MethodName, Params,
            ( FileName != null ? FileName + " (" + Line.ToString() + ")" : "") );
    }
}
```


Теперь создадим класс Dbg, который будет выполнять всю необходимую работу по получению стека функций.


```
public class Dbg
{
    // получить коллстек функций для текущего потока в виде строки
    public static String        GetStackString()
    {
        StringBuilder hStrBld = new StringBuilder();
        StackItem[] stack = GetStack();
        foreach( StackItem item in stack)
            hStrBld.Append( item.ToString() + Environment.NewLine );
        return hStrBld.ToString();
    }

    // получить коллстек функций для текущего потока
    public static StackItem[]    GetStack()
    {
        return GetStack( Thread.CurrentThread );
    }

    // получить коллстек функций для указанного потока
    public static StackItem[]    GetStack( Thread targetThread )
    {
        List< StackItem > stackList = new List< StackItem >();
        StackTrace st = new StackTrace( targetThread, true );
        for( Int32 i = 0; i < st.FrameCount; ++i )
        {
            StackItem item = GetStackItem( st.GetFrame( i ) );
            if( item != null )
                stackList.Add( item );
        }
        return stackList.ToArray();
    }

    // сформировать данные о фрейме стека
    private static StackItem    GetStackItem( StackFrame sf )
    {
        if( sf == null )
            return null;
        MethodBase method = sf.GetMethod();
        if( method == null || method.ReflectedType == null )
            return null;
        
        // получить информацию о данном фрейме стека
        StackItem item    = new StackItem();
        item.Module    = method.Module.Assembly.FullName;
        item.ClassName    = method.ReflectedType.Name;
        item.MethodName    = method.Name;
        item.FileName    = sf.GetFileName();
        item.Line    = sf.GetFileLineNumber();

        // получить параметры данного метода
        StringBuilder params = new StringBuilder();
        ParameterInfo[] paramsInfo = hMethod.GetParameters();
        for( Int32 i = 0; i < paramsInfo.Length; i++ )
        {
            ParameterInfo currParam = paramsInfo[ i ];
            szParams.Append( currParam.ParameterType.Name );
            szParams.Append( " " );
            szParams.Append( currParam.Name );
            if( i != paramsInfo.Length - 1 )
                params.Append( ", " );
        }

        item.Params = params.ToString();

        return item;
    }
}
```


Пользоваться данным классом очень легко. Если вам нужна строка, в которой будет записан колстек функций для текущего потока, то вам нужно вызвать функцию **GetStackString**. Полученную строку можно записывать в лог или вывести пользователю в отладочном сообщении.


```
String callstackStr = Dbg.GetStackString(); // получить коллстек функций для текущего потока
StackItem[] items = Dbg.GetStack(); // получение массива данных о стеке текущего потока
StackItem[] items = Dbg.GetStack( thread ); // получение массива данных о стеке указанного потока
```


Вот пример текста, который может быть получен функцией GetStackString, при перехвате исключения. По этому тексту можно в точности определить место в коде, где произошла ошибка.


```
Route.AssignVehicle( rc_Vehicle hVehicle ) Route.cs (1323)
Vehicle.Update(  ) Vehicle.cs (772)
wnd_RoutePlanManager.processUpdateable( i_Updateable updateable ) RoutePlanManagerWindow.cs (89)
wnd_RoutePlanManager.objectLoaded( ModelBase obj ) RoutePlanManagerWindow.cs (123)
wnd_RoutePlanManager.objectsLoaded( List`1 objects ) RoutePlanManagerWindow.cs (184)
wnd_RoutePlanManager.onObjectsLoaded( List`1 objects ) RoutePlanManagerWindow.cs (371)
DgObjectsLoaded.Invoke( List`1 objects ) 
ModelController.DoObjectsLoaded( List`1 objects ) ModelController.cs (157)
Vehicle.<loadByEnterprises>b__b( DataTable res ) Vehicle.cs (1871)
<>c__DisplayClassd.<beginQuery>b__9( DataTable res ) MultiDbi.cs (173)
<>c__DisplayClass4.<beginQuery>b__3(  ) asdbi.cs (863)
ThreadManager.ExecTask( TaskQueue queue, Int32 taskId ) ThreadManager.cs (603)
ThreadManager.ThreadWorker( Object parameter ) ThreadManager.cs (583)
ThreadHelper.ThreadStart_Context( Object state ) 
ExecutionContext.Run( ExecutionContext executionContext, ContextCallback callback, Object state ) 
ThreadHelper.ThreadStart( Object obj ) 
```

